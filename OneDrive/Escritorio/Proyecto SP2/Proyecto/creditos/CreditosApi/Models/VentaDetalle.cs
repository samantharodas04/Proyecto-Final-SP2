// Models/VentaDetalle.cs
using System.ComponentModel.DataAnnotations.Schema;

namespace CreditosApi.Models
{
    public class VentaDetalle
    {
        public int Id { get; set; }
        public int VentaId { get; set; }
        public int? ItemId { get; set; }                 // nullable por snapshot
        public string ItemNombre { get; set; } = "";
        public decimal PrecioUnitario { get; set; }
        public int Cantidad { get; set; }

        public Venta Venta { get; set; } = default!;
        public Item? Item { get; set; }
    }
}
