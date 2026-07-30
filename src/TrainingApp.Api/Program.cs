using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json.Serialization;
using System.Text.Json.Nodes;
using System.Text.RegularExpressions;
using System.Net;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using Microsoft.Extensions.Caching.Memory;
using Swashbuckle.AspNetCore.SwaggerGen;
using TrainingApp.Api.Data;
using TrainingApp.Api.Domain;
using TrainingApp.Api.Services;

var builder = WebApplication.CreateBuilder(args);
var connectionString = Environment.GetEnvironmentVariable("TRAINING_DB_CONNECTION") ?? "Host=localhost;Port=5432;Database=training;Username=training;Password=training";
var jwtKey = Environment.GetEnvironmentVariable("TRAINING_JWT_KEY") ?? (builder.Environment.IsDevelopment() ? "development-only-key-change-me-32-bytes" : throw new InvalidOperationException("TRAINING_JWT_KEY is required"));
builder.Services.AddDbContext<AppDbContext>(o => o.UseNpgsql(connectionString, npgsql => npgsql.MigrationsHistoryTable("__EFMigrationsHistory", "public")));
builder.Services.AddHealthChecks().AddNpgSql(connectionString);
builder.Services.AddHttpClient();
builder.Services.AddMemoryCache();
builder.Services.AddProblemDetails();
builder.Services.AddDataProtection()
    .PersistKeysToFileSystem(new DirectoryInfo(Environment.GetEnvironmentVariable("TRAINING_DATA_PROTECTION_KEYS_PATH") ?? Path.Combine(builder.Environment.ContentRootPath, ".data-protection-keys")))
    .SetApplicationName("TrainingApp");
builder.Services.ConfigureHttpJsonOptions(o => { o.SerializerOptions.Converters.Add(new JsonStringEnumConverter()); o.SerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles; });
builder.Services.AddAuthentication(o => { o.DefaultScheme = "smart"; o.DefaultChallengeScheme = "smart"; })
    .AddPolicyScheme("smart", "Cookie or Bearer", o => o.ForwardDefaultSelector = c => c.Request.Headers.Authorization.ToString().StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase) ? JwtBearerDefaults.AuthenticationScheme : CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(o => { o.Cookie.Name = "training.auth"; o.Cookie.HttpOnly = true; o.Cookie.SameSite = SameSiteMode.Strict; o.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest; o.Cookie.MaxAge = TimeSpan.FromDays(30); o.ExpireTimeSpan = TimeSpan.FromDays(30); o.SlidingExpiration = true; o.Events.OnRedirectToLogin = c => { c.Response.StatusCode = 401; return Task.CompletedTask; }; })
    .AddJwtBearer(o => { o.TokenValidationParameters = TokenFactory.Validation(jwtKey); });
builder.Services.AddAuthorization(o => o.AddPolicy("admin", p => p.RequireClaim("is_admin", "true")));
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(o => { o.SwaggerDoc("v1", new OpenApiInfo { Title = "Training API", Version = "v1" }); o.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme { Type = SecuritySchemeType.Http, Scheme = "bearer", BearerFormat = "JWT" }); o.AddSecurityRequirement(document => new OpenApiSecurityRequirement { [new OpenApiSecuritySchemeReference("Bearer", document)] = [] }); o.OperationFilter<AllowAnonymousOperationFilter>(); o.SchemaFilter<StringEnumSchemaFilter>(); });

var app = builder.Build();
var forwardedHeaders = new ForwardedHeadersOptions { ForwardedHeaders = ForwardedHeaders.XForwardedProto };
forwardedHeaders.KnownIPNetworks.Clear(); forwardedHeaders.KnownProxies.Clear();
app.UseForwardedHeaders(forwardedHeaders);
app.UseExceptionHandler(); app.UseSwagger(); app.UseSwaggerUI(); app.UseDefaultFiles(); app.UseStaticFiles(); app.UseAuthentication(); app.UseAuthorization();
app.MapHealthChecks("/health/live", new HealthCheckOptions { Predicate = _ => false }).AllowAnonymous();
app.MapHealthChecks("/health/ready").AllowAnonymous();

var api = app.MapGroup("/api/v1");
api.MapPost("/auth/login", async (LoginRequest request, bool? web, AppDbContext db, HttpContext http, CancellationToken ct) =>
{
    var user = await db.Users.SingleOrDefaultAsync(x => x.UserName == request.UserName, ct);
    if (user is null || !user.IsActive || new PasswordHasher<LocalUser>().VerifyHashedPassword(user, user.PasswordHash, request.Password) == PasswordVerificationResult.Failed) return Results.Unauthorized();
    var claims = UserClaims(user);
    if (web == true) { await http.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, new ClaimsPrincipal(new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme)), PersistentCookie()); return Results.Ok(new { authenticated = true }); }
    var issued = await TokenFactory.IssueAsync(db, user, jwtKey, ct);
    return Results.Ok(issued.Response);
}).Produces<TokenResponse>().Produces(401).AllowAnonymous();
api.MapPost("/auth/refresh", async (RefreshRequest request, AppDbContext db, CancellationToken ct) =>
{
    var hash = TokenFactory.Hash(request.RefreshToken); var existing = await db.RefreshTokens.SingleOrDefaultAsync(x => x.TokenHash == hash, ct);
    if (existing is null || existing.RevokedAt != null || existing.ExpiresAt <= DateTimeOffset.UtcNow) return Results.Unauthorized();
    var user = await db.Users.SingleOrDefaultAsync(x => x.Id == existing.UserId && x.IsActive, ct); if (user is null) return Results.Unauthorized(); existing.RevokedAt = DateTimeOffset.UtcNow; var issued = await TokenFactory.IssueAsync(db, user, jwtKey, ct); existing.ReplacedById = issued.TokenId; await db.SaveChangesAsync(ct); return Results.Ok(issued.Response);
}).AllowAnonymous();
api.MapPost("/auth/logout", async (RefreshRequest? request, AppDbContext db, HttpContext http, CancellationToken ct) => { if (request?.RefreshToken is { Length: > 0 }) { var hash = TokenFactory.Hash(request.RefreshToken); var token = await db.RefreshTokens.SingleOrDefaultAsync(x => x.TokenHash == hash, ct); if (token != null && token.RevokedAt == null) token.RevokedAt = DateTimeOffset.UtcNow; await db.SaveChangesAsync(ct); } await http.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme); return Results.NoContent(); }).Produces(204).AllowAnonymous();

