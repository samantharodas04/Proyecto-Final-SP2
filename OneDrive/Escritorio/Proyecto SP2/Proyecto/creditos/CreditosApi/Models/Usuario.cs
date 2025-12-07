using System.Collections.Generic;

namespace CreditosApi.Models
{
    public class Usuario
    {
        public int Id { get; set; }
        public string Nombre { get; set; } = string.Empty;
        public string Apellido { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Dpi { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public DateTime FechaRegistro { get; set; } = DateTime.Now;

        // 🔹 Relación 1:N (un usuario tiene muchos clientes)
        public ICollection<Cliente> Clientes { get; set; } = new List<Cliente>();
         public ICollection<Item> Items { get; set; } = new List<Item>();
    }
}
