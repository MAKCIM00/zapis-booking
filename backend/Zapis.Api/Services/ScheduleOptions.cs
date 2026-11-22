using System.Globalization;

namespace Zapis.Api.Services;

/// <summary>Настройки рабочего графика салона из appsettings.json (секция "Schedule").</summary>
public sealed class ScheduleOptions
{
    public TimeZoneInfo TimeZone { get; }
    public TimeOnly OpenTime { get; }
    public TimeOnly CloseTime { get; }
    public int StepMinutes { get; }

    public ScheduleOptions(IConfiguration configuration)
    {
        var section = configuration.GetSection("Schedule");
        var timeZoneId = section["TimeZone"] ?? "Asia/Tomsk";

        try
        {
            TimeZone = TimeZoneInfo.FindSystemTimeZoneById(timeZoneId);
        }
        catch (TimeZoneNotFoundException)
        {
            TimeZone = TimeZoneInfo.Local;
        }
        catch (InvalidTimeZoneException)
        {
            TimeZone = TimeZoneInfo.Local;
        }

        OpenTime = ParseTime(section["OpenTime"], new TimeOnly(10, 0));
        CloseTime = ParseTime(section["CloseTime"], new TimeOnly(20, 0));
        StepMinutes = section.GetValue("StepMinutes", 30);
    }

    private static TimeOnly ParseTime(string? value, TimeOnly fallback) =>
        TimeOnly.TryParseExact(value, "HH:mm", CultureInfo.InvariantCulture, DateTimeStyles.None, out var parsed)
            ? parsed
            : fallback;
}
