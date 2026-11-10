using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace Tourism;

[DbContext(typeof(TourismDb))]
[Migration("202611090001_Initial")]
public sealed class Initial : Migration
{
    protected override void Up(MigrationBuilder migration) => migration.Sql("""
        CREATE TABLE "Companies" ("Id" text PRIMARY KEY, "Owner" text NOT NULL, "Name" text NOT NULL, "Balance" numeric NOT NULL CHECK ("Balance" >= 0));
        CREATE TABLE "Assets" ("Id" text PRIMARY KEY, "Name" text NOT NULL, "Region" text NOT NULL, "Kind" text NOT NULL, "Zone" text NOT NULL, "Owner" text NOT NULL,
          "X" int NOT NULL, "Y" int NOT NULL, "Width" int NOT NULL, "Height" int NOT NULL, "Rent" numeric NOT NULL, "Deposit" numeric NOT NULL, "Allowed" text NOT NULL);
        CREATE TABLE "Leases" ("Id" uuid PRIMARY KEY, "AssetId" text NOT NULL REFERENCES "Assets", "CompanyId" text NOT NULL REFERENCES "Companies",
          "Landlord" text NOT NULL, "Start" bigint NOT NULL, "End" bigint NOT NULL, "PaidThrough" bigint NOT NULL, "Deposit" numeric NOT NULL, "Rent" numeric NOT NULL, "Status" text NOT NULL);
        CREATE UNIQUE INDEX active_asset_lease ON "Leases" ("AssetId") WHERE "Status" = 'Active';
        CREATE INDEX company_leases ON "Leases" ("CompanyId");
        CREATE TABLE "Facilities" ("Id" text PRIMARY KEY, "AssetId" text NOT NULL REFERENCES "Assets", "Kind" text NOT NULL, "Owner" text NOT NULL,
          "X" int NOT NULL, "Y" int NOT NULL, "Staff" int NOT NULL, "Level" int NOT NULL, "Price" numeric NOT NULL, "Open" boolean NOT NULL);
        CREATE INDEX asset_facilities ON "Facilities" ("AssetId");
        CREATE TABLE "Ledger" ("Id" uuid PRIMARY KEY, "CompanyId" text NOT NULL REFERENCES "Companies", "Key" text NOT NULL, "Kind" text NOT NULL,
          "AssetId" text NOT NULL REFERENCES "Assets", "Amount" numeric NOT NULL, "Period" bigint NOT NULL, UNIQUE ("CompanyId", "Key"));
        CREATE TABLE "Receipts" ("CompanyId" text NOT NULL REFERENCES "Companies", "Key" uuid NOT NULL, "Fingerprint" text NOT NULL, PRIMARY KEY ("CompanyId", "Key"));
        CREATE TABLE "Markets" ("Id" text PRIMARY KEY, "Period" bigint NOT NULL, "Demand" int NOT NULL, "Served" int NOT NULL, "NpcServed" int NOT NULL);
        """);

    protected override void Down(MigrationBuilder migration) => migration.Sql("""
        DROP TABLE "Markets", "Receipts", "Ledger", "Facilities", "Leases", "Assets", "Companies";
        """);
}

