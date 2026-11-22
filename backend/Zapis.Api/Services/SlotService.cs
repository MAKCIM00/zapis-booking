using Zapis.Api.Domain;

namespace Zapis.Api.Services;

/// <summary>
/// Бизнес-логика свободных окон: сетка слотов от открытия до закрытия с шагом StepMinutes,
/// занятые интервалы мастера вычитаются. Всё храним в UTC, наружу отдаём ISO-8601.
/// </summary>
public sealed class SlotService(ScheduleOptions options)
{
    public IReadOnlyList<DateTime> FreeSlots(DateOnly date, int durationMinutes, IReadOnlyCollection<Booking> masterBookings)
    {
        var result = new List<DateTime>();
        var openLocal = date.ToDateTime(options.OpenTime);
        var lastStartLocal = date.ToDateTime(options.CloseTime).AddMinutes(-durationMinutes);
        var nowUtc = DateTime.UtcNow;

        for (var local = openLocal; local <= lastStartLocal; local = local.AddMinutes(options.StepMinutes))
        {
            var startUtc = ToUtc(local);
            if (startUtc <= nowUtc)
            {
                continue;
            }

            var endUtc = startUtc.AddMinutes(durationMinutes);
            var overlaps = masterBookings.Any(b => b.StartAt < endUtc && b.EndAt > startUtc);
            if (!overlaps)
            {
                result.Add(startUtc);
            }
        }

        return result;
    }

    /// <summary>Проверяет, что присланное клиентом время попадает в рабочую сетку.</summary>
    public bool IsAligned(DateTime startUtc, DateOnly date, int durationMinutes)
    {
        var local = TimeZoneInfo.ConvertTimeFromUtc(
            DateTime.SpecifyKind(startUtc, DateTimeKind.Utc), options.TimeZone);

        if (DateOnly.FromDateTime(local) != date)
        {
            return false;
        }

        var time = TimeOnly.FromDateTime(local);
        if (time < options.OpenTime || time > options.CloseTime.AddMinutes(-durationMinutes))
        {
            return false;
        }

        return (time.ToTimeSpan() - options.OpenTime.ToTimeSpan()).TotalMinutes % options.StepMinutes == 0;
    }

    public DateTime ToUtc(DateTime local) =>
        TimeZoneInfo.ConvertTimeToUtc(DateTime.SpecifyKind(local, DateTimeKind.Unspecified), options.TimeZone);
}