var users = api.MapGroup("/users").RequireAuthorization();
users.MapGet("/me", async (HttpContext h, AppDbContext db, CancellationToken ct) => { var id = UserId(h); var user = await db.Users.AsNoTracking().SingleAsync(x => x.Id == id, ct); return Results.Ok(UserResponse.From(user)); });
users.MapPut("/me/preferences", async (UserPreferencesRequest r, HttpContext h, AppDbContext db, CancellationToken ct) => { if (r.ColorTheme is not ("purple" or "toxic" or "red")) return Results.BadRequest(new { error = "colorTheme must be purple, toxic, or red" }); var id = UserId(h); var user = await db.Users.SingleAsync(x => x.Id == id, ct); user.ColorTheme = r.ColorTheme; await db.SaveChangesAsync(ct); return Results.Ok(UserResponse.From(user)); });
users.MapPut("/me/password", async (ChangePasswordRequest r, HttpContext h, AppDbContext db, CancellationToken ct) => { if (r.NewPassword.Length < 12) return Results.BadRequest(new { error = "New password must contain at least 12 characters" }); var id = UserId(h); var user = await db.Users.SingleAsync(x => x.Id == id, ct); var hasher = new PasswordHasher<LocalUser>(); if (hasher.VerifyHashedPassword(user, user.PasswordHash, r.CurrentPassword) == PasswordVerificationResult.Failed) return Results.Unauthorized(); user.PasswordHash = hasher.HashPassword(user, r.NewPassword); var tokens = await db.RefreshTokens.Where(x => x.UserId == id && x.RevokedAt == null).ToListAsync(ct); tokens.ForEach(x => x.RevokedAt = DateTimeOffset.UtcNow); await db.SaveChangesAsync(ct); return Results.NoContent(); });
users.MapGet("/", async (AppDbContext db, CancellationToken ct) => (await db.Users.AsNoTracking().OrderBy(x => x.UserName).ToListAsync(ct)).Select(UserResponse.From)).RequireAuthorization("admin");
users.MapPost("/", async (CreateUserRequest r, AppDbContext db, CancellationToken ct) => { if (string.IsNullOrWhiteSpace(r.UserName) || r.Password.Length < 12) return Results.BadRequest(new { error = "Username is required and password must contain at least 12 characters" }); if (await db.Users.AnyAsync(x => x.UserName == r.UserName.Trim(), ct)) return Results.Conflict(new { error = "Username already exists" }); var user = new LocalUser { UserName = r.UserName.Trim(), PasswordHash = "pending", IsAdmin = r.IsAdmin }; user.PasswordHash = new PasswordHasher<LocalUser>().HashPassword(user, r.Password); db.Add(user); await db.SaveChangesAsync(ct); return Results.Created($"/api/v1/users/{user.Id}", UserResponse.From(user)); }).RequireAuthorization("admin");
users.MapPut("/{id:guid}", async (Guid id, UpdateUserRequest r, HttpContext h, AppDbContext db, CancellationToken ct) => { var user = await db.Users.FindAsync([id], ct); if (user is null) return Results.NotFound(); if (id == UserId(h) && r.IsActive == false) return Results.BadRequest(new { error = "An administrator cannot deactivate the current account" }); if (r.Password is { Length: > 0 and < 12 }) return Results.BadRequest(new { error = "Password must contain at least 12 characters" }); user.IsActive = r.IsActive; user.IsAdmin = r.IsAdmin; if (!string.IsNullOrEmpty(r.Password)) { user.PasswordHash = new PasswordHasher<LocalUser>().HashPassword(user, r.Password); var tokens = await db.RefreshTokens.Where(x => x.UserId == id && x.RevokedAt == null).ToListAsync(ct); tokens.ForEach(x => x.RevokedAt = DateTimeOffset.UtcNow); } await db.SaveChangesAsync(ct); return Results.Ok(UserResponse.From(user)); }).RequireAuthorization("admin");

var exercises = api.MapGroup("/exercises").RequireAuthorization();
exercises.MapGet("/", async (HttpContext h, AppDbContext db, CancellationToken ct, bool archived = false) => { var owner = UserId(h); return await db.Exercises.Where(x => (x.OwnerId == null || x.OwnerId == owner) && (archived || !x.IsArchived)).OrderBy(x => x.Name).AsNoTracking().ToListAsync(ct); }).Produces<IReadOnlyList<Exercise>>().Produces(401);
exercises.MapGet("/{id:guid}", async (Guid id, HttpContext h, AppDbContext db, CancellationToken ct) => { var owner = UserId(h); return await db.Exercises.AsNoTracking().SingleOrDefaultAsync(x => x.Id == id && (x.OwnerId == null || x.OwnerId == owner), ct) is { } x ? Results.Ok(x) : Results.NotFound(); });
exercises.MapPost("/", async (ExerciseWrite r, HttpContext h, AppDbContext db, CancellationToken ct) => { var x = new Exercise { Id = r.Id ?? Guid.NewGuid(), OwnerId = UserId(h), Name = r.Name.Trim(), Description = r.Description, MuscleGroup = r.MuscleGroup.Trim(), Equipment = r.Equipment.Trim(), ImageUrl = r.ImageUrl, SourceUrl = r.SourceUrl, LicenseName = r.LicenseName, LicenseUrl = r.LicenseUrl, SourceAuthor = r.SourceAuthor }; db.Add(x); await db.SaveChangesAsync(ct); return Results.Created($"/api/v1/exercises/{x.Id}", x); });
exercises.MapPut("/{id:guid}", async (Guid id, ExerciseWrite r, HttpContext h, AppDbContext db, CancellationToken ct) => { var owner = UserId(h); var x = await db.Exercises.SingleOrDefaultAsync(x => x.Id == id && x.OwnerId == owner, ct); if (x is null) return Results.NotFound(); x.Name = r.Name.Trim(); x.Description = r.Description; x.MuscleGroup = r.MuscleGroup.Trim(); x.Equipment = r.Equipment.Trim(); x.ImageUrl = r.ImageUrl; x.SourceUrl = r.SourceUrl; x.LicenseName = r.LicenseName; x.LicenseUrl = r.LicenseUrl; x.SourceAuthor = r.SourceAuthor; x.IsArchived = r.IsArchived; x.UpdatedAt = DateTimeOffset.UtcNow; await db.SaveChangesAsync(ct); return Results.Ok(x); });
exercises.MapDelete("/{id:guid}", async (Guid id, HttpContext h, AppDbContext db, CancellationToken ct) => { var owner = UserId(h); var x = await db.Exercises.SingleOrDefaultAsync(x => x.Id == id && x.OwnerId == owner, ct); if (x is null) return Results.NotFound(); x.IsArchived = true; x.UpdatedAt = DateTimeOffset.UtcNow; await db.SaveChangesAsync(ct); return Results.NoContent(); });
exercises.MapGet("/{id:guid}/history", async (Guid id, HttpContext h, AppDbContext db, CancellationToken ct) => { var owner = UserId(h); return await db.SetEntries.Where(x => x.WorkoutExercise!.ExerciseId == id && x.WorkoutExercise.Workout!.OwnerId == owner && x.Status == SetStatus.Completed).OrderByDescending(x => x.CompletedAt).AsNoTracking().ToListAsync(ct); });
exercises.MapGet("/{id:guid}/records", async (Guid id, HttpContext h, AppDbContext db, CancellationToken ct) => Results.Ok(await RecordsService.GetAsync(db, id, UserId(h), ct))).Produces<RecordsResponse>().Produces(401);
exercises.MapGet("/library/search", async (string? search, int? offset, IHttpClientFactory clients, IMemoryCache cache, CancellationToken ct) =>
{
    var skip = Math.Max(0, offset ?? 0);
    var term = search?.Trim();
    var page = await cache.GetOrCreateAsync("wger-exercise-library", entry =>
    {
        entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(1);
        return clients.CreateClient().GetFromJsonAsync<WgerPage>("https://wger.de/api/v2/exerciseinfo/?language=2&limit=1000", ct);
    });
    var rows = (page?.Results ?? []).Select(x =>
    {
        var translation = x.Translations.FirstOrDefault(t => t.Language == 2);
        var image = x.Images.FirstOrDefault(i => i.IsMain) ?? x.Images.FirstOrDefault();
        return new LibraryExercise(x.Uuid, translation?.Name ?? $"Exercise {x.Id}", PlainText(translation?.Description), x.Category.Name,
            string.Join(", ", x.Equipment.Select(e => e.Name)), image?.Image, $"https://wger.de/en/exercise/{x.Id}/view/", x.License.ShortName,
            x.License.Url, translation?.LicenseAuthor ?? x.LicenseAuthor);
    }).Where(x => GymEquipment(x.Equipment) && (string.IsNullOrWhiteSpace(term) || x.Name.Contains(term, StringComparison.OrdinalIgnoreCase)
        || x.MuscleGroup.Contains(term, StringComparison.OrdinalIgnoreCase) || x.Equipment.Contains(term, StringComparison.OrdinalIgnoreCase)))
        .OrderByDescending(x => EquipmentPriority(x.Equipment)).ThenBy(x => x.Name).ToList();
    var count = rows.Count;
    rows = rows.Skip(skip).Take(24).ToList();
    return Results.Ok(new { count, offset = skip, pageSize = 24, results = rows });
});

