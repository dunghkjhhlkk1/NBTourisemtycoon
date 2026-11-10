using System.Text.Json;
using Microsoft.EntityFrameworkCore;

namespace Tourism;

public sealed class Business(TourismDb db, MapRules map)
{
    public const int PeriodSeconds = 15;
    public const int RentPeriod = 8;
    public const int Term = 40;
    public const string CompanyId = "demo";
    public static long PeriodNow => DateTimeOffset.UtcNow.ToUnixTimeSeconds() / PeriodSeconds;

    public async Task Initialize()
    {
        await db.Database.MigrateAsync();
        await Execute(async () =>
        {
            if (await db.Companies.AnyAsync()) return;
            db.Companies.Add(new());
            db.Markets.Add(new() { Period = PeriodNow });
            db.Assets.AddRange(
                new Asset { Id="ticket", Name="Quầy vé Tràng An", Kind="public", Zone="Cổng vào", X=16,Y=21,Width=2,Height=2 },
                new Asset { Id="restaurant", Name="Nhà hàng Tràng An", Kind="property", Zone="Dịch vụ", X=23,Y=20,Width=4,Height=3,Rent=280,Deposit=500 },
                new Asset { Id="homestay", Name="Homestay Hoa Lư", Kind="property", Zone="Lưu trú", X=29,Y=20,Width=3,Height=3,Rent=320,Deposit=600 },
                new Asset { Id="souvenir", Name="Quầy đặc sản NPC", Kind="public", Zone="Dịch vụ", X=20,Y=20,Width=2,Height=2 },
                new Asset { Id="dock", Name="Bến thuyền Tràng An", Kind="property", Zone="Bến thuyền", X=31,Y=31,Width=2,Height=2,Rent=200,Deposit=300 },
                new Asset { Id="plot-a", Name="A1 · Khu thương mại", Kind="CommercialPlot", Zone="Dịch vụ", X=11,Y=20,Width=5,Height=4,Rent=130,Deposit=260,Allowed="restaurant,souvenir" },
                new Asset { Id="plot-b", Name="B1 · Khu lưu trú", Kind="AccommodationPlot", Zone="Lưu trú", X=32,Y=20,Width=5,Height=4,Rent=155,Deposit=310,Allowed="homestay" },
                new Asset { Id="npc-restaurant", Name="Nhà hàng Bến Đông · NPC", Kind="public", Zone="Dịch vụ", X=37,Y=21,Width=4,Height=3 },
                new Asset { Id="protected", Name="Bảo tồn ven sông", Kind="ProtectedPlot", Zone="Bảo tồn", X=27,Y=32,Width=14,Height=5 });
            foreach (var (kind,x,y,price) in new[] { ("ticket",16,21,45), ("restaurant",23,20,65), ("homestay",29,20,145), ("souvenir",20,20,35), ("dock",31,31,95) })
                db.Facilities.Add(new() { Id=kind, AssetId=kind, Kind=kind, X=x, Y=y, Price=price });
            db.Facilities.Add(new() { Id="npc-restaurant", AssetId="npc-restaurant", Kind="restaurant", X=37,Y=21,Price=75 });
        });
    }

    public async Task Execute(Func<Task> operation)
    {
        await using var transaction = await db.Database.BeginTransactionAsync();
        await db.Database.ExecuteSqlRawAsync("SELECT pg_advisory_xact_lock(3076603)");
        await operation();
        await db.SaveChangesAsync();
        await transaction.CommitAsync();
    }

