using System;
using System.ComponentModel.DataAnnotations.Schema;

namespace CreditosApi.Models
{
    public class Pago
    {
        public int Id { get; set; }

        public int DeudaId { get; set; }
        public Deuda Deuda { get; set; } = null!;

        [Column(TypeName = "decimal(10,2)")]
        public decimal Monto { get; set; }

        public DateTime Fecha { get; set; } = DateTime.Now;

        public string? Nota { get; set; }

        // opcional si quieres registrar quién lo creó
        public int UsuarioId { get; set; }
    }
}