var workouts = api.MapGroup("/workouts").RequireAuthorization();
workouts.MapGet("/", async (DateTimeOffset? from, DateTimeOffset? to, HttpContext h, AppDbContext db, CancellationToken ct) => { if (from.HasValue != to.HasValue || (from.HasValue && (from >= to || to > from.Value.AddYears(5)))) return Results.BadRequest(new { error = "from and to must define a valid range of at most five years" }); var owner = UserId(h); var rows = await db.Workouts.Where(x => x.OwnerId == owner && (!from.HasValue || x.ScheduledAt >= from) && (!to.HasValue || x.ScheduledAt < to)).OrderBy(x => x.ScheduledAt).Select(x => new CalendarWorkout(x.Id, x.Name, x.ScheduledAt, x.StartedAt, x.CompletedAt, x.Status, x.Version, x.Exercises.SelectMany(e => e.Sets.Where(s => s.Status == SetStatus.Completed && s.ActualWeightKg != null && s.ActualReps != null)).Sum(s => (decimal?)(s.ActualWeightKg!.Value * s.ActualReps!.Value * s.WorkoutExercise!.WeightMultiplier)) ?? 0)).AsNoTracking().ToListAsync(ct); return Results.Ok(rows); }).Produces<IReadOnlyList<CalendarWorkout>>().Produces(400).Produces(401);
workouts.MapGet("/{id:guid}", async (Guid id, AppDbContext db, HttpContext h, CancellationToken ct) => { var owner = UserId(h); var x = await db.Workouts.Include(x => x.Exercises.OrderBy(e => e.Order)).ThenInclude(e => e.Exercise).Include(x => x.Exercises).ThenInclude(e => e.Sets.OrderBy(s => s.Order)).AsNoTracking().SingleOrDefaultAsync(x => x.Id == id && x.OwnerId == owner, ct); if (x is null) return Results.NotFound(); h.Response.Headers.ETag = $"\"{x.Version}\""; return Results.Ok(x); }).Produces<Workout>().Produces(404).Produces(401);
workouts.MapPost("/", async (WorkoutWrite r, HttpContext h, AppDbContext db, CancellationToken ct) => { var x = new Workout { Id = r.Id ?? Guid.NewGuid(), OwnerId = UserId(h), Name = r.Name, ScheduledAt = r.ScheduledAt, Notes = r.Notes }; db.Add(x); await db.SaveChangesAsync(ct); return Results.Created($"/api/v1/workouts/{x.Id}", x); }).Produces<Workout>(201).Produces(401);
workouts.MapPut("/{id:guid}", UpdateWorkout).Produces<Workout>().Produces(404).Produces(409).Produces(401);
workouts.MapPost("/{id:guid}/start", async (Guid id, HttpContext h, AppDbContext db, CancellationToken ct) => { var owner = UserId(h); var x = await db.Workouts.SingleOrDefaultAsync(x => x.Id == id && x.OwnerId == owner, ct); if (x is null) return Results.NotFound(); if (x.Status != WorkoutStatus.Planned) return Results.Conflict(new { error = "Only a planned workout can start", current = x }); x.Status = WorkoutStatus.InProgress; x.StartedAt = DateTimeOffset.UtcNow; Touch(x); await db.SaveChangesAsync(ct); return Results.Ok(x); });
workouts.MapPost("/{id:guid}/complete", async (Guid id, HttpContext h, AppDbContext db, CancellationToken ct) => { var owner = UserId(h); var x = await db.Workouts.SingleOrDefaultAsync(x => x.Id == id && x.OwnerId == owner, ct); if (x is null) return Results.NotFound(); if (x.Status != WorkoutStatus.InProgress) return Results.Conflict(new { error = "Only an in-progress workout can complete", current = x }); x.Status = WorkoutStatus.Completed; x.CompletedAt = DateTimeOffset.UtcNow; Touch(x); await db.SaveChangesAsync(ct); return Results.Ok(x); });
workouts.MapPost("/{id:guid}/exercises", async (Guid id, WorkoutExerciseWrite r, HttpContext h, AppDbContext db, CancellationToken ct) => { if (r.WeightMultiplier is not (1 or 2)) return Results.BadRequest(new { error = "weightMultiplier must be 1 or 2" }); var owner = UserId(h); if (!await db.Workouts.AnyAsync(x => x.Id == id && x.OwnerId == owner, ct) || !await db.Exercises.AnyAsync(x => x.Id == r.ExerciseId && (x.OwnerId == null || x.OwnerId == owner), ct)) return Results.NotFound(); var x = new WorkoutExercise { Id = r.Id ?? Guid.NewGuid(), WorkoutId = id, ExerciseId = r.ExerciseId, Order = r.Order, Notes = r.Notes, RestSeconds = r.RestSeconds, WeightMultiplier = r.WeightMultiplier }; db.Add(x); await db.SaveChangesAsync(ct); return Results.Created($"/api/v1/workouts/{id}", x); });
workouts.MapPut("/{workoutId:guid}/exercises/{workoutExerciseId:guid}", async (Guid workoutId, Guid workoutExerciseId, WorkoutExerciseWrite r, HttpContext h, AppDbContext db, CancellationToken ct) => { if (r.WeightMultiplier is not (1 or 2)) return Results.BadRequest(new { error = "weightMultiplier must be 1 or 2" }); var owner = UserId(h); var x = await db.WorkoutExercises.Include(x => x.Workout).SingleOrDefaultAsync(x => x.Id == workoutExerciseId && x.WorkoutId == workoutId && x.Workout!.OwnerId == owner, ct); if (x is null || !await db.Exercises.AnyAsync(e => e.Id == r.ExerciseId && (e.OwnerId == null || e.OwnerId == owner), ct)) return Results.NotFound(); x.ExerciseId = r.ExerciseId; x.Order = r.Order; x.Notes = r.Notes; x.RestSeconds = r.RestSeconds; x.WeightMultiplier = r.WeightMultiplier; await db.SaveChangesAsync(ct); return Results.Ok(x); });
workouts.MapPost("/{workoutId:guid}/exercises/{workoutExerciseId:guid}/sets", async (Guid workoutId, Guid workoutExerciseId, SetWrite r, HttpContext h, AppDbContext db, CancellationToken ct) => { var owner = UserId(h); var parent = await db.WorkoutExercises.SingleOrDefaultAsync(x => x.Id == workoutExerciseId && x.WorkoutId == workoutId && x.Workout!.OwnerId == owner, ct); if (parent is null) return Results.NotFound(); var x = NewSet(workoutExerciseId, r); db.Add(x); await db.SaveChangesAsync(ct); return Results.Created($"/api/v1/workouts/{workoutId}", x); }).Produces<SetEntry>(201).Produces(404).Produces(401);
workouts.MapPut("/{workoutId:guid}/sets/{setId:guid}", async (Guid workoutId, Guid setId, SetWrite r, HttpContext h, AppDbContext db, CancellationToken ct) => await UpdateSet(workoutId, setId, r, null, UserId(h), db, ct));
workouts.MapPost("/{workoutId:guid}/sets/{setId:guid}/complete", async (Guid workoutId, Guid setId, SetWrite r, HttpContext h, AppDbContext db, CancellationToken ct) => await UpdateSet(workoutId, setId, r, SetStatus.Completed, UserId(h), db, ct));
workouts.MapPost("/{workoutId:guid}/sets/{setId:guid}/skip", async (Guid workoutId, Guid setId, HttpContext h, AppDbContext db, CancellationToken ct) => await UpdateSet(workoutId, setId, null, SetStatus.Skipped, UserId(h), db, ct));
workouts.MapDelete("/{workoutId:guid}/sets/{setId:guid}", async (Guid workoutId, Guid setId, HttpContext h, AppDbContext db, CancellationToken ct) => { var owner = UserId(h); var x = await db.SetEntries.SingleOrDefaultAsync(x => x.Id == setId && x.WorkoutExercise!.WorkoutId == workoutId && x.WorkoutExercise.Workout!.OwnerId == owner, ct); if (x is null) return Results.NotFound(); if (x.Status == SetStatus.Completed) return Results.Conflict(new { error = "Completed sets cannot be deleted" }); db.Remove(x); await db.SaveChangesAsync(ct); return Results.NoContent(); });
workouts.MapPost("/sync", SyncWorkouts).Produces<IReadOnlyList<SyncResult>>().Produces<IReadOnlyList<SyncResult>>(409).Produces(400).Produces(401);

