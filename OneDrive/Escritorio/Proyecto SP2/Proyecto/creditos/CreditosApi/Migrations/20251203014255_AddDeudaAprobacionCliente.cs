using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CreditosApi.Migrations
{
    /// <inheritdoc />
    public partial class AddDeudaAprobacionCliente : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            

            migrationBuilder.AddColumn<bool>(
                name: "AprobadaPorCliente",
                table: "Deudas",
                type: "bit",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "FechaAprobacionCliente",
                table: "Deudas",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "RequiereAprobacionCliente",
                table: "Deudas",
                type: "bit",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
           

            migrationBuilder.DropColumn(
                name: "AprobadaPorCliente",
                table: "Deudas");

            migrationBuilder.DropColumn(
                name: "FechaAprobacionCliente",
                table: "Deudas");

            migrationBuilder.DropColumn(
                name: "RequiereAprobacionCliente",
                table: "Deudas");
        }
    }
}
