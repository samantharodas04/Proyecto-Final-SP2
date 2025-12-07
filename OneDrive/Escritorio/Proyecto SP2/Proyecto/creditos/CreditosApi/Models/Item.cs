using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CreditosApi.Models
{
    public class Item
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Required]
        [MaxLength(200)]
        public string Nombre { get; set; } = string.Empty;

        [MaxLength(500)]
        public string? Descripcion { get; set; }

        [Required]
        [Column(TypeName = "decimal(10,2)")]
        public decimal Precio { get; set; }

        public string? Foto { get; set; } // 👈 coincide con tu tabla

        public DateTime FechaRegistro { get; set; } = DateTime.Now;

        // 🔹 Relación con Usuario
        [Required]
        public int UsuarioId { get; set; }
        public Usuario? Usuario { get; set; }

        public bool IsActivo { get; set; } = true;   // 👈 soft delete
        public DateTime? DeletedAt { get; set; }     // 👈 cuándo se “borró”
        public int Stock { get; set; }  // stock actual
    }
}
