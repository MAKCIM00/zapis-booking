using System.Text.Json;
using System.Text.Json.Serialization;
using Zapis.Api.Endpoints;
using Zapis.Api.Infrastructure;
using Zapis.Api.Services;

var builder = WebApplication.CreateBuilder(args);

// Enum'ы в JSON отдаём строками: "active" / "cancelled", а не 0/1.
builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.Converters.Add(new JsonStringEnumConverter(JsonNamingPolicy.CamelCase));
});

builder.Services.AddSingleton<PasswordHasher>();
builder.Services.AddSingleton<TokenService>();
builder.Services.AddSingleton<ScheduleOptions>();
builder.Services.AddSingleton<SlotService>();
builder.Services.AddSingleton<JsonDatabase>();

// Мобильному клиенту нужен CORS (Flutter Web / отладка), для нативных сборок он безвреден.
builder.Services.AddCors(options =>
    options.AddPolicy("mobile", policy => policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

var app = builder.Build();

app.UseCors("mobile");

// Инициализация хранилища: создаём файл и наполняем демо-данными при первом запуске.
await app.Services.GetRequiredService<JsonDatabase>().InitializeAsync();

app.MapGet("/health", () => Results.Ok(new
{
    status = "ok",
    service = "zapis-api",
    time = DateTime.UtcNow
}));

app.MapGet("/", () => Results.Ok(new
{
    service = "zapis-api",
    version = "1.0",
    health = "/health",
    auth = new[] { "POST /api/auth/register", "POST /api/auth/login", "GET /api/auth/me" },
    catalog = new[] { "GET /api/categories", "GET /api/services", "GET /api/services/{id}", "GET /api/services/{id}/slots" },
    bookings = new[] { "POST /api/bookings", "GET /api/bookings?scope=upcoming|past|all", "POST /api/bookings/{id}/cancel" },
    profile = new[] { "GET /api/profile", "PUT /api/profile" }
}));

AuthEndpoints.Map(app);
CatalogEndpoints.Map(app);
BookingEndpoints.Map(app);
ProfileEndpoints.Map(app);

app.Run();
