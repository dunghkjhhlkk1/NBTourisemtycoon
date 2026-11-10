using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace Tourism;

[DbContext(typeof(TourismDb))]
[Migration("202611090003_LeaseDemoDock")]
public sealed class LeaseDemoDock : Migration
{
    protected override void Up(MigrationBuilder migration) => migration.Sql("""
        UPDATE "Assets" SET "Kind" = 'property', "Rent" = 200, "Deposit" = 300 WHERE "Id" = 'dock';
        """);

    protected override void Down(MigrationBuilder migration) => migration.Sql("""
        UPDATE "Assets" SET "Kind" = 'public', "Rent" = 0, "Deposit" = 0 WHERE "Id" = 'dock';
        """);
}