var templates = api.MapGroup("/templates").RequireAuthorization();
templates.MapGet("/", async (HttpContext h, AppDbContext db, CancellationToken ct) => { var owner = UserId(h); return await db.WorkoutTemplates.Include(x => x.Exercises).ThenInclude(x => x.Sets).Where(x => x.OwnerId == owner && !x.IsArchived).AsNoTracking().ToListAsync(ct); }).Produces<IReadOnlyList<WorkoutTemplate>>().Produces(401);
templates.MapPost("/", async (TemplateWrite r, HttpContext h, AppDbContext db, CancellationToken ct) => { var owner = UserId(h); if (r.Exercises.Any(e => e.WeightMultiplier is not (1 or 2))) return Results.BadRequest(new { error = "weightMultiplier must be 1 or 2" }); if (r.Exercises.Any(e => !db.Exercises.Any(x => x.Id == e.ExerciseId && (x.OwnerId == null || x.OwnerId == owner)))) return Results.BadRequest(new { error = "Template contains an unavailable exercise" }); var t = new WorkoutTemplate { Id = r.Id ?? Guid.NewGuid(), OwnerId = owner, Name = r.Name, Exercises = r.Exercises.Select(e => new TemplateExercise { Id = e.Id ?? Guid.NewGuid(), ExerciseId = e.ExerciseId, Order = e.Order, RestSeconds = e.RestSeconds, WeightMultiplier = e.WeightMultiplier, Sets = e.Sets.Select(s => new TemplateSet { Id = s.Id ?? Guid.NewGuid(), Order = s.Order, WeightKg = s.WeightKg, Reps = s.Reps, Rpe = s.Rpe, IsWarmup = s.IsWarmup }).ToList() }).ToList() }; db.Add(t); await db.SaveChangesAsync(ct); return Results.Created($"/api/v1/templates/{t.Id}", t); });
templates.MapPost("/{id:guid}/workouts", async (Guid id, TemplateWorkoutRequest r, HttpContext h, AppDbContext db, CancellationToken ct) => { var owner = UserId(h); var t = await db.WorkoutTemplates.Include(x => x.Exercises).ThenInclude(x => x.Sets).SingleOrDefaultAsync(x => x.Id == id && x.OwnerId == owner, ct); if (t is null) return Results.NotFound(); var w = new Workout { Id = r.Id ?? Guid.NewGuid(), OwnerId = owner, Name = r.Name ?? t.Name, ScheduledAt = r.ScheduledAt, Exercises = t.Exercises.Select(e => new WorkoutExercise { Id = Guid.NewGuid(), ExerciseId = e.ExerciseId, Order = e.Order, RestSeconds = e.RestSeconds, WeightMultiplier = e.WeightMultiplier, Sets = e.Sets.Select(s => new SetEntry { Id = Guid.NewGuid(), Order = s.Order, PlannedWeightKg = s.WeightKg, PlannedReps = s.Reps, PlannedRpe = s.Rpe, IsWarmup = s.IsWarmup }).ToList() }).ToList() }; db.Add(w); await db.SaveChangesAsync(ct); return Results.Created($"/api/v1/workouts/{w.Id}", w); });

