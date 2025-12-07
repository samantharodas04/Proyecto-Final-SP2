using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CreditosApi.Models
{
    public class Cliente
    {
        [Key]
        public int Id { get; set; }   // Nuevo PK real

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

        public int UsuarioId { get; set; }

        public DateTime FechaRegistro { get; set; } = DateTime.Now;

        // Relación con Usuario
        [ForeignKey("Usuario")]
        public int UsuarioId { get; set; }
        public Usuario? Usuario { get; set; }

        // 🔐 Campos para acceso del cliente
    public string? ClienteEmailLogin { get; set; }   // correo que usará para entrar
    public string? ClientePasswordHash { get; set; } // en demo podemos guardar plano, pero idealmente hash
    public bool ClienteCuentaActiva { get; set; } = false;
    }
}
