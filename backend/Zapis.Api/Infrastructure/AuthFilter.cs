namespace Zapis.Api.Infrastructure;

/// <summary>
/// Проверка Bearer-токена для защищённых эндпоинтов.
/// Кладём Guid пользователя в HttpContext.Items, дальше его читает любой обработчик.
/// </summary>
public sealed class AuthFilter(TokenService tokens) : IEndpointFilter
{
    public async ValueTask<object?> InvokeAsync(EndpointFilterInvocationContext context, EndpointFilterDelegate next)
    {
        var http = context.HttpContext;
        var header = http.Request.Headers.Authorization.ToString();

        if (!header.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase) ||
            !tokens.TryValidate(header["Bearer ".Length..].Trim(), out var userId))
        {
            return Results.Problem(
                title: "Не авторизован",
                detail: "Передайте заголовок Authorization: Bearer <token>.",
                statusCode: StatusCodes.Status401Unauthorized);
        }

        http.Items[HttpContextExtensions.UserIdKey] = userId;
        return await next(context);
    }
}

public static class HttpContextExtensions
{
    public const string UserIdKey = "UserId";

    public static Guid UserId(this HttpContext context) =>
        context.Items[UserIdKey] is Guid id
            ? id
            : throw new InvalidOperationException("Эндпоинт не защищён AuthFilter.");
}