api.MapGet("/statistics/volume", async (DateTimeOffset from, DateTimeOffset to, Guid? exerciseId, bool? includeWarmups, HttpContext h, AppDbContext db, CancellationToken ct) => { if (from >= to || to > from.AddYears(5)) return Results.BadRequest(new { error = "from and to must define a valid range of at most five years" }); var owner = UserId(h); var q = db.SetEntries.Where(s => s.WorkoutExercise!.Workout!.OwnerId == owner && s.Status == SetStatus.Completed && s.CompletedAt >= from && s.CompletedAt < to && s.ActualWeightKg != null && s.ActualReps != null && (includeWarmups != false || !s.IsWarmup) && (!exerciseId.HasValue || s.WorkoutExercise.ExerciseId == exerciseId)); var byExercise = await q.GroupBy(s => new { s.WorkoutExercise!.ExerciseId, s.WorkoutExercise.Exercise!.Name }).Select(g => new ExerciseVolume(g.Key.ExerciseId, g.Key.Name, g.Sum(s => s.ActualWeightKg!.Value * s.ActualReps!.Value * s.WorkoutExercise!.WeightMultiplier), g.Count(), g.Sum(s => s.ActualReps!.Value))).ToListAsync(ct); var dayRows = await q.GroupBy(s => new { s.CompletedAt!.Value.Year, s.CompletedAt.Value.Month, s.CompletedAt.Value.Day }).Select(g => new { g.Key.Year, g.Key.Month, g.Key.Day, Volume = g.Sum(s => s.ActualWeightKg!.Value * s.ActualReps!.Value * s.WorkoutExercise!.WeightMultiplier) }).OrderBy(x => x.Year).ThenBy(x => x.Month).ThenBy(x => x.Day).ToListAsync(ct); var byDay = dayRows.Select(x => new DayVolume(new DateTimeOffset(x.Year, x.Month, x.Day, 0, 0, 0, TimeSpan.Zero), x.Volume)).ToList(); return Results.Ok(new VolumeStatistics(from, to, byExercise.Sum(x => x.TotalVolumeKg), byExercise, byDay)); }).Produces<VolumeStatistics>().Produces(400).Produces(401).RequireAuthorization();

api.MapPost("/health/samples/import", async (IReadOnlyList<HealthSampleWrite> batch, HttpContext h, AppDbContext db, CancellationToken ct) => { var owner = UserId(h); if (batch.Count is < 1 or > 500) return Results.BadRequest(new { error = "Batch size must be 1..500" }); var allowed = new HashSet<string>(["bodyWeight", "stepCount", "activeEnergy", "basalEnergy", "heartRate", "restingHeartRate", "sleep", "workout"]); if (batch.Any(x => !allowed.Contains(x.Type) || x.EndAt < x.StartAt || string.IsNullOrWhiteSpace(x.ExternalId))) return Results.BadRequest(new { error = "Invalid health sample" }); var externalIds = batch.Select(x => x.ExternalId).Distinct().ToList(); var existingRows = await db.HealthSamples.Where(x => x.OwnerId == owner && externalIds.Contains(x.ExternalId)).Select(x => new { x.Type, x.SourceBundleId, x.ExternalId }).ToListAsync(ct); var existing = existingRows.Select(x => (x.Type, x.SourceBundleId, x.ExternalId)).ToHashSet(); var unique = batch.DistinctBy(x => (x.Type, x.SourceBundleId, x.ExternalId)).ToList(); var added = unique.Where(x => !existing.Contains((x.Type, x.SourceBundleId, x.ExternalId))).Select(x => new HealthSample { Id = x.Id ?? Guid.NewGuid(), OwnerId = owner, Type = x.Type, StartAt = x.StartAt, EndAt = x.EndAt, NumericValue = x.NumericValue, Unit = x.Unit, SourceName = x.SourceName, SourceBundleId = x.SourceBundleId, ExternalId = x.ExternalId, MetadataJson = x.MetadataJson }).ToList(); db.AddRange(added); await db.SaveChangesAsync(ct); return Results.Ok(new HealthImportResponse(added.Count, batch.Count - added.Count)); }).Produces<HealthImportResponse>().Produces(400).Produces(401).RequireAuthorization();
api.MapGet("/health/daily", async (string type, DateTimeOffset from, DateTimeOffset to, HttpContext h, AppDbContext db, CancellationToken ct) => { var owner = UserId(h); var samples = await db.HealthSamples.Where(x => x.OwnerId == owner && x.Type == type && x.StartAt >= from && x.StartAt < to).Select(x => new { x.StartAt, x.NumericValue }).AsNoTracking().ToListAsync(ct); return samples.GroupBy(x => x.StartAt.UtcDateTime.Date).Select(g => new DailyHealthResponse(g.Key, g.Sum(x => x.NumericValue))).OrderBy(x => x.Date).ToList(); }).Produces<IReadOnlyList<DailyHealthResponse>>().Produces(401).RequireAuthorization();
api.MapPost("/integrations/home-assistant/body-measurements", async (BodyMeasurementWrite r, AppDbContext db, HttpContext h, CancellationToken ct) => { var expected = Environment.GetEnvironmentVariable("TRAINING_HOME_ASSISTANT_API_KEY"); if (string.IsNullOrWhiteSpace(expected) || !CryptographicOperations.FixedTimeEquals(Encoding.UTF8.GetBytes(h.Request.Headers["X-Api-Key"].ToString()), Encoding.UTF8.GetBytes(expected))) return Results.Unauthorized(); var ownerName = Environment.GetEnvironmentVariable("TRAINING_HOME_ASSISTANT_USERNAME") ?? Environment.GetEnvironmentVariable("TRAINING_ADMIN_USERNAME") ?? "taras"; var owner = await db.Users.SingleOrDefaultAsync(x => x.UserName == ownerName && x.IsActive, ct); if (owner is null || r.WeightKg is <= 0 or > 500 || r.BodyFatPercent is < 0 or > 100 || string.IsNullOrWhiteSpace(r.ExternalId)) return Results.BadRequest(new { status = "rejected" }); if (await db.BodyMeasurements.AnyAsync(x => x.OwnerId == owner.Id && x.Source == r.Source && x.ExternalId == r.ExternalId, ct)) return Results.Ok(new { status = "alreadyExists" }); db.Add(new BodyMeasurement { OwnerId = owner.Id, ExternalId = r.ExternalId, MeasuredAt = r.MeasuredAt, WeightKg = r.WeightKg, BodyFatPercent = r.BodyFatPercent, MuscleMassKg = r.MuscleMassKg, Impedance = r.Impedance, Source = r.Source, RawPayload = r.RawPayload }); await db.SaveChangesAsync(ct); return Results.Created("", new { status = "created" }); }).AllowAnonymous();
api.MapGet("/export", async (HttpContext h, AppDbContext db, CancellationToken ct) =>
{
    var owner = UserId(h);
    var profile = await db.Users.AsNoTracking().Where(x => x.Id == owner).Select(x => new { x.Id, x.UserName, x.IsAdmin, x.CreatedAt }).SingleAsync(ct);
    var exercises = await db.Exercises.AsNoTracking().Where(x => x.OwnerId == null || x.OwnerId == owner).ToListAsync(ct);
    var workouts = await db.Workouts.AsNoTracking().Where(x => x.OwnerId == owner).Include(x => x.Exercises).ThenInclude(x => x.Exercise).Include(x => x.Exercises).ThenInclude(x => x.Sets).OrderBy(x => x.ScheduledAt).ToListAsync(ct);
    var templates = await db.WorkoutTemplates.AsNoTracking().Where(x => x.OwnerId == owner).Include(x => x.Exercises).ThenInclude(x => x.Exercise).Include(x => x.Exercises).ThenInclude(x => x.Sets).ToListAsync(ct);
    var healthSamples = await db.HealthSamples.AsNoTracking().Where(x => x.OwnerId == owner).OrderBy(x => x.StartAt).ToListAsync(ct);
    var bodyMeasurements = await db.BodyMeasurements.AsNoTracking().Where(x => x.OwnerId == owner).OrderBy(x => x.MeasuredAt).ToListAsync(ct);
    return Results.Ok(new { exportedAt = DateTimeOffset.UtcNow, profile, exercises, workouts, templates, healthSamples, bodyMeasurements });
}).RequireAuthorization();
api.MapGet("/bootstrap", async (HttpContext h, AppDbContext db, CancellationToken ct) => { var owner = UserId(h); var now = DateTimeOffset.UtcNow; var workout = await db.Workouts.Include(x => x.Exercises).ThenInclude(x => x.Exercise).Include(x => x.Exercises).ThenInclude(x => x.Sets).Where(x => x.OwnerId == owner && (x.Status == WorkoutStatus.InProgress || (x.Status == WorkoutStatus.Planned && x.ScheduledAt >= now.AddDays(-1)))).OrderBy(x => x.Status == WorkoutStatus.InProgress ? 0 : 1).ThenBy(x => x.ScheduledAt).AsNoTracking().FirstOrDefaultAsync(ct); var lastSync = await db.HealthSamples.Where(x => x.OwnerId == owner).MaxAsync(x => (DateTimeOffset?)x.ImportedAt, ct); return new BootstrapResponse(workout, await db.Exercises.Where(x => (x.OwnerId == null || x.OwnerId == owner) && !x.IsArchived).AsNoTracking().ToListAsync(ct), lastSync); }).Produces<BootstrapResponse>().Produces(401).RequireAuthorization();

