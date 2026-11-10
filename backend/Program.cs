using System.Net;
using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using Tourism;

var builder = WebApplication.CreateBuilder(args);
var root = Path.GetFullPath(builder.Configuration["GameRoot"] ?? "..");
var web = Path.Combine(root, "exports", "web-v03");
var webFiles = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(web);
builder.Services.AddDbContext<TourismDb>(options => options.UseNpgsql(
    builder.Configuration.GetConnectionString("Tourism") ?? throw new InvalidOperationException("Set ConnectionStrings__Tourism.")));
builder.Services.AddSingleton(new MapRules(Path.Combine(root, "data", "world.json"), Path.Combine(root, "data", "buildings.json")));
builder.Services.AddScoped<Business>();
builder.Services.AddHostedService<MarketWorker>();
var app = builder.Build();
await using (var scope = app.Services.CreateAsyncScope())
    await scope.ServiceProvider.GetRequiredService<Business>().Initialize();

var token = Convert.ToHexString(RandomNumberGenerator.GetBytes(32));
var mobileCode = builder.Configuration["MobileAccessCode"];
app.UseDefaultFiles(new DefaultFilesOptions { FileProvider = webFiles });
var contentTypes = new Microsoft.AspNetCore.StaticFiles.FileExtensionContentTypeProvider();
contentTypes.Mappings[".pck"] = "application/octet-stream";
contentTypes.Mappings[".webmanifest"] = "application/manifest+json";
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = webFiles,
    ContentTypeProvider = contentTypes,
    OnPrepareResponse = response => response.Context.Response.Headers.CacheControl = "no-cache"
});
var api = app.MapGroup("/api");
api.MapGet("/session", (HttpContext context) =>
    IsLocal(context) || MobileSessionAllowed(context) ? Results.Ok(new { token }) : Results.StatusCode(403));
api.MapGet("/state", async (HttpContext context, TourismDb db) =>
{
    if (!Authenticated(context)) return Results.Unauthorized();
    await using var transaction = await db.Database.BeginTransactionAsync(System.Data.IsolationLevel.RepeatableRead);
    var company = await db.Companies.SingleAsync(x => x.Owner == "local-player");
    var ledger = db.Ledger.Where(x => x.CompanyId == company.Id);
    var amounts = await ledger.GroupBy(_ => 0).Select(g => new {
        Revenue = g.Where(x => x.Kind == "Doanh thu dịch vụ").Sum(x => x.Amount),
        Expenses = -g.Where(x => x.Amount < 0 && x.Kind != "Đặt cọc").Sum(x => x.Amount)
    }).SingleOrDefaultAsync();
    var facilities = await db.Facilities.OrderBy(x => x.Id).ToListAsync();
    var sectors = facilities.GroupBy(f => f.Kind).Select(g => new {
        Kind = g.Key, Capacity = g.Where(f => f.Open).Sum(f => f.Staff * f.Level * (f.Kind == "homestay" ? 2 : 4)),
        AveragePrice = Math.Round(g.Average(f => f.Price), 1)
    });
    return Results.Ok(new {
        company, amounts, sectors, period = Business.PeriodNow, rentPeriod = Business.RentPeriod, term = Business.Term,
        assets = await db.Assets.OrderBy(x => x.Id).ToListAsync(),
        facilities,
        leases = await db.Leases.Where(x => x.CompanyId == company.Id).OrderByDescending(x => x.Start).ToListAsync(),
        market = await db.Markets.SingleAsync(),
        ledger = await ledger.OrderByDescending(x => x.Period).ThenByDescending(x => x.Id).Take(12).ToListAsync()
    });
});
api.MapPost("/actions", async (HttpContext context, ActionRequest command, Business business) =>
{
    if (!Authenticated(context)) return Results.Unauthorized();
    try
    {
        await business.Apply("local-player", command);
        return Results.Ok(new { accepted = true });
    }
    catch (RuleException error)
    {
        return Results.Conflict(new { message = error.Message });
    }
});
await app.RunAsync();

bool Authenticated(HttpContext context) =>
    (IsLocal(context) || (context.Request.IsHttps && !string.IsNullOrWhiteSpace(mobileCode))) &&
    context.Request.Headers.Authorization == $"Bearer {token}";
bool MobileSessionAllowed(HttpContext context) =>
    context.Request.IsHttps && !string.IsNullOrWhiteSpace(mobileCode) &&
    CryptographicOperations.FixedTimeEquals(
        System.Text.Encoding.UTF8.GetBytes(context.Request.Headers["X-Mobile-Code"].ToString()),
        System.Text.Encoding.UTF8.GetBytes(mobileCode));
static bool IsLocal(HttpContext context) =>
    context.Connection.RemoteIpAddress is { } address && IPAddress.IsLoopback(address) &&
    context.Request.Host.Host is "localhost" or "127.0.0.1" or "[::1]";

public sealed class MarketWorker(IServiceScopeFactory scopes, ILogger<MarketWorker> log) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(TimeSpan.FromSeconds(3));
        while (await timer.WaitForNextTickAsync(stoppingToken))
        {
            try
            {
                await using var scope = scopes.CreateAsyncScope();
                await scope.ServiceProvider.GetRequiredService<Business>().Advance();
            }
            catch (Exception error) when (!stoppingToken.IsCancellationRequested)
            {
                log.LogError(error, "Could not advance market");
            }
        }
    }
}

