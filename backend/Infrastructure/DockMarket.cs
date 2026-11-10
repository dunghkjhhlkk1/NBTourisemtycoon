using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace Tourism;

[DbContext(typeof(TourismDb))]
[Migration("202611090002_DockMarket")]
public sealed class DockMarket : Migration
{
    protected override void Up(MigrationBuilder migration) => migration.Sql("""
        ALTER TABLE "Markets" ADD COLUMN "DockSeats" integer NOT NULL DEFAULT 0,
          ADD COLUMN "DockFare" numeric NOT NULL DEFAULT 0,
          ADD COLUMN "DockGross" numeric NOT NULL DEFAULT 0;
        """);

    protected override void Down(MigrationBuilder migration) => migration.Sql("""
        ALTER TABLE "Markets" DROP COLUMN "DockSeats", DROP COLUMN "DockFare", DROP COLUMN "DockGross";
        """);
}

