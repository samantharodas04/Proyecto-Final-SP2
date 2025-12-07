using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema; // [NotMapped], [Column]
using System.Linq; // Sum()

namespace CreditosApi.Models
{
    public class Deuda
    {
        public int Id { get; set; }
        public double Monto { get; set; }
        public DateTime FechaLimite { get; set; }
        public DateTime FechaCreacion { get; set; }
        public bool Aprobada { get; set; } = true;

        // ✔ Nuevo: cuándo quedó totalmente pagada (saldo 0)
        public DateTime? FechaPagada { get; set; }

        public int UsuarioId { get; set; }
        public int ClienteId { get; set; }

        public Usuario? Usuario { get; set; }
        public Cliente? Cliente { get; set; }
        public bool RequiereAprobacionCliente { get; set; } = false;
        public bool? AprobadaPorCliente { get; set; }
        public DateTime? FechaAprobacionCliente { get; set; }
        public string? TxHash { get; set; }  // hash de la transacción registrarDeuda
        public bool OnChain { get; set; }
        public ICollection<DeudaDetalle> Detalles { get; set; } = new List<DeudaDetalle>();

        // Si ya creaste el modelo Pago y DbSet en AppDbContext
        public ICollection<Pago> Pagos { get; set; } = new List<Pago>();

        [NotMapped]
        public decimal Saldo => (decimal)Monto - (Pagos?.Sum(p => p.Monto) ?? 0m);

        // 🔐 Campos para acceso del cliente
    public string? ClienteEmailLogin { get; set; }   // correo que usará para entrar
    public string? ClientePasswordHash { get; set; } // en demo podemos guardar plano, pero idealmente hash
    public bool ClienteCuentaActiva { get; set; } = false;
    }
}
