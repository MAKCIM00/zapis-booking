using System.Text.Json;
using System.Text.Json.Serialization;
using Zapis.Api.Domain;

namespace Zapis.Api.Infrastructure;

/// <summary>Корневой документ хранилища — по сути, "таблицы" в одном JSON-файле.</summary>
public sealed class DatabaseState
{
    public List<User> Users { get; set; } = [];
    public List<Category> Categories { get; set; } = [];
    public List<Master> Masters { get; set; } = [];
    public List<Service> Services { get; set; } = [];
    public List<MasterService> MasterServices { get; set; } = [];
    public List<Booking> Bookings { get; set; } = [];
}

/// <summary>
/// Потокобезопасное JSON-хранилище: читаем/пишем под одним семафором,
/// сохраняем атомарно через временный файл.
/// Слой спрятан за этим классом, чтобы заменить его на EF Core + PostgreSQL,
/// не трогая эндпоинты (см. database/schema.sql и README).
/// </summary>
public sealed class JsonDatabase
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        WriteIndented = true,
        Converters = { new JsonStringEnumConverter(JsonNamingPolicy.CamelCase) }
    };

    private readonly string _filePath;
    private readonly PasswordHasher _hasher;
    private readonly ILogger<JsonDatabase> _logger;
    private readonly SemaphoreSlim _gate = new(1, 1);
    private DatabaseState _state = new();

    public JsonDatabase(
        IHostEnvironment environment,
        IConfiguration configuration,
        PasswordHasher hasher,
        ILogger<JsonDatabase> logger)
    {
        _hasher = hasher;
        _logger = logger;
        var relativePath = configuration["Storage:Path"] ?? "App_Data/db.json";
        _filePath = Path.Combine(environment.ContentRootPath, relativePath);
    }

    public async Task InitializeAsync()
    {
        Directory.CreateDirectory(Path.GetDirectoryName(_filePath)!);

        if (File.Exists(_filePath))
        {
            var json = await File.ReadAllTextAsync(_filePath);
            _state = JsonSerializer.Deserialize<DatabaseState>(json, JsonOptions) ?? SeedData.Create(_hasher);
            _logger.LogInformation("Хранилище загружено: {Path}", _filePath);
            return;
        }

        _state = SeedData.Create(_hasher);
        await SaveAsync();
        _logger.LogInformation("Хранилище создано и заполнено демо-данными: {Path}", _filePath);
    }

    /// <summary>Чтение под блокировкой: возвращаем проекцию, а не ссылки на сущности.</summary>
    public async Task<T> ReadAsync<T>(Func<DatabaseState, T> query, CancellationToken cancellationToken = default)
    {
        await _gate.WaitAsync(cancellationToken);
        try
        {
            return query(_state);
        }
        finally
        {
            _gate.Release();
        }
    }

    /// <summary>Изменение + сохранение на диск одной операцией.</summary>
    public async Task<T> WriteAsync<T>(Func<DatabaseState, T> mutate, CancellationToken cancellationToken = default)
    {
        await _gate.WaitAsync(cancellationToken);
        try
        {
            var result = mutate(_state);
            await SaveAsync();
            return result;
        }
        finally
        {
            _gate.Release();
        }
    }

    private async Task SaveAsync()
    {
        var tempPath = _filePath + ".tmp";
        await File.WriteAllTextAsync(tempPath, JsonSerializer.Serialize(_state, JsonOptions));
        File.Move(tempPath, _filePath, overwrite: true);
    }
}
