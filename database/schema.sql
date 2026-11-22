-- ============================================================================
--  «Аура» — схема базы данных для PostgreSQL 16+
--
--  Демо-бэкенд (backend/Zapis.Api) для запуска без Docker хранит данные в JSON,
--  но целевая схема — эта. Она же используется в docker-compose.yml.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;    -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS btree_gist;  -- exclusion-constraint по master_id + интервалу

-- ---------------------------------------------------------------- users -----

CREATE TABLE users (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email         text        NOT NULL,
    password_hash text        NOT NULL,
    full_name     text        NOT NULL,
    phone         text        NOT NULL DEFAULT '',
    created_at    timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT users_email_format CHECK (position('@' IN email) > 1),
    CONSTRAINT users_full_name_not_empty CHECK (length(trim(full_name)) > 1)
);

-- Email сравниваем без учёта регистра, поэтому уникальный индекс по lower(email),
-- а не обычный UNIQUE на колонке.
CREATE UNIQUE INDEX users_email_unique_idx ON users (lower(email));

-- ----------------------------------------------------------- categories -----

CREATE TABLE categories (
    id    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    title text NOT NULL,
    slug  text NOT NULL UNIQUE,
    icon  text NOT NULL DEFAULT ''
);

-- -------------------------------------------------------------- masters -----

CREATE TABLE masters (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name      text NOT NULL,
    specialization text NOT NULL DEFAULT '',
    rating         numeric(2, 1) NOT NULL DEFAULT 0
        CHECK (rating >= 0 AND rating <= 5)
);

-- ------------------------------------------------------------- services -----

CREATE TABLE services (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id      uuid NOT NULL REFERENCES categories (id) ON DELETE RESTRICT,
    title            text NOT NULL,
    description      text NOT NULL DEFAULT '',
    price            numeric(10, 2) NOT NULL CHECK (price >= 0),
    duration_minutes integer NOT NULL CHECK (duration_minutes BETWEEN 15 AND 480),
    is_active        boolean NOT NULL DEFAULT true
);

CREATE INDEX services_category_idx ON services (category_id) WHERE is_active;

-- ------------------------------------------------------- master_services -----

-- Many-to-many: какие мастера оказывают какие услуги.
CREATE TABLE master_services (
    master_id  uuid NOT NULL REFERENCES masters (id) ON DELETE CASCADE,
    service_id uuid NOT NULL REFERENCES services (id) ON DELETE CASCADE,

    PRIMARY KEY (master_id, service_id)
);

CREATE INDEX master_services_service_idx ON master_services (service_id);

-- ------------------------------------------------------------- bookings -----

CREATE TABLE bookings (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    service_id       uuid NOT NULL REFERENCES services (id) ON DELETE RESTRICT,
    master_id        uuid NOT NULL REFERENCES masters (id) ON DELETE RESTRICT,
    start_at         timestamptz NOT NULL,
    end_at           timestamptz NOT NULL,
    price_at_booking numeric(10, 2) NOT NULL CHECK (price_at_booking >= 0),
    status           text NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'cancelled')),
    comment          text,
    created_at       timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT bookings_period_valid CHECK (end_at > start_at)
);

-- Главная защита от двойной записи: два активных интервала одного мастера
-- не могут пересекаться. Даже если два запроса придут одновременно,
-- второй упадёт на уровне БД, а не создаст дубль.
ALTER TABLE bookings
    ADD CONSTRAINT bookings_no_overlap
    EXCLUDE USING gist (
        master_id WITH =,
        tstzrange(start_at, end_at, '[)') WITH &&
    )
    WHERE (status = 'active');

-- Быстрая проверка занятости мастера на дату.
CREATE INDEX bookings_master_start_idx
    ON bookings (master_id, start_at)
    WHERE status = 'active';

-- «Мои записи» — свежие сверху.
CREATE INDEX bookings_user_start_idx
    ON bookings (user_id, start_at DESC);

-- ------------------------------------------------------------- comments -----

COMMENT ON TABLE bookings IS 'Записи клиентов на услуги к мастерам';
COMMENT ON COLUMN bookings.price_at_booking IS 'Цена на момент записи: изменение прайса не переписывает историю';
COMMENT ON COLUMN bookings.start_at IS 'UTC; клиент отображает в локальном часовом поясе';
