using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CreditosApi.Models
{
    public class Cliente
    {
        [Key] // 👈 Primary Key real
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Required]
        [MaxLength(20)]
        public string Dpi { get; set; } = string.Empty;

        [Required]
        [MaxLength(200)]
        public string Nombre { get; set; } = string.Empty;

        [MaxLength(200)]
        public string? Email { get; set; }

        [MaxLength(20)]
        public string? Telefono { get; set; }

        public DateTime FechaRegistro { get; set; } = DateTime.Now;

        public string? ClienteEmailLogin { get; set; }
        public string? ClientePasswordHash { get; set; }
        public bool ClienteCuentaActiva { get; set; }
        // 🔹 Relación con Usuario
        [Required]
        public int UsuarioId { get; set; }
        public Usuario? Usuario { get; set; }
    }
}
