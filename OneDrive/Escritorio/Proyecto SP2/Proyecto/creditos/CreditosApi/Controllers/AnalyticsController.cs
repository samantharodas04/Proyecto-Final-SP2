using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CreditosApi.Data;

namespace CreditosApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AnalyticsController : ControllerBase
    {
        private readonly AppDbContext _context;
        public AnalyticsController(AppDbContext context) => _context = context;

        /// GET: /api/analytics/best-sellers?usuarioId=1&from=2025-01-01&to=2025-12-31&top=10
        /// Agrupa por ItemNombre (snapshot) para cubrir items eliminados o renombrados
        [HttpGet("best-sellers")]
        public async Task<IActionResult> GetBestSellers(
            [FromQuery] int usuarioId,
            [FromQuery] DateTime? from = null,
            [FromQuery] DateTime? to = null,
            [FromQuery] int top = 10)
        {
            if (usuarioId <= 0) return BadRequest("usuarioId requerido.");

            var q = _context.DeudaDetalles
                .Include(dd => dd.Deuda)
                .Where(dd => dd.Deuda.UsuarioId == usuarioId);

            if (from.HasValue)
                q = q.Where(dd => dd.Deuda.FechaCreacion >= from.Value);
            if (to.HasValue)
                q = q.Where(dd => dd.Deuda.FechaCreacion <= to.Value);

            var data = await q
                .GroupBy(dd => new { dd.ItemNombre }) // 🔑 agrupamos por snapshot
                .Select(g => new
                {
                    itemNombre = g.Key.ItemNombre,
                    cantidadTotal = g.Sum(x => x.Cantidad),
                    ingresosAprox = g.Sum(x => x.PrecioUnitario * x.Cantidad),
                    // precio promedio sólo informativo
                    precioPromedio = g.Average(x => x.PrecioUnitario)
                })
                .OrderByDescending(x => x.cantidadTotal) // ranking por cantidad vendida
                .ThenByDescending(x => x.ingresosAprox)
                .Take(top)
                .ToListAsync();

            return Ok(data);
        }
    }
}