await using (var scope = app.Services.CreateAsyncScope()) { var db = scope.ServiceProvider.GetRequiredService<AppDbContext>(); if (Environment.GetEnvironmentVariable("TRAINING_AUTO_MIGRATE") == "true") await db.Database.MigrateAsync(); await SeedUser(db); }
app.Run();

static void Touch(Workout x) { x.Version++; x.UpdatedAt = DateTimeOffset.UtcNow; }
static string? PlainText(string? html) => string.IsNullOrWhiteSpace(html) ? null : WebUtility.HtmlDecode(Regex.Replace(html, "<[^>]+>", " ")).Replace("  ", " ").Trim();
static bool GymEquipment(string equipment) => new[] { "barbell", "dumbbell", "machine", "cable", "kettlebell", "bench", "rack", "ez curl" }.Any(x => equipment.Contains(x, StringComparison.OrdinalIgnoreCase));
static int EquipmentPriority(string equipment) => new[] { "barbell", "dumbbell", "machine", "cable", "kettlebell" }.Select((x, i) => equipment.Contains(x, StringComparison.OrdinalIgnoreCase) ? 10 - i : 0).Max();
static SetEntry NewSet(Guid parent, SetWrite r) => new() { Id = r.Id ?? Guid.NewGuid(), WorkoutExerciseId = parent, Order = r.Order, Status = r.Status ?? SetStatus.Planned, PlannedWeightKg = r.PlannedWeightKg, PlannedReps = r.PlannedReps, PlannedRpe = r.PlannedRpe, ActualWeightKg = r.ActualWeightKg, ActualReps = r.ActualReps, ActualRpe = r.ActualRpe, IsWarmup = r.IsWarmup, Notes = r.Notes, CompletedAt = SyncSetRules.CompletionTime(r.Status ?? SetStatus.Planned, r.CompletedAt, DateTimeOffset.UtcNow) };
static async Task<IResult> UpdateWorkout(Guid id, WorkoutWrite r, HttpRequest request, HttpContext h, AppDbContext db, CancellationToken ct) { var owner = UserId(h); var x = await db.Workouts.SingleOrDefaultAsync(x => x.Id == id && x.OwnerId == owner, ct); if (x is null) return Results.NotFound(); var expected = ParseVersion(request, r.Version); if (expected != x.Version) return Results.Conflict(new { error = "Version conflict", current = x }); x.Name = r.Name; x.ScheduledAt = r.ScheduledAt; x.Notes = r.Notes; Touch(x); await db.SaveChangesAsync(ct); return Results.Ok(x); }
static async Task<IResult> UpdateSet(Guid workoutId, Guid setId, SetWrite? r, SetStatus? status, Guid owner, AppDbContext db, CancellationToken ct) { var x = await db.SetEntries.Include(x => x.WorkoutExercise).ThenInclude(x => x!.Workout).SingleOrDefaultAsync(x => x.Id == setId && x.WorkoutExercise!.WorkoutId == workoutId && x.WorkoutExercise.Workout!.OwnerId == owner, ct); if (x is null) return Results.NotFound(); if (r?.Version is long expected && expected != x.Version) return Results.Conflict(new { error = "Version conflict", current = x }); if (r?.CompletedAt is { } completedAt && !SyncSetRules.ValidClientTime(completedAt, DateTimeOffset.UtcNow)) return Results.BadRequest(new { error = "completedAt must be UTC and within the last ten years" }); if (r != null) { x.Order = r.Order; x.PlannedWeightKg = r.PlannedWeightKg; x.PlannedReps = r.PlannedReps; x.PlannedRpe = r.PlannedRpe; x.ActualWeightKg = r.ActualWeightKg; x.ActualReps = r.ActualReps; x.ActualRpe = r.ActualRpe; x.IsWarmup = r.IsWarmup; x.Notes = r.Notes; } if (status.HasValue) { x.Status = status.Value; x.CompletedAt = SyncSetRules.CompletionTime(status.Value, r?.CompletedAt, DateTimeOffset.UtcNow); } x.Version++; x.UpdatedAt = DateTimeOffset.UtcNow; await db.SaveChangesAsync(ct); return Results.Ok(x); }
static long ParseVersion(HttpRequest request, long? body) => request.Headers.IfMatch.FirstOrDefault()?.Trim('"') is { } value && long.TryParse(value, out var parsed) ? parsed : body ?? -1;
static async Task<IResult> SyncWorkouts(IReadOnlyList<SetSyncCommand> commands, HttpContext h, AppDbContext db, CancellationToken ct) { var owner = UserId(h); if (commands.Count is < 1 or > 100) return Results.BadRequest(new { error = "Batch size must be 1..100" }); var now = DateTimeOffset.UtcNow; if (commands.Any(c => c.Value.CompletedAt is { } time && !SyncSetRules.ValidClientTime(time, now))) return Results.BadRequest(new { error = "completedAt must be UTC and within the last ten years" }); var results = new List<SyncResult>(); foreach (var c in commands) { if (!await db.WorkoutExercises.AnyAsync(x => x.Id == c.WorkoutExerciseId && x.Workout!.OwnerId == owner, ct)) { results.Add(new SyncResult(c.Id, "rejected")); continue; } var current = await db.SetEntries.Include(x => x.WorkoutExercise).ThenInclude(x => x!.Workout).SingleOrDefaultAsync(x => x.Id == c.Id && x.WorkoutExercise!.Workout!.OwnerId == owner, ct); if (current is null) { var created = NewSet(c.WorkoutExerciseId, c.Value with { Id = c.Id }); db.Add(created); results.Add(new SyncResult(created.Id, "created", created.Version)); continue; } if (c.ExpectedVersion == 0 && SyncSetRules.SameSet(current, c.Value)) { results.Add(new SyncResult(current.Id, "existing", current.Version)); continue; } if (current.Version != c.ExpectedVersion) { results.Add(new SyncResult(current.Id, "conflict", current.Version, current)); continue; } current.ActualWeightKg = c.Value.ActualWeightKg; current.ActualReps = c.Value.ActualReps; current.ActualRpe = c.Value.ActualRpe; current.Status = c.Value.Status ?? current.Status; current.CompletedAt = SyncSetRules.CompletionTime(current.Status, c.Value.CompletedAt, now); current.Version++; current.UpdatedAt = now; results.Add(new SyncResult(current.Id, "updated", current.Version)); } await db.SaveChangesAsync(ct); return results.Any(x => x.Status == "conflict") ? Results.Conflict(results) : Results.Ok(results); }
static async Task SeedUser(AppDbContext db) { if (await db.Users.AnyAsync()) return; var name = Environment.GetEnvironmentVariable("TRAINING_ADMIN_USERNAME") ?? "taras"; var password = Environment.GetEnvironmentVariable("TRAINING_ADMIN_PASSWORD") ?? throw new InvalidOperationException("TRAINING_ADMIN_PASSWORD is required for first start"); var user = new LocalUser { UserName = name, PasswordHash = "pending", IsAdmin = true }; user.PasswordHash = new PasswordHasher<LocalUser>().HashPassword(user, password); db.Add(user); await db.SaveChangesAsync(); }
static Guid UserId(HttpContext h) => Guid.TryParse(h.User.FindFirstValue(ClaimTypes.NameIdentifier) ?? h.User.FindFirstValue(JwtRegisteredClaimNames.Sub), out var id) ? id : throw new UnauthorizedAccessException("User identifier is missing");
static Claim[] UserClaims(LocalUser user) => [new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()), new Claim(ClaimTypes.Name, user.UserName), new Claim("is_admin", user.IsAdmin ? "true" : "false")];
static AuthenticationProperties PersistentCookie() => new() { IsPersistent = true, AllowRefresh = true };

