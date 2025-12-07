using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CreditosApi.Migrations
{
    /// <inheritdoc />
    public partial class UpdateModeloClientesAuth : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "ClienteCuentaActiva",
                table: "Deudas",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "ClienteEmailLogin",
                table: "Deudas",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ClientePasswordHash",
                table: "Deudas",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "ClienteCuentaActiva",
                table: "Clientes",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "ClienteEmailLogin",
                table: "Clientes",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ClientePasswordHash",
                table: "Clientes",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ClienteCuentaActiva",
                table: "Deudas");

            migrationBuilder.DropColumn(
                name: "ClienteEmailLogin",
                table: "Deudas");

            migrationBuilder.DropColumn(
                name: "ClientePasswordHash",
                table: "Deudas");

            migrationBuilder.DropColumn(
                name: "ClienteCuentaActiva",
                table: "Clientes");

            migrationBuilder.DropColumn(
                name: "ClienteEmailLogin",
                table: "Clientes");

            migrationBuilder.DropColumn(
                name: "ClientePasswordHash",
                table: "Clientes");
        }
    }
}
