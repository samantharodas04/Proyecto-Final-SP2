using System;
using System.Collections.Generic;

namespace CreditosApi.Models.DTOs
{
    public class CrearDeudaDto
    {
        public int UsuarioId { get; set; }
        public int ClienteId { get; set; }
        public double? Monto { get; set; }         // opcional si hay Detalles
        public DateTime? FechaLimite { get; set; }
        public List<CrearDetalleDto> Detalles { get; set; } = new();
    }

    public class CrearDetalleDto
    {
        public int ItemId { get; set; }
        public int Cantidad { get; set; } = 1;
    }
}