    public async Task Apply(string player, ActionRequest request)
    {
        await Execute(async () =>
        {
            var company = await db.Companies.SingleAsync(x => x.Owner == player);
            var market = await db.Markets.SingleAsync();
            var now = Math.Max(market.Period, PeriodNow);
            var signature = JsonSerializer.Serialize(request);
            if (request.Key == Guid.Empty) throw new RuleException("Thiếu mã giao dịch.");
            var receipt = await db.Receipts.FindAsync(company.Id, request.Key);
            if (receipt is not null)
            {
                Require(receipt.Fingerprint == signature, "Mã giao dịch đã được dùng cho thao tác khác.");
                return;
            }
            var asset = await db.Assets.FindAsync(request.Target) ?? throw new RuleException("Không tìm thấy tài sản.");
            var lease = await db.Leases.SingleOrDefaultAsync(x => x.AssetId == asset.Id && x.Status == "Active");
            if (lease is not null && lease.End <= now)
            {
                await Close(company, lease, "Expired", now);
                await db.SaveChangesAsync();
                lease = null;
            }
            var facilities = await db.Facilities.Where(x => x.AssetId == asset.Id).ToListAsync();
            var key = request.Key.ToString();
            if (request.Action == "lease")
            {
                Require(asset.Rent > 0 && lease is null, "Tài sản đang được thuê hoặc bị hạn chế.");
                Require(facilities.All(x => x.Owner == "npc" || x.Owner == company.Id), "Tài sản có công trình của doanh nghiệp khác.");
                Record(company, asset.Id, key + "/deposit", "Đặt cọc", -asset.Deposit, now);
                Record(company, asset.Id, key + "/rent", "Thuê kỳ đầu", -asset.Rent, now);
                db.Leases.Add(new() { Id=Guid.NewGuid(), AssetId=asset.Id, CompanyId=company.Id, Landlord=asset.Owner,
                    Start=now, End=now+Term, PaidThrough=now+RentPeriod, Deposit=asset.Deposit, Rent=asset.Rent });
            }
            else
            {
                Require(lease?.CompanyId == company.Id, "Doanh nghiệp chưa có quyền khai thác.");
                switch (request.Action)
                {
                    case "pay":
                        Require(lease!.PaidThrough < lease.End, "Đã thanh toán hết thời hạn.");
                        Record(company, asset.Id, key, "Tiền thuê định kỳ", -lease.Rent, now);
                        lease.PaidThrough = Math.Min(lease.End, Math.Max(now, lease.PaidThrough) + RentPeriod);
                        break;
                    case "renew":
                        Require(lease!.End - now <= RentPeriod, "Có thể gia hạn trong kỳ cuối.");
                        Record(company, asset.Id, key, "Gia hạn", -lease.Rent, now);
                        if (lease.PaidThrough >= lease.End) lease.PaidThrough += RentPeriod;
                        else lease.PaidThrough = Math.Min(lease.End, Math.Max(now, lease.PaidThrough) + RentPeriod);
                        lease.End += Term;
                        break;
                    case "end":
                        Require(facilities.All(x => x.Owner == "npc"), "Lô có công trình đầu tư. Cần quy tắc chuyển nhượng để chấm dứt.");
                        await Close(company, lease!, "Ended", now);
                        break;
                    case "build":
                        Require(lease!.PaidThrough > now, "Cần thanh toán kỳ thuê trước khi xây.");
                        Require(request.Kind is not null && asset.Allowed.Split(',').Contains(request.Kind), "Loại công trình không được phép trên lô này.");
                        var kind = request.Kind!;
                        map.Validate(asset, kind, request.X, request.Y, await db.Facilities.ToListAsync());
                        Record(company, asset.Id, key, "Xây dựng", -900, now);
                        db.Facilities.Add(new() { Id=Guid.NewGuid().ToString(), AssetId=asset.Id, Kind=kind, X=request.X, Y=request.Y,
                            Owner=company.Id, Price=kind == "homestay" ? 145 : kind == "restaurant" ? 65 : 35 });
                        break;
                    case "price": case "staff": case "upgrade": case "open":
                        Require(lease!.PaidThrough > now, "Cần thanh toán kỳ thuê trước khi quản lý.");
                        var facility = facilities.SingleOrDefault(x => x.Id == request.Kind) ?? throw new RuleException("Không tìm thấy cơ sở.");
                        if (request.Action == "price") facility.Price = Math.Clamp(request.Value, 5, 500);
                        if (request.Action == "staff")
                        {
                            var staff = Math.Clamp(request.Value, 0, 3);
                            if (staff > facility.Staff) Record(company, asset.Id, key, "Tuyển dụng", -40*(staff-facility.Staff), now);
                            facility.Staff = staff;
                        }
                        if (request.Action == "upgrade")
                        {
                            Require(facility.Level < 3, "Đã đạt cấp tối đa.");
                            Record(company, asset.Id, key, "Nâng cấp", -450*facility.Level, now);
                            facility.Level++;
                        }
                        if (request.Action == "open") facility.Open = request.Value != 0;
                        break;
                    default: throw new RuleException("Thao tác không hợp lệ.");
                }
            }
            db.Receipts.Add(new() { CompanyId=company.Id, Key=request.Key, Fingerprint=signature });
        });
    }

