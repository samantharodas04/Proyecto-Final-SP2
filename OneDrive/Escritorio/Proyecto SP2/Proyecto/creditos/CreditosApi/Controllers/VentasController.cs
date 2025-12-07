// Controllers/VentasController.cs
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CreditosApi.Data;
using CreditosApi.Models;
using CreditosApi.Models.DTOs;
using System.Linq;
using System.Threading.Tasks;
using System;

namespace CreditosApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class VentasController : ControllerBase
    {
        private readonly AppDbContext _context;
        public VentasController(AppDbContext context) => _context = context;

        // POST: api/ventas
        [HttpPost]
        public async Task<IActionResult> Crear([FromBody] CrearVentaDto dto)
        {
            if (dto.Detalles == null || dto.Detalles.Count == 0)
                return BadRequest("La venta debe tener al menos 1 detalle.");

            var ids = dto.Detalles.Select(d => d.ItemId).Distinct().ToList();
            var items = await _context.Items
                .Where(i => ids.Contains(i.Id))
                .ToDictionaryAsync(i => i.Id);

            decimal total = 0m;
            var venta = new Venta
            {
                UsuarioId = dto.UsuarioId,
                ClienteId = dto.ClienteId,
                Fecha = dto.Fecha ?? DateTime.Now
            };

            foreach (var det in dto.Detalles)
            {
                if (!items.TryGetValue(det.ItemId, out var it))
                    return BadRequest($"Item {det.ItemId} no existe.");

                if (it.Stock < det.Cantidad)
                    return BadRequest($"Stock insuficiente para {it.Nombre}. Stock: {it.Stock}");

                var vd = new VentaDetalle
                {
                    ItemId = it.Id,
                    ItemNombre = it.Nombre,             // snapshot
                    PrecioUnitario = (decimal)it.Precio,
                    Cantidad = det.Cantidad
                };
                venta.Detalles.Add(vd);

                // descuenta stock
                it.Stock -= det.Cantidad;

                total += vd.PrecioUnitario * vd.Cantidad;
            }

            venta.Total = total;

            _context.Ventas.Add(venta);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                venta.Id,
                venta.Total,
                venta.Fecha,
                venta.UsuarioId,
                venta.ClienteId,
                Detalles = venta.Detalles.Select(d => new {
                    d.ItemId, d.ItemNombre, d.Cantidad, d.PrecioUnitario
                })
            });
        }

        // GET: api/ventas/resumen?usuarioId=1&from=2025-01-01&to=2025-12-31
        [HttpGet("resumen")]
        public async Task<IActionResult> Resumen(
            [FromQuery] int usuarioId,
            [FromQuery] DateTime? from,
            [FromQuery] DateTime? to)
        {
            var q = _context.Ventas.Where(v => v.UsuarioId == usuarioId);

            if (from.HasValue) q = q.Where(v => v.Fecha >= from.Value);
            if (to.HasValue)   q = q.Where(v => v.Fecha <= to.Value);

            var total = await q.SumAsync(v => (decimal?)v.Total) ?? 0m;

            var top = await _context.VentaDetalles
                .Include(d => d.Venta)
                .Where(d => d.Venta.UsuarioId == usuarioId
                            && (!from.HasValue || d.Venta.Fecha >= from.Value)
                            && (!to.HasValue || d.Venta.Fecha <= to.Value))
                .GroupBy(d => d.ItemNombre)
                .Select(g => new {
                    ItemNombre = g.Key,
                    Cantidad = g.Sum(x => x.Cantidad)
                })
                .OrderByDescending(x => x.Cantidad)
                .FirstOrDefaultAsync();

            return Ok(new {
                ventasTotales = total,
                productoEstrella = top?.ItemNombre ?? "-",
                productoEstrellaCantidad = top?.Cantidad ?? 0
            });
        }
    }
}
