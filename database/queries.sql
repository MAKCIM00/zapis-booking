-- ============================================================================
--  Примеры запросов к схеме «Аура» (PostgreSQL 16+).
--  Это те базовые операции, которые нужны BFF: выборки, JOIN, INSERT, UPDATE.
-- ============================================================================

-- 1. Каталог: услуги + категория + количество мастеров.
--    LEFT JOIN, чтобы показать и услуги без мастеров (их видно в отчёте).
SELECT s.id,
       s.title,
       s.price,
       s.duration_minutes,
       c.title                AS category,
       count(ms.master_id)    AS masters_count
FROM services s
         JOIN categories c ON c.id = s.category_id
         LEFT JOIN master_services ms ON ms.service_id = s.id
WHERE s.is_active
GROUP BY s.id, c.title
ORDER BY c.title, s.title;

-- 2. Поиск по каталогу с фильтром по категории и пагинацией.
SELECT s.id, s.title, s.price, s.duration_minutes
FROM services s
WHERE s.is_active
  AND ($1::uuid IS NULL OR s.category_id = $1)
  AND ($2::text IS NULL OR s.title ILIKE '%' || $2 || '%')
ORDER BY s.title
LIMIT $3 OFFSET $4;

-- 3. Карточка услуги: мастера, которые её оказывают.
SELECT m.id, m.full_name, m.specialization, m.rating
FROM master_services ms
         JOIN masters m ON m.id = ms.master_id
WHERE ms.service_id = $1
ORDER BY m.rating DESC;

-- 4. Свободные окна мастера на дату.
--    Строим сетку 30 минут в рабочем дне салона (10:00–20:00, часовой пояс Asia/Tomsk)
--    и убираем интервалы, которые пересекаются с активными записями.
WITH params AS (
    SELECT $1::uuid      AS master_id,
           $2::int       AS duration_minutes,
           $3::date      AS day,
           'Asia/Tomsk'  AS tz
),
     grid AS (
         -- 19 слотов: 10:00, 10:30, ... 19:00
         SELECT ((p.day + time '10:00') AT TIME ZONE p.tz) + (n * interval '30 minutes') AS slot_start,
                p.duration_minutes
         FROM params p
                  CROSS JOIN generate_series(0, 18) AS n
     )
SELECT g.slot_start
FROM grid g
WHERE g.slot_start > now()
  AND g.slot_start + make_interval(mins => g.duration_minutes)
      <= ((SELECT day FROM params) + time '20:00') AT TIME ZONE (SELECT tz FROM params)
  AND NOT EXISTS (
    SELECT 1
    FROM bookings b
    WHERE b.master_id = (SELECT master_id FROM params)
      AND b.status = 'active'
      AND tstzrange(b.start_at, b.end_at, '[)')
          && tstzrange(g.slot_start, g.slot_start + make_interval(mins => g.duration_minutes), '[)')
)
ORDER BY g.slot_start;

-- 5. Создание записи: цену и длительность берём из услуги, а не с клиента.
INSERT INTO bookings (user_id, service_id, master_id, start_at, end_at, price_at_booking)
SELECT $1,
       s.id,
       $2,
       $3,
       $3 + make_interval(mins => s.duration_minutes),
       s.price
FROM services s
WHERE s.id = $4
RETURNING id, start_at, end_at, price_at_booking, status;

-- 6. «Мои записи»: JOIN услуги и мастера, свежие сверху.
SELECT b.id,
       s.title      AS service_title,
       m.full_name  AS master_name,
       b.start_at,
       b.end_at,
       b.price_at_booking,
       b.status
FROM bookings b
         JOIN services s ON s.id = b.service_id
         JOIN masters m ON m.id = b.master_id
WHERE b.user_id = $1
ORDER BY b.start_at DESC
LIMIT 50;

-- 7. Отмена записи: только своя, только будущая и только активная.
UPDATE bookings
SET status = 'cancelled'
WHERE id = $1
  AND user_id = $2
  AND status = 'active'
  AND start_at > now()
RETURNING id, status;

-- 8. Обновление профиля.
UPDATE users
SET full_name = $2,
    phone     = $3
WHERE id = $1
RETURNING id, email, full_name, phone;

-- 9. Загрузка мастера за период: сколько записей и на какую сумму.
SELECT m.full_name,
       count(*)                     AS bookings_count,
       sum(b.price_at_booking)      AS revenue
FROM bookings b
         JOIN masters m ON m.id = b.master_id
WHERE b.status = 'active'
  AND b.start_at >= $1
  AND b.start_at < $2
GROUP BY m.id, m.full_name
ORDER BY revenue DESC;

-- 10. Проверка, что пересечений нет (должно вернуть 0 строк).
SELECT b1.id, b2.id
FROM bookings b1
         JOIN bookings b2
              ON b1.master_id = b2.master_id
                  AND b1.id < b2.id
                  AND b1.status = 'active'
                  AND b2.status = 'active'
                  AND tstzrange(b1.start_at, b1.end_at, '[)')
                      && tstzrange(b2.start_at, b2.end_at, '[)');