    public async Task Advance()
    {
        await Execute(async () =>
        {
            var market = await db.Markets.SingleAsync();
            var now = PeriodNow;
            if (market.Period >= now) return;
            var company = await db.Companies.SingleAsync();
            var leases = await db.Leases.Where(x => x.Status == "Active").ToListAsync();
            foreach (var lease in leases.Where(x => x.End <= now)) await Close(company, lease, "Expired", now);
            var active = leases.Where(x => x.Status == "Active").ToDictionary(x => x.AssetId);
            var facilities = await db.Facilities.OrderBy(x => x.Id).ToListAsync();
            market.Period = now;
            market.Demand = 12 + (int)(now % 13);
            market.Served = market.NpcServed = 0;
            market.DockSeats = 0;
            market.DockFare = market.DockGross = 0;
            foreach (var group in facilities.Where(x => x.Open && x.Staff > 0).GroupBy(x => x.Kind))
            {
                var demand = group.Key == "homestay" ? market.Demand / 4 : group.Key == "ticket" ? market.Demand : market.Demand / 2;
                var candidates = group
                    .Where(f => active.TryGetValue(f.AssetId, out var contract) ? contract.PaidThrough > now : f.Owner == "npc")
                    .OrderByDescending(f => 65 + f.Level * 12 + f.Staff * 5 - f.Price * (f.Kind == "homestay" ? 0.25m : 0.55m)
                        - (Math.Abs(f.X - 11) + Math.Abs(f.Y - 24)) * 0.8m).ToArray();
                foreach (var f in candidates)
                {
                    var managed = active.ContainsKey(f.AssetId);
                    var wages = 9 * f.Staff;
                    if (managed && company.Balance < wages) continue;
                    var served = Math.Min(demand, f.Staff * f.Level * (f.Kind == "homestay" ? 2 : 4));
                    if (f.Id == "dock")
                    {
                        var capacity = Math.Min(3, f.Staff + f.Level);
                        served = Math.Min(served, Math.Clamp(6 - (int)(f.Price / 30), 0, capacity));
                        market.DockSeats = served;
                        market.DockFare = f.Price;
                        market.DockGross = served * f.Price;
                    }
                    demand -= served;
                    if (!managed) { market.NpcServed += served; continue; }
                    var prefix = $"period/{now}/{f.Id}";
                    Record(company, f.AssetId, prefix+"/wages", "Lương", -wages, now);
                    if (served == 0) continue;
                    market.Served += served;
                    Record(company, f.AssetId, prefix+"/sale", "Doanh thu dịch vụ", served*f.Price, now);
                    Record(company, f.AssetId, prefix+"/cost", "Chi phí vận hành", -served*Math.Min(18, f.Price), now);
                }
            }
        });
    }

    private async Task Close(Company company, Lease lease, string status, long period)
    {
        lease.Status = status;
        Record(company, lease.AssetId, $"close/{lease.Id}", "Hoàn đặt cọc", lease.Deposit, period);
        foreach (var facility in await db.Facilities.Where(x => x.AssetId == lease.AssetId && x.Owner == "npc").ToListAsync())
        {
            facility.Open = true;
            facility.Staff = 1;
            facility.Level = 1;
            facility.Price = facility.Kind switch { "homestay" => 145, "dock" => 95, _ => 65 };
        }
    }

    private void Record(Company company, string asset, string key, string kind, decimal amount, long period)
    {
        Require(company.Balance + amount >= 0, "Doanh nghiệp không đủ tiền.");
        company.Balance += amount;
        db.Ledger.Add(new() { Id=Guid.NewGuid(), CompanyId=company.Id, AssetId=asset, Key=key, Kind=kind, Amount=amount, Period=period });
    }

    private static void Require(bool valid, string message)
    {
        if (!valid) throw new RuleException(message);
    }
}

