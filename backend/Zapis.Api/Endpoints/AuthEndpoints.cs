using Zapis.Api.Domain;
using Zapis.Api.Infrastructure;

namespace Zapis.Api.Endpoints;

public static class AuthEndpoints
{
    public static void Map(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/auth").WithTags("Auth");

        group.MapPost("/register", RegisterAsync);
        group.MapPost("/login", LoginAsync);
        group.MapGet("/me", MeAsync).AddEndpointFilter<AuthFilter>();
    }

    private static async Task<IResult> RegisterAsync(
        RegisterRequest request,
        JsonDatabase database,
        PasswordHasher hasher,
        TokenService tokens)
    {
        var fullName = (request.FullName ?? string.Empty).Trim();
        var email = (request.Email ?? string.Empty).Trim().ToLowerInvariant();
        var phone = (request.Phone ?? string.Empty).Trim();
        var password = request.Password ?? string.Empty;

        var errors = new Dictionary<string, string[]>();
        if (fullName.Length < 2)
        {
            errors["fullName"] = ["Укажите имя и фамилию."];
        }

        if (email.Length < 5 || !email.Contains('@') || !email.Contains('.'))
        {
            errors["email"] = ["Укажите корректный email."];
        }

        if (phone.Length < 6)
        {
            errors["phone"] = ["Укажите номер телефона."];
        }

        if (password.Length < 6)
        {
            errors["password"] = ["Пароль должен быть не короче 6 символов."];
        }

        if (errors.Count > 0)
        {
            return Results.ValidationProblem(errors);
        }

        var exists = await database.ReadAsync(state => state.Users.Any(u => u.Email == email));
        if (exists)
        {
            return Results.Problem(
                title: "Email уже зарегистрирован",
                detail: "Попробуйте войти или восстановить пароль.",
                statusCode: StatusCodes.Status409Conflict);
        }

        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = email,
            PasswordHash = hasher.Hash(password),
            FullName = fullName,
            Phone = phone,
            CreatedAt = DateTime.UtcNow
        };

        await database.WriteAsync(state =>
        {
            state.Users.Add(user);
            return true;
        });

        return Results.Created("/api/profile", new AuthResponse(tokens.Create(user), user.ToDto()));
    }

    private static async Task<IResult> LoginAsync(
        LoginRequest request,
        JsonDatabase database,
        PasswordHasher hasher,
        TokenService tokens)
    {
        var email = (request.Email ?? string.Empty).Trim().ToLowerInvariant();
        var password = request.Password ?? string.Empty;

        var user = await database.ReadAsync(state => state.Users.FirstOrDefault(u => u.Email == email));

        if (user is null || !hasher.Verify(password, user.PasswordHash))
        {
            return Results.Problem(
                title: "Неверный email или пароль",
                statusCode: StatusCodes.Status401Unauthorized);
        }

        return Results.Ok(new AuthResponse(tokens.Create(user), user.ToDto()));
    }

    private static async Task<IResult> MeAsync(HttpContext http, JsonDatabase database)
    {
        var user = await database.ReadAsync(state => state.Users.FirstOrDefault(u => u.Id == http.UserId()));
        return user is null
            ? Results.Problem(title: "Пользователь не найден", statusCode: StatusCodes.Status404NotFound)
            : Results.Ok(user.ToDto());
    }
}
