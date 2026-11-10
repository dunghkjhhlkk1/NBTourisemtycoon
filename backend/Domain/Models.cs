namespace Tourism;

public sealed class Company
{
    public string Id { get; set; } = "demo";
    public string Owner { get; set; } = "local-player";
    public string Name { get; set; } = "Du lịch Tràng An";
    public decimal Balance { get; set; } = 12500;
}

public sealed class Asset
{
    public string Id { get; set; } = "";
    public string Name { get; set; } = "";
    public string Region { get; set; } = "trang-an";
    public string Kind { get; set; } = "";
    public string Zone { get; set; } = "";
    public string Owner { get; set; } = "npc";
    public int X { get; set; }
    public int Y { get; set; }
    public int Width { get; set; }
    public int Height { get; set; }
    public decimal Rent { get; set; }
    public decimal Deposit { get; set; }
    public string Allowed { get; set; } = "";
}

public sealed class Lease
{
    public Guid Id { get; set; }
    public string AssetId { get; set; } = "";
    public string CompanyId { get; set; } = "";
    public string Landlord { get; set; } = "npc";
    public long Start { get; set; }
    public long End { get; set; }
    public long PaidThrough { get; set; }
    public decimal Deposit { get; set; }
    public decimal Rent { get; set; }
    public string Status { get; set; } = "Active";
}

public sealed class Facility
{
    public string Id { get; set; } = "";
    public string AssetId { get; set; } = "";
    public string Kind { get; set; } = "";
    public string Owner { get; set; } = "npc";
    public int X { get; set; }
    public int Y { get; set; }
    public int Staff { get; set; } = 1;
    public int Level { get; set; } = 1;
    public decimal Price { get; set; }
    public bool Open { get; set; } = true;
}

public sealed class LedgerEntry
{
    public Guid Id { get; set; }
    public string CompanyId { get; set; } = "";
    public string Key { get; set; } = "";
    public string Kind { get; set; } = "";
    public string AssetId { get; set; } = "";
    public decimal Amount { get; set; }
    public long Period { get; set; }
}

public sealed class CommandReceipt
{
    public string CompanyId { get; set; } = "";
    public Guid Key { get; set; }
    public string Fingerprint { get; set; } = "";
}

public sealed class Market
{
    public string Id { get; set; } = "trang-an";
    public long Period { get; set; }
    public int Demand { get; set; }
    public int Served { get; set; }
    public int NpcServed { get; set; }
    public int DockSeats { get; set; }
    public decimal DockFare { get; set; }
    public decimal DockGross { get; set; }
}

public sealed record ActionRequest(Guid Key, string Action, string Target, string? Kind, int X, int Y, int Value);
public sealed class RuleException(string message) : Exception(message);

