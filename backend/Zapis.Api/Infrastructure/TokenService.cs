using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Zapis.Api.Domain;

namespace Zapis.Api.Infrastructure;

/// <summary>
/// Минимальная реализация JWT (HS256) без сторонних библиотек:
/// header.payload.signature, подпись — HMACSHA256 по ключу из конфигурации.
/// </summary>
public sealed class TokenService
{
    private readonly byte[] _key;
    private readonly string _issuer;
    private readonly int _lifetimeMinutes;

    public TokenService(IConfiguration configuration)
    {
        var key = configuration["Jwt:Key"];
        if (string.IsNullOrWhiteSpace(key) || key.Length < 32)
        {
            throw new InvalidOperationException("Jwt:Key должен быть задан и содержать минимум 32 символа.");
        }

        _key = Encoding.UTF8.GetBytes(key);
        _issuer = configuration["Jwt:Issuer"] ?? "zapis-api";
        _lifetimeMinutes = configuration.GetValue("Jwt:LifetimeMinutes", 720);
    }

    public string Create(User user)
    {
        var now = DateTimeOffset.UtcNow;
        var payload = new Dictionary<string, object>
        {
            ["sub"] = user.Id.ToString(),
            ["email"] = user.Email,
            ["name"] = user.FullName,
            ["iss"] = _issuer,
            ["iat"] = now.ToUnixTimeSeconds(),
            ["exp"] = now.AddMinutes(_lifetimeMinutes).ToUnixTimeSeconds()
        };

        var header = Base64Url(JsonSerializer.SerializeToUtf8Bytes(new { alg = "HS256", typ = "JWT" }));
        var body = Base64Url(JsonSerializer.SerializeToUtf8Bytes(payload));
        var signature = Base64Url(Sign($"{header}.{body}"));
        return $"{header}.{body}.{signature}";
    }

    public bool TryValidate(string token, out Guid userId)
    {
        userId = Guid.Empty;
        var parts = token.Split('.');
        if (parts.Length != 3)
        {
            return false;
        }

        var expected = Sign($"{parts[0]}.{parts[1]}");
        byte[] actual;
        try
        {
            actual = FromBase64Url(parts[2]);
        }
        catch (FormatException)
        {
            return false;
        }

        if (!CryptographicOperations.FixedTimeEquals(expected, actual))
        {
            return false;
        }

        try
        {
            using var document = JsonDocument.Parse(FromBase64Url(parts[1]));
            var root = document.RootElement;

            if (root.TryGetProperty("exp", out var exp) &&
                exp.GetInt64() < DateTimeOffset.UtcNow.ToUnixTimeSeconds())
            {
                return false;
            }

            if (!root.TryGetProperty("sub", out var sub) || !Guid.TryParse(sub.GetString(), out userId))
            {
                return false;
            }

            return true;
        }
        catch (JsonException)
        {
            return false;
        }
    }

    private byte[] Sign(string value) =>
        HMACSHA256.HashData(_key, Encoding.UTF8.GetBytes(value));

    private static string Base64Url(byte[] bytes) =>
        Convert.ToBase64String(bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_');

    private static byte[] FromBase64Url(string value)
    {
        var padded = value.Replace('-', '+').Replace('_', '/');
        padded = padded.PadRight(padded.Length + (4 - padded.Length % 4) % 4, '=');
        return Convert.FromBase64String(padded);
    }
}
