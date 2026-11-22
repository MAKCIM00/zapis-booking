using Zapis.Api.Domain;
using Zapis.Api.Infrastructure;

namespace Zapis.Api.Endpoints;

public static class ProfileEndpoints
{
    public static void Map(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/profile")
            .WithTags("Profile")
            .AddEndpointFilter<AuthFilter>();

        group.MapGet("", GetAsync);
        group.MapPut("", UpdateAsync);
    }

    private static async Task<IResult> GetAsync(HttpContext http, JsonDatabase database)
    {
        var user = await database.ReadAsync(state => state.Users.FirstOrDefault(u => u.Id == http.UserId()));
        return user is null
            ? Results.Problem(title: "Пользователь не найден", statusCode: StatusCodes.Status404NotFound)
            : Results.Ok(user.ToDto());
    }

    private static async Task<IResult> UpdateAsync(
        UpdateProfileRequest request,
        HttpContext http,
        JsonDatabase database)
    {
        var fullName = (request.FullName ?? string.Empty).Trim();
        var phone = (request.Phone ?? string.Empty).Trim();

        var errors = new Dictionary<string, string[]>();
        if (fullName.Length < 2)
        {
            errors["fullName"] = ["Укажите имя и фамилию."];
        }

        if (phone.Length < 6)
        {
            errors["phone"] = ["Укажите номер телефона."];
        }

        if (errors.Count > 0)
        {
            return Results.ValidationProblem(errors);
        }

        var updated = await database.WriteAsync(state =>
        {
            var user = state.Users.FirstOrDefault(u => u.Id == http.UserId());
            if (user is null)
            {
                return null;
            }

            user.FullName = fullName;
            user.Phone = phone;
            return user.ToDto();
        });

        return updated is null ? Results.NotFound() : Results.Ok(updated);
    }
}
