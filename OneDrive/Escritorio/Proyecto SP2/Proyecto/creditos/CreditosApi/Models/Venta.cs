// Models/Venta.cs
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace CreditosApi.Models
{
    public class Venta
    {
        public int Id { get; set; }
        public int UsuarioId { get; set; }
        public int? ClienteId { get; set; }          // opcional (venta sin cliente)
        public DateTime Fecha { get; set; } = DateTime.Now;
        public decimal Total { get; set; }

        public Usuario? Usuario { get; set; }
        public Cliente? Cliente { get; set; }
        public ICollection<VentaDetalle> Detalles { get; set; } = new List<VentaDetalle>();
    }
}
