// Models/DTOs/DashboardResumenDto.cs
using System;

namespace CreditosApi.Models.DTOs
{
    public class DashboardResumenDto
    {
        // Totales de items vendidos (suma de Monto de las deudas en rango)
        public decimal VentasTotales { get; set; }

        // Suma de saldos positivos (deudas - pagos)
        public decimal SaldoPendiente { get; set; }

        // Top 1 item (best seller por cantidad)
        public string? TopItemNombre { get; set; }
        public int? TopItemCantidad { get; set; }
        public decimal? TopItemMonto { get; set; }

        // 👇 NUEVOS
        // Número de clientes con al menos una deuda vencida y saldo > 0
        public int ClientesMorosos { get; set; }

        // Promedio de días de atraso de deudas vencidas con saldo > 0
        public double PromedioDiasAtraso { get; set; }
    }
}
