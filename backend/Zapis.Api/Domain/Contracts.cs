namespace Zapis.Api.Domain;

// DTO-контракты API: наружу отдаём только эти модели, доменные сущности не светим.

public sealed record RegisterRequest(string FullName, string Email, string Phone, string Password);

public sealed record LoginRequest(string Email, string Password);

public sealed record UserDto(Guid Id, string FullName, string Email, string Phone);

public sealed record AuthResponse(string Token, UserDto User);

public sealed record CategoryDto(Guid Id, string Title, string Slug, string Icon);

public sealed record MasterDto(Guid Id, string FullName, string Specialization, double Rating);

public sealed record ServiceListItemDto(
    Guid Id,
    string Title,
    string Description,
    decimal Price,
    int DurationMinutes,
    string CategoryTitle,
    string CategorySlug,
    string CategoryIcon,
    MasterDto[] Masters);

public sealed record ServiceDetailsDto(
    Guid Id,
    string Title,
    string Description,
    decimal Price,
    int DurationMinutes,
    CategoryDto Category,
    MasterDto[] Masters);

public sealed record SlotDto(Guid MasterId, string MasterName, DateTime StartAt);

public sealed record ServiceSlotsDto(Guid ServiceId, DateOnly Date, int DurationMinutes, SlotDto[] Slots);

public sealed record CreateBookingRequest(Guid ServiceId, Guid MasterId, DateTime StartAt, string? Comment);

public sealed record BookingDto(
    Guid Id,
    Guid ServiceId,
    string ServiceTitle,
    Guid MasterId,
    string MasterName,
    DateTime StartAt,
    DateTime EndAt,
    decimal Price,
    BookingStatus Status,
    string? Comment,
    DateTime CreatedAt);

public sealed record UpdateProfileRequest(string FullName, string Phone);

public sealed record PagedResponse<T>(T[] Items, int Total, int Page, int PageSize);
