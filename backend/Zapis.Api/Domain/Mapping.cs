namespace Zapis.Api.Domain;

/// <summary>Преобразование доменных сущностей в DTO для ответов API.</summary>
public static class Mapping
{
    public static UserDto ToDto(this User user) =>
        new(user.Id, user.FullName, user.Email, user.Phone);

    public static MasterDto ToDto(this Master master) =>
        new(master.Id, master.FullName, master.Specialization, master.Rating);

    public static CategoryDto ToDto(this Category category) =>
        new(category.Id, category.Title, category.Slug, category.Icon);
}
