using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CreditosApi.Models
{
    [Table("DeudaDetalle")] // 👈 nombre EXACTO de tu tabla
    public class DeudaDetalle
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int DeudaId { get; set; }
        public Deuda Deuda { get; set; } = null!;

        // 👇 ahora nullable para que si se borra el Item, el historial quede
        public int? ItemId { get; set; }
        public Item? Item { get; set; }

        [Required]
        public int Cantidad { get; set; } = 1;

        [Column(TypeName = "decimal(10,2)")]
        public decimal PrecioUnitario { get; set; }  // precio al momento

        [Required, MaxLength(200)]
        public string ItemNombre { get; set; } = ""; // nombre al momento
    }
}
