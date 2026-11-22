using Zapis.Api.Domain;
using Zapis.Api.Infrastructure;
using Zapis.Api.Services;

namespace Zapis.Api.Endpoints;

public static class CatalogEndpoints
{
    public static void Map(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api").WithTags("Catalog");

        group.MapGet("/categories", GetCategoriesAsync);
        group.MapGet("/services", GetServicesAsync);
        group.MapGet("/services/{id:guid}", GetServiceAsync);
        group.MapGet("/services/{id:guid}/slots", GetSlotsAsync);
    }

    private static async Task<IResult> GetCategoriesAsync(JsonDatabase database)
    {
        var items = await database.ReadAsync(state =>
            state.Categories.OrderBy(c => c.Title).Select(c => c.ToDto()).ToArray());

        return Results.Ok(items);
    }

    private static async Task<IResult> GetServicesAsync(
        JsonDatabase database,
        string? q = null,
        Guid? categoryId = null,
        int page = 1,
        int pageSize = 12)
    {
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 50);
        var search = q?.Trim();

        var response = await database.ReadAsync(state =>
        {
            IEnumerable<Service> query = state.Services.Where(s => s.IsActive);

            if (categoryId is { } id)
            {
                query = query.Where(s => s.CategoryId == id);
            }

            if (!string.IsNullOrWhiteSpace(search))
            {
                query = query.Where(s =>
                    s.Title.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                    s.Description.Contains(search, StringComparison.OrdinalIgnoreCase));
            }

            var ordered = query.OrderBy(s => s.Title).ToList();
            var items = ordered
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(s => ToListItem(state, s))
                .ToArray();

            return new PagedResponse<ServiceListItemDto>(items, ordered.Count, page, pageSize);
        });

        return Results.Ok(response);
    }

    private static async Task<IResult> GetServiceAsync(Guid id, JsonDatabase database)
    {
        var dto = await database.ReadAsync(state =>
        {
            var service = state.Services.FirstOrDefault(s => s.Id == id && s.IsActive);
            if (service is null)
            {
                return null;
            }

            var category = state.Categories.First(c => c.Id == service.CategoryId);
            var masters = state.MasterServices
                .Where(ms => ms.ServiceId == service.Id)
                .Join(state.Masters, ms => ms.MasterId, m => m.Id, (_, m) => m.ToDto())
                .ToArray();

            return new ServiceDetailsDto(
                service.Id, service.Title, service.Description, service.Price,
                service.DurationMinutes, category.ToDto(), masters);
        });

        return dto is null ? Results.NotFound() : Results.Ok(dto);
    }

    private static async Task<IResult> GetSlotsAsync(
        Guid id,
        JsonDatabase database,
        SlotService slots,
        ScheduleOptions schedule,
        DateOnly? date = null,
        Guid? masterId = null)
    {
        var day = date ?? DateOnly.FromDateTime(
            TimeZoneInfo.ConvertTime(DateTime.UtcNow, schedule.TimeZone).AddDays(1));

        var result = await database.ReadAsync(state =>
        {
            var service = state.Services.FirstOrDefault(s => s.Id == id && s.IsActive);
            if (service is null)
            {
                return (Found: false, Dto: (ServiceSlotsDto?)null);
            }

            var masterIds = state.MasterServices
                .Where(ms => ms.ServiceId == service.Id)
                .Select(ms => ms.MasterId)
                .ToList();

            if (masterId is { } only)
            {
                masterIds = masterIds.Where(m => m == only).ToList();
            }

            var dayStartUtc = slots.ToUtc(day.ToDateTime(TimeOnly.MinValue));
            var dayEndUtc = dayStartUtc.AddDays(1);

            var bookings = state.Bookings
                .Where(b => b.Status == BookingStatus.Active
                            && masterIds.Contains(b.MasterId)
                            && b.StartAt >= dayStartUtc
                            && b.StartAt < dayEndUtc)
                .ToList();

            var free = new List<SlotDto>();
            foreach (var masterIdValue in masterIds)
            {
                var master = state.Masters.First(m => m.Id == masterIdValue);
                var busy = bookings.Where(b => b.MasterId == masterIdValue).ToList();

                free.AddRange(slots
                    .FreeSlots(day, service.DurationMinutes, busy)
                    .Select(start => new SlotDto(master.Id, master.FullName, start)));
            }

            var ordered = free.OrderBy(s => s.StartAt).ThenBy(s => s.MasterName).ToArray();
            return (Found: true, Dto: (ServiceSlotsDto?)new ServiceSlotsDto(
                service.Id, day, service.DurationMinutes, ordered));
        });

        if (!result.Found || result.Dto is null)
        {
            return Results.NotFound();
        }

        return Results.Ok(result.Dto);
    }

    private static ServiceListItemDto ToListItem(DatabaseState state, Service service)
    {
        var category = state.Categories.FirstOrDefault(c => c.Id == service.CategoryId);
        var masters = state.MasterServices
            .Where(ms => ms.ServiceId == service.Id)
            .Join(state.Masters, ms => ms.MasterId, m => m.Id, (_, m) => m.ToDto())
            .ToArray();

        return new ServiceListItemDto(
            service.Id,
            service.Title,
            service.Description,
            service.Price,
            service.DurationMinutes,
            category?.Title ?? string.Empty,
            category?.Slug ?? string.Empty,
            category?.Icon ?? string.Empty,
            masters);
    }
}
