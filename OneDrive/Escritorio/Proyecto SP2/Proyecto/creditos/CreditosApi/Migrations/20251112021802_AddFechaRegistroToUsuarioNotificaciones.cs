using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CreditosApi.Migrations
{
    /// <inheritdoc />
    public partial class AddFechaRegistroToUsuarioNotificaciones : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_UsuarioNotificaciones_Usuarios_UsuarioId",
                table: "UsuarioNotificaciones");

            migrationBuilder.DropIndex(
                name: "IX_UsuarioNotificaciones_UsuarioId",
                table: "UsuarioNotificaciones");

            migrationBuilder.AddColumn<DateTime>(
                name: "FechaRegistro",
                table: "UsuarioNotificaciones",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "SYSUTCDATETIME()");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "FechaRegistro",
                table: "UsuarioNotificaciones");

            migrationBuilder.CreateIndex(
                name: "IX_UsuarioNotificaciones_UsuarioId",
                table: "UsuarioNotificaciones",
                column: "UsuarioId");

            migrationBuilder.AddForeignKey(
                name: "FK_UsuarioNotificaciones_Usuarios_UsuarioId",
                table: "UsuarioNotificaciones",
                column: "UsuarioId",
                principalTable: "Usuarios",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