public record LoginRequest(string UserName, string Password); public record RefreshRequest(string RefreshToken);
public sealed record TokenResponse(string AccessToken, DateTimeOffset ExpiresAt, string RefreshToken, DateTimeOffset RefreshExpiresAt, TokenUserResponse User);
public sealed record TokenUserResponse(Guid Id, string UserName, bool IsAdmin);
public sealed record BootstrapResponse(Workout? Workout, IReadOnlyList<Exercise> Exercises, DateTimeOffset? LastHealthSyncAt);
public record CreateUserRequest(string UserName, string Password, bool IsAdmin = false); public record UpdateUserRequest(bool IsActive, bool IsAdmin, string? Password); public record ChangePasswordRequest(string CurrentPassword, string NewPassword); public record UserPreferencesRequest(string ColorTheme); public record UserResponse(Guid Id, string UserName, bool IsAdmin, bool IsActive, string ColorTheme, DateTimeOffset CreatedAt) { public static UserResponse From(LocalUser x) => new(x.Id, x.UserName, x.IsAdmin, x.IsActive, x.ColorTheme, x.CreatedAt); }
public record ExerciseWrite(Guid? Id, string Name, string? Description, string MuscleGroup, string Equipment, bool IsArchived = false, string? ImageUrl = null, string? SourceUrl = null, string? LicenseName = null, string? LicenseUrl = null, string? SourceAuthor = null);
public record WorkoutWrite(Guid? Id, string Name, DateTimeOffset ScheduledAt, string? Notes, long? Version);
public record WorkoutExerciseWrite(Guid? Id, Guid ExerciseId, int Order, string? Notes, int RestSeconds = 90, int WeightMultiplier = 1);
public record SetWrite(Guid? Id, int Order, decimal? PlannedWeightKg, int? PlannedReps, decimal? PlannedRpe, decimal? ActualWeightKg, int? ActualReps, decimal? ActualRpe, bool IsWarmup, string? Notes, long? Version, SetStatus? Status = null, DateTimeOffset? CompletedAt = null);
public record SetSyncCommand(Guid Id, Guid WorkoutExerciseId, long ExpectedVersion, SetWrite Value);
public record TemplateWrite(Guid? Id, string Name, IReadOnlyList<TemplateExerciseWrite> Exercises); public record TemplateExerciseWrite(Guid? Id, Guid ExerciseId, int Order, int RestSeconds, IReadOnlyList<TemplateSetWrite> Sets, int WeightMultiplier = 1); public record TemplateSetWrite(Guid? Id, int Order, decimal? WeightKg, int? Reps, decimal? Rpe, bool IsWarmup); public record TemplateWorkoutRequest(Guid? Id, string? Name, DateTimeOffset ScheduledAt);
public sealed record CalendarWorkout(Guid Id, string Name, DateTimeOffset ScheduledAt, DateTimeOffset? StartedAt, DateTimeOffset? CompletedAt, WorkoutStatus Status, long Version, decimal TotalVolumeKg);
public sealed record VolumeStatistics(DateTimeOffset From, DateTimeOffset To, decimal TotalVolumeKg, IReadOnlyList<ExerciseVolume> ByExercise, IReadOnlyList<DayVolume> ByDay);
public sealed record ExerciseVolume(Guid ExerciseId, string ExerciseName, decimal TotalVolumeKg, int CompletedSets, int TotalReps);
public sealed record DayVolume(DateTimeOffset Date, decimal TotalVolumeKg);
public record HealthSampleWrite(Guid? Id, string Type, DateTimeOffset StartAt, DateTimeOffset EndAt, decimal? NumericValue, string? Unit, string? SourceName, string? SourceBundleId, string ExternalId, string? MetadataJson);
public sealed record HealthImportResponse(int Created, int AlreadyExists);
public sealed record DailyHealthResponse(DateTime Date, decimal? Value);
public sealed record SyncResult(Guid Id, string Status, long? Version = null, SetEntry? Current = null);
public record BodyMeasurementWrite(string ExternalId, DateTimeOffset MeasuredAt, decimal WeightKg, decimal? BodyFatPercent, decimal? MuscleMassKg, decimal? Impedance, string Source, string RawPayload);

