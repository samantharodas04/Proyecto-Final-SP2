using System;

namespace CreditosApi.Models
{
    public class BlockchainLog
    {
        public int Id { get; set; }

        public string Tipo { get; set; } = string.Empty;
        public int? DeudaId { get; set; }
        public int? PagoId { get; set; }
        public string? TxHash { get; set; }
        public bool Exitoso { get; set; }
        public string? Error { get; set; }
        public DateTime Fecha { get; set; } = DateTime.UtcNow;
    }
}
