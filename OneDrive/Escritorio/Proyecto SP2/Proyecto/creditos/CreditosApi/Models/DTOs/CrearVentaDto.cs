// Models/DTOs/CrearVentaDto.cs
using System;
using System.Collections.Generic;

namespace CreditosApi.Models.DTOs
{
    public class CrearVentaDto
    {
        public int UsuarioId { get; set; }
        public int? ClienteId { get; set; }
        public DateTime? Fecha { get; set; }
        public List<CrearVentaDetalleDto> Detalles { get; set; } = new();
    }

    public class CrearVentaDetalleDto
    {
        public int ItemId { get; set; }
        public int Cantidad { get; set; }
    }
}
