namespace Zapis.Api.Domain;

/// <summary>Пользователь мобильного приложения (клиент салона).</summary>
public sealed class User
{
    public Guid Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

/// <summary>Категория услуг: волосы, ногти, брови, массаж.</summary>
public sealed class Category
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string Icon { get; set; } = string.Empty;
}

/// <summary>Мастер салона.</summary>
public sealed class Master
{
    public Guid Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Specialization { get; set; } = string.Empty;
    public double Rating { get; set; }
}

/// <summary>Услуга прайс-листа.</summary>
public sealed class Service
{
    public Guid Id { get; set; }
    public Guid CategoryId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int DurationMinutes { get; set; }
    public bool IsActive { get; set; } = true;
}

/// <summary>Связь many-to-many: какие мастера оказывают какую услугу.</summary>
public sealed class MasterService
{
    public Guid MasterId { get; set; }
    public Guid ServiceId { get; set; }
}

public enum BookingStatus
{
    Active,
    Cancelled
}

/// <summary>Запись клиента на услугу к конкретному мастеру.</summary>
public sealed class Booking
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid ServiceId { get; set; }
    public Guid MasterId { get; set; }
    public DateTime StartAt { get; set; }
    public DateTime EndAt { get; set; }
    public decimal PriceAtBooking { get; set; }
    public BookingStatus Status { get; set; }
    public string? Comment { get; set; }
    public DateTime CreatedAt { get; set; }
}
