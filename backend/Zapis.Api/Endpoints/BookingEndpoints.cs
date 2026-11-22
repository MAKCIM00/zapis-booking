using Zapis.Api.Domain;
using Zapis.Api.Infrastructure;
using Zapis.Api.Services;

namespace Zapis.Api.Endpoints;

public static class BookingEndpoints
{
    private enum CreateOutcome
    {
        Created,
        ServiceNotFound,
        MasterDoesNotProvideService,
        SlotNotAligned,
        MasterBusy,
        UserBusy
    }

    public static void Map(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/bookings")
            .WithTags("Bookings")
            .AddEndpointFilter<AuthFilter>();

        group.MapPost("", CreateAsync);
        group.MapGet("", GetMyAsync);
        group.MapPost("/{id:guid}/cancel", CancelAsync);
    }

    private static async Task<IResult> CreateAsync(
        CreateBookingRequest request,
        HttpContext http,
        JsonDatabase database,
        SlotService slots,
        ScheduleOptions schedule)
    {
        var userId = http.UserId();
        var startAt = DateTime.SpecifyKind(request.StartAt, DateTimeKind.Utc);

        if (startAt <= DateTime.UtcNow)
        {
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["startAt"] = ["Нельзя записаться на прошедшее время."]
            });
        }

        var (outcome, booking) = await database.WriteAsync(state =>
        {
            var service = state.Services.FirstOrDefault(s => s.Id == request.ServiceId && s.IsActive);
            if (service is null)
            {
                return (CreateOutcome.ServiceNotFound, (Booking?)null);
            }

            var masterProvides = state.MasterServices
                .Any(ms => ms.ServiceId == service.Id && ms.MasterId == request.MasterId);

            if (!masterProvides)
            {
                return (CreateOutcome.MasterDoesNotProvideService, null);
            }

            var localDate = DateOnly.FromDateTime(
                TimeZoneInfo.ConvertTimeFromUtc(startAt, schedule.TimeZone));

            if (!slots.IsAligned(startAt, localDate, service.DurationMinutes))
            {
                return (CreateOutcome.SlotNotAligned, null);
            }

            var endAt = startAt.AddMinutes(service.DurationMinutes);

            var masterBusy = state.Bookings.Any(b =>
                b.Status == BookingStatus.Active &&
                b.MasterId == request.MasterId &&
                b.StartAt < endAt && b.EndAt > startAt);

            if (masterBusy)
            {
                return (CreateOutcome.MasterBusy, null);
            }

            var userBusy = state.Bookings.Any(b =>
                b.Status == BookingStatus.Active &&
                b.UserId == userId &&
                b.StartAt < endAt && b.EndAt > startAt);

            if (userBusy)
            {
                return (CreateOutcome.UserBusy, null);
            }

            var created = new Booking
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                ServiceId = service.Id,
                MasterId = request.MasterId,
                StartAt = startAt,
                EndAt = endAt,
                PriceAtBooking = service.Price,
                Status = BookingStatus.Active,
                Comment = string.IsNullOrWhiteSpace(request.Comment) ? null : request.Comment.Trim(),
                CreatedAt = DateTime.UtcNow
            };

            state.Bookings.Add(created);
            return (CreateOutcome.Created, created);
        });

        if (outcome == CreateOutcome.Created && booking is not null)
        {
            var dto = await database.ReadAsync(state => ToDto(state, booking));
            return Results.Created($"/api/bookings/{booking.Id}", dto);
        }

        return outcome switch
        {
            CreateOutcome.ServiceNotFound => Results.NotFound(new { message = "Услуга не найдена." }),
            CreateOutcome.MasterDoesNotProvideService => Results.BadRequest(new { message = "Мастер не оказывает эту услугу." }),
            CreateOutcome.SlotNotAligned => Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["startAt"] = ["Время не попадает в рабочую сетку салона."]
            }),
            _ => Results.Problem(
                title: "Это время уже занято",
                detail: "Выберите другое окно или другого мастера.",
                statusCode: StatusCodes.Status409Conflict)
        };
    }

    private static async Task<IResult> GetMyAsync(
        HttpContext http,
        JsonDatabase database,
        string? scope = "all")
    {
        var userId = http.UserId();
        var now = DateTime.UtcNow;

        var items = await database.ReadAsync(state =>
        {
            var query = state.Bookings.Where(b => b.UserId == userId);

            query = scope switch
            {
                "upcoming" => query.Where(b => b.Status == BookingStatus.Active && b.StartAt >= now),
                "past" => query.Where(b => b.StartAt < now || b.Status == BookingStatus.Cancelled),
                _ => query
            };

            var ordered = scope == "upcoming"
                ? query.OrderBy(b => b.StartAt)
                : query.OrderByDescending(b => b.StartAt);

            return ordered.Select(b => ToDto(state, b)).ToArray();
        });

        return Results.Ok(items);
    }

    private static async Task<IResult> CancelAsync(Guid id, HttpContext http, JsonDatabase database)
    {
        var userId = http.UserId();

        var (status, dto) = await database.WriteAsync(state =>
        {
            var booking = state.Bookings.FirstOrDefault(b => b.Id == id && b.UserId == userId);
            if (booking is null)
            {
                return ("not_found", (BookingDto?)null);
            }

            if (booking.Status == BookingStatus.Cancelled)
            {
                return ("already_cancelled", null);
            }

            if (booking.StartAt <= DateTime.UtcNow)
            {
                return ("too_late", null);
            }

            booking.Status = BookingStatus.Cancelled;
            return ("ok", ToDto(state, booking));
        });

        return status switch
        {
            "ok" => Results.Ok(dto),
            "already_cancelled" => Results.Problem(
                title: "Запись уже отменена",
                statusCode: StatusCodes.Status409Conflict),
            "too_late" => Results.Problem(
                title: "Нельзя отменить прошедшую запись",
                statusCode: StatusCodes.Status409Conflict),
            _ => Results.NotFound()
        };
    }

    private static BookingDto ToDto(DatabaseState state, Booking booking)
    {
        var service = state.Services.FirstOrDefault(s => s.Id == booking.ServiceId);
        var master = state.Masters.FirstOrDefault(m => m.Id == booking.MasterId);

        return new BookingDto(
            booking.Id,
            booking.ServiceId,
            service?.Title ?? "Услуга удалена",
            booking.MasterId,
            master?.FullName ?? "Мастер",
            booking.StartAt,
            booking.EndAt,
            booking.PriceAtBooking,
            booking.Status,
            booking.Comment,
            booking.CreatedAt);
    }
}
