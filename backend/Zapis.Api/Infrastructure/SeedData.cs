using Zapis.Api.Domain;

namespace Zapis.Api.Infrastructure;

/// <summary>Демо-данные: салон красоты «Аура», 4 категории, 4 мастера, 10 услуг и тестовый пользователь.</summary>
public static class SeedData
{
    private static readonly Guid DemoUserId = Guid.Parse("d1111111-1111-1111-1111-111111111111");

    private static readonly Guid Hair = Guid.Parse("a1111111-1111-1111-1111-111111111111");
    private static readonly Guid Nails = Guid.Parse("a2222222-2222-2222-2222-222222222222");
    private static readonly Guid Brows = Guid.Parse("a3333333-3333-3333-3333-333333333333");
    private static readonly Guid Massage = Guid.Parse("a4444444-4444-4444-4444-444444444444");

    private static readonly Guid Anna = Guid.Parse("b1111111-1111-1111-1111-111111111111");
    private static readonly Guid Marina = Guid.Parse("b2222222-2222-2222-2222-222222222222");
    private static readonly Guid Daria = Guid.Parse("b3333333-3333-3333-3333-333333333333");
    private static readonly Guid Igor = Guid.Parse("b4444444-4444-4444-4444-444444444444");

    public static DatabaseState Create(PasswordHasher hasher) => new()
    {
        Users =
        [
            new User
            {
                Id = DemoUserId,
                Email = "demo@zapis.ru",
                PasswordHash = hasher.Hash("demo1234"),
                FullName = "Демо Клиент",
                Phone = "+7 900 000-00-00",
                CreatedAt = DateTime.UtcNow
            }
        ],

        Categories =
        [
            new Category { Id = Hair, Title = "Волосы", Slug = "hair", Icon = "hair" },
            new Category { Id = Nails, Title = "Ногти", Slug = "nails", Icon = "nails" },
            new Category { Id = Brows, Title = "Брови и ресницы", Slug = "brows", Icon = "brows" },
            new Category { Id = Massage, Title = "Массаж", Slug = "massage", Icon = "massage" }
        ],

        Masters =
        [
            new Master { Id = Anna, FullName = "Анна Соколова", Specialization = "Стилист-колорист", Rating = 4.9 },
            new Master { Id = Marina, FullName = "Марина Ким", Specialization = "Мастер маникюра", Rating = 4.8 },
            new Master { Id = Daria, FullName = "Дарья Лебедева", Specialization = "Бровист", Rating = 4.7 },
            new Master { Id = Igor, FullName = "Игорь Волков", Specialization = "Массажист", Rating = 4.9 }
        ],

        Services =
        [
            new Service
            {
                Id = Guid.Parse("c1111111-1111-1111-1111-111111111111"), CategoryId = Hair,
                Title = "Женская стрижка", DurationMinutes = 60, Price = 3500,
                Description = "Стрижка с учётом формы лица, мытьё головы и укладка включены."
            },
            new Service
            {
                Id = Guid.Parse("c1111111-1111-1111-1111-111111111112"), CategoryId = Hair,
                Title = "Укладка", DurationMinutes = 45, Price = 2500,
                Description = "Повседневная или вечерняя укладка на стайлерах и брашингом."
            },
            new Service
            {
                Id = Guid.Parse("c1111111-1111-1111-1111-111111111113"), CategoryId = Hair,
                Title = "Окрашивание в один тон", DurationMinutes = 120, Price = 6500,
                Description = "Однотонное окрашивание стойкой краской, уход после окрашивания."
            },
            new Service
            {
                Id = Guid.Parse("c2222222-2222-2222-2222-222222222221"), CategoryId = Nails,
                Title = "Маникюр с покрытием", DurationMinutes = 90, Price = 2800,
                Description = "Аппаратный маникюр, укрепление и гель-лак любого оттенка."
            },
            new Service
            {
                Id = Guid.Parse("c2222222-2222-2222-2222-222222222222"), CategoryId = Nails,
                Title = "Педикюр", DurationMinutes = 90, Price = 3200,
                Description = "Обработка стоп, снятие огрубевшей кожи, покрытие гель-лаком."
            },
            new Service
            {
                Id = Guid.Parse("c3333333-3333-3333-3333-333333333331"), CategoryId = Brows,
                Title = "Коррекция и окрашивание бровей", DurationMinutes = 45, Price = 1800,
                Description = "Архитектура бровей, окрашивание краской или хной."
            },
            new Service
            {
                Id = Guid.Parse("c3333333-3333-3333-3333-333333333332"), CategoryId = Brows,
                Title = "Ламинирование ресниц", DurationMinutes = 75, Price = 3500,
                Description = "Изгиб, питание и ботокс ресниц, эффект держится до 6 недель."
            },
            new Service
            {
                Id = Guid.Parse("c4444444-4444-4444-4444-444444444441"), CategoryId = Massage,
                Title = "Массаж спины", DurationMinutes = 60, Price = 3000,
                Description = "Расслабляющий массаж спины и шеи, 60 минут."
            },
            new Service
            {
                Id = Guid.Parse("c4444444-4444-4444-4444-444444444442"), CategoryId = Massage,
                Title = "Общий массаж тела", DurationMinutes = 90, Price = 4500,
                Description = "Классический общий массаж с индивидуальным подбором масла."
            },
            new Service
            {
                Id = Guid.Parse("c4444444-4444-4444-4444-444444444443"), CategoryId = Massage,
                Title = "Спа-ритуал для лица", DurationMinutes = 60, Price = 4000,
                Description = "Очищение, пилинг, массаж лица и питательная маска."
            }
        ],

        MasterServices =
        [
            new MasterService { MasterId = Anna, ServiceId = Guid.Parse("c1111111-1111-1111-1111-111111111111") },
            new MasterService { MasterId = Anna, ServiceId = Guid.Parse("c1111111-1111-1111-1111-111111111112") },
            new MasterService { MasterId = Anna, ServiceId = Guid.Parse("c1111111-1111-1111-1111-111111111113") },

            new MasterService { MasterId = Marina, ServiceId = Guid.Parse("c2222222-2222-2222-2222-222222222221") },
            new MasterService { MasterId = Marina, ServiceId = Guid.Parse("c2222222-2222-2222-2222-222222222222") },

            new MasterService { MasterId = Daria, ServiceId = Guid.Parse("c3333333-3333-3333-3333-333333333331") },
            new MasterService { MasterId = Daria, ServiceId = Guid.Parse("c3333333-3333-3333-3333-333333333332") },

            new MasterService { MasterId = Igor, ServiceId = Guid.Parse("c4444444-4444-4444-4444-444444444441") },
            new MasterService { MasterId = Igor, ServiceId = Guid.Parse("c4444444-4444-4444-4444-444444444442") },
            new MasterService { MasterId = Igor, ServiceId = Guid.Parse("c4444444-4444-4444-4444-444444444443") }
        ]
    };
}
