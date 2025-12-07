using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CreditosApi.Migrations
{
    /// <inheritdoc />
    public partial class AddBlockchainLogs : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "BlockchainLogs",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Tipo = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    DeudaId = table.Column<int>(type: "int", nullable: true),
                    PagoId = table.Column<int>(type: "int", nullable: true),
                    TxHash = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    Exitoso = table.Column<bool>(type: "bit", nullable: false),
                    Error = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Fecha = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BlockchainLogs", x => x.Id);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "BlockchainLogs");
        }
    }
}
