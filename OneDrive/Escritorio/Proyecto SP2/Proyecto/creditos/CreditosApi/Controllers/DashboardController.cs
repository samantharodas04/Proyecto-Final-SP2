using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

using CreditosApi.Data;
using CreditosApi.Models.DTOs;

namespace CreditosApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DashboardController : ControllerBase
    {
        private readonly AppDbContext _context;

        public DashboardController(AppDbContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Resumen para Dashboard.
        /// GET: api/dashboard/resumen?usuarioId=1&startDate=2025-09-01&endDate=2025-09-30
        /// - VentasTotales: suma de Monto de las deudas en rango.
        /// - SaldoPendiente: suma de saldos positivos (Monto - pagos) en rango.
        /// - TopItem*: top 1 ítem por cantidad vendida en rango.
        /// - ClientesMorosos: # de clientes con deuda vencida y saldo > 0.
        /// - PromedioDiasAtraso: promedio de días de atraso (1 decimal).
        /// </summary>
        [HttpGet("resumen")]
        public async Task<IActionResult> GetDashboardResumen(
            [FromQuery] int usuarioId,
            [FromQuery] DateTime? startDate,
            [FromQuery] DateTime? endDate)
        {
            // --------- Deudas del usuario (aplica rango si viene) ----------
            var deudasQ = _context.Deudas
                .AsNoTracking()
                .Where(d => d.UsuarioId == usuarioId);

            if (startDate.HasValue)
                deudasQ = deudasQ.Where(d => d.FechaCreacion >= startDate.Value);

            if (endDate.HasValue)
                deudasQ = deudasQ.Where(d => d.FechaCreacion <= endDate.Value);

            // Ventas totales = suma del Monto de las deudas (items o monto directo)
            var ventasTotales = await deudasQ.SumAsync(d => (decimal)d.Monto);

            // --------- Saldo pendiente (Monto - pagos) sólo si > 0 ----------
            var saldosQ =
                from d in _context.Deudas.AsNoTracking()
                where d.UsuarioId == usuarioId
                      && (!startDate.HasValue || d.FechaCreacion >= startDate.Value)
                      && (!endDate.HasValue   || d.FechaCreacion <= endDate.Value)
                join p in _context.Pagos.AsNoTracking() on d.Id equals p.DeudaId into gp
                select new
                {
                    Saldo = (decimal)d.Monto - gp.Sum(x => x.Monto)
                };

            var saldoPendiente = await saldosQ
                .Where(x => x.Saldo > 0m)
                .SumAsync(x => (decimal?)x.Saldo) ?? 0m;

            // --------- Top 1 best seller por cantidad ----------
            // Usa el nombre real de tu DbSet de detalles (normalmente "DeudaDetalles").
            var detallesQ = _context.DeudaDetalles
                .AsNoTracking()
                .Include(dd => dd.Deuda)
                .Where(dd => dd.Deuda.UsuarioId == usuarioId);

            if (startDate.HasValue)
                detallesQ = detallesQ.Where(dd => dd.Deuda.FechaCreacion >= startDate.Value);

            if (endDate.HasValue)
                detallesQ = detallesQ.Where(dd => dd.Deuda.FechaCreacion <= endDate.Value);

            var top1 = await detallesQ
                .GroupBy(dd => new { dd.ItemId, dd.ItemNombre })
                .Select(g => new
                {
                    Nombre   = g.Key.ItemNombre,
                    Cantidad = g.Sum(x => x.Cantidad),
                    Monto    = g.Sum(x => x.PrecioUnitario * x.Cantidad)
                })
                .OrderByDescending(x => x.Cantidad)
                .ThenByDescending(x => x.Monto)
                .FirstOrDefaultAsync();

            // --------- Clientes morosos (vencida + saldo > 0) ----------
            var hoy = DateTime.Today;

            var clientesMorosos = await
                (from d in _context.Deudas.AsNoTracking()
                 where d.UsuarioId == usuarioId
                       && d.FechaLimite < hoy
                       && (!startDate.HasValue || d.FechaCreacion >= startDate.Value)
                       && (!endDate.HasValue   || d.FechaCreacion <= endDate.Value)
                 join p in _context.Pagos.AsNoTracking() on d.Id equals p.DeudaId into gp
                 let saldo = (decimal)d.Monto - gp.Sum(x => x.Monto)
                 where saldo > 0m
                 select d.ClienteId
                ).Distinct().CountAsync();

            // --------- Promedio de días de atraso ----------
            double promedioDiasAtraso = 0;

            try
            {
                // Vía SQL (eficiente) si tu provider soporta DateDiffDay
                promedioDiasAtraso = await
                    (from d in _context.Deudas.AsNoTracking()
                     where d.UsuarioId == usuarioId
                           && d.FechaLimite < hoy
                           && (!startDate.HasValue || d.FechaCreacion >= startDate.Value)
                           && (!endDate.HasValue   || d.FechaCreacion <= endDate.Value)
                     join p in _context.Pagos.AsNoTracking() on d.Id equals p.DeudaId into gp
                     let saldo = (decimal)d.Monto - gp.Sum(x => x.Monto)
                     where saldo > 0m
                     select EF.Functions.DateDiffDay(d.FechaLimite, hoy)
                    ).AverageAsync();
            }
            catch
            {
                // Fallback en memoria si el provider no soporta DateDiffDay
                var fechas = await
                    (from d in _context.Deudas.AsNoTracking()
                     where d.UsuarioId == usuarioId
                           && d.FechaLimite < hoy
                           && (!startDate.HasValue || d.FechaCreacion >= startDate.Value)
                           && (!endDate.HasValue   || d.FechaCreacion <= endDate.Value)
                     join p in _context.Pagos.AsNoTracking() on d.Id equals p.DeudaId into gp
                     let saldo = (decimal)d.Monto - gp.Sum(x => x.Monto)
                     where saldo > 0m
                     select d.FechaLimite
                    ).ToListAsync();

                if (fechas.Count > 0)
                {
                    promedioDiasAtraso = fechas
                        .Select(fl => (hoy - fl.Date).TotalDays)
                        .Average();
                }
            }

            var dto = new DashboardResumenDto
            {
                VentasTotales   = ventasTotales,
                SaldoPendiente  = saldoPendiente,
                TopItemNombre   = top1?.Nombre,
                TopItemCantidad = top1?.Cantidad,
                TopItemMonto    = top1?.Monto,
                ClientesMorosos = clientesMorosos,
                PromedioDiasAtraso = Math.Round(promedioDiasAtraso, 1)
            };

            return Ok(dto);
        }
    }
}