public sealed record LibraryExercise(Guid Id, string Name, string? Description, string MuscleGroup, string Equipment, string? ImageUrl, string SourceUrl, string LicenseName, string LicenseUrl, string? SourceAuthor);
public sealed record WgerPage(int Count, List<WgerExercise> Results);
public sealed record WgerExercise(int Id, Guid Uuid, WgerNamed Category, List<WgerNamed> Equipment, WgerLicense License, [property: JsonPropertyName("license_author")] string? LicenseAuthor, List<WgerImage> Images, List<WgerTranslation> Translations);
public sealed record WgerNamed(int Id, string Name);
public sealed record WgerLicense([property: JsonPropertyName("short_name")] string ShortName, string Url);
public sealed record WgerImage(string Image, [property: JsonPropertyName("is_main")] bool IsMain);
public sealed record WgerTranslation(string Name, string? Description, int Language, [property: JsonPropertyName("license_author")] string? LicenseAuthor);

public static class TokenFactory
{
    public sealed record Issued(Guid TokenId, TokenResponse Response);
    public static TokenValidationParameters Validation(string key) => new() { ValidateIssuer = true, ValidIssuer = "training-api", ValidateAudience = true, ValidAudience = "training-ios", ValidateLifetime = true, ValidateIssuerSigningKey = true, IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key)), ClockSkew = TimeSpan.FromSeconds(30) };
    public static async Task<Issued> IssueAsync(AppDbContext db, LocalUser user, string key, CancellationToken ct) { var now = DateTimeOffset.UtcNow; var handler = new JwtSecurityTokenHandler(); var jwt = handler.CreateEncodedJwt(new SecurityTokenDescriptor { Subject = new ClaimsIdentity([new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()), new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()), new Claim(JwtRegisteredClaimNames.UniqueName, user.UserName), new Claim("is_admin", user.IsAdmin ? "true" : "false")]), Issuer = "training-api", Audience = "training-ios", NotBefore = now.UtcDateTime, Expires = now.AddMinutes(15).UtcDateTime, SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key)), SecurityAlgorithms.HmacSha256) }); var raw = Convert.ToBase64String(RandomNumberGenerator.GetBytes(48)); var token = new RefreshToken { UserId = user.Id, TokenHash = Hash(raw), ExpiresAt = now.AddDays(30) }; db.Add(token); await db.SaveChangesAsync(ct); return new Issued(token.Id, new TokenResponse(jwt, now.AddMinutes(15), raw, token.ExpiresAt, new TokenUserResponse(user.Id, user.UserName, user.IsAdmin))); }
    public static string Hash(string token) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(token)));
}

public partial class Program { }

public sealed class AllowAnonymousOperationFilter : IOperationFilter
{
    public void Apply(OpenApiOperation operation, OperationFilterContext context)
    {
        if (context.ApiDescription.ActionDescriptor.EndpointMetadata.OfType<IAllowAnonymous>().Any()) operation.Security = [];
    }
}

public sealed class StringEnumSchemaFilter : ISchemaFilter
{
    public void Apply(IOpenApiSchema schema, SchemaFilterContext context)
    {
        if (!context.Type.IsEnum || schema is not OpenApiSchema concrete) return;
        concrete.Type = JsonSchemaType.String;
        concrete.Format = null;
        concrete.Enum = Enum.GetNames(context.Type).Select(x => (JsonNode)JsonValue.Create(x)!).ToList();
    }
}

public static class SyncSetRules
{
    public static bool ValidClientTime(DateTimeOffset value, DateTimeOffset now) => value.Offset == TimeSpan.Zero && value >= now.AddYears(-10) && value <= now.AddMinutes(5);
    public static DateTimeOffset? CompletionTime(SetStatus status, DateTimeOffset? requested, DateTimeOffset now) => status == SetStatus.Completed ? requested ?? now : null;
    public static bool SameSet(SetEntry x, SetWrite r) => x.Order == r.Order && x.PlannedWeightKg == r.PlannedWeightKg && x.PlannedReps == r.PlannedReps && x.PlannedRpe == r.PlannedRpe && x.ActualWeightKg == r.ActualWeightKg && x.ActualReps == r.ActualReps && x.ActualRpe == r.ActualRpe && x.IsWarmup == r.IsWarmup && x.Notes == r.Notes && x.Status == (r.Status ?? SetStatus.Planned) && (!r.CompletedAt.HasValue || x.CompletedAt == r.CompletedAt);
}
