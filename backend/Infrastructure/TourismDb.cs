using Microsoft.EntityFrameworkCore;

namespace Tourism;

public sealed class TourismDb(DbContextOptions<TourismDb> options) : DbContext(options)
{
    public DbSet<Company> Companies => Set<Company>();
    public DbSet<Asset> Assets => Set<Asset>();
    public DbSet<Lease> Leases => Set<Lease>();
    public DbSet<Facility> Facilities => Set<Facility>();
    public DbSet<LedgerEntry> Ledger => Set<LedgerEntry>();
    public DbSet<CommandReceipt> Receipts => Set<CommandReceipt>();
    public DbSet<Market> Markets => Set<Market>();

    protected override void OnModelCreating(ModelBuilder model)
    {
        model.Entity<Lease>().HasOne<Asset>().WithMany().HasForeignKey(x => x.AssetId);
        model.Entity<Lease>().HasOne<Company>().WithMany().HasForeignKey(x => x.CompanyId);
        model.Entity<Lease>().HasIndex(x => x.AssetId).IsUnique().HasFilter("\"Status\" = 'Active'");
        model.Entity<Facility>().HasOne<Asset>().WithMany().HasForeignKey(x => x.AssetId);
        model.Entity<LedgerEntry>().HasOne<Company>().WithMany().HasForeignKey(x => x.CompanyId);
        model.Entity<LedgerEntry>().HasIndex(x => new { x.CompanyId, x.Key }).IsUnique();
        model.Entity<CommandReceipt>().HasKey(x => new { x.CompanyId, x.Key });
        model.Entity<CommandReceipt>().HasOne<Company>().WithMany().HasForeignKey(x => x.CompanyId);
    }
}

