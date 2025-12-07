using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CreditosApi.Data;
using CreditosApi.Models;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace CreditosApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")] // => api/clientes
    public class ClientesController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ClientesController(AppDbContext context)
        {
            _context = context;
        }

        // =========================
        // Listar clientes por usuario
        // GET: api/clientes/{usuarioId}
        // =========================
        [HttpGet("{usuarioId:int}")]
        public async Task<IActionResult> GetClientes(int usuarioId)
        {
            var clientes = await _context.Clientes
                .Where(c => c.UsuarioId == usuarioId)
                .OrderBy(c => c.Nombre)
                .ToListAsync();

            return Ok(clientes);
        }

        // =========================
        // Crear cliente
        // POST: api/clientes
        // =========================
        [HttpPost]
        public async Task<IActionResult> Crear([FromBody] Cliente cliente)
        {
            if (cliente == null)
                return BadRequest("Cliente inválido");

            try
            {
                cliente.FechaRegistro = DateTime.Now;
                _context.Clientes.Add(cliente);
                await _context.SaveChangesAsync();

                return Content("Cliente creado correctamente", "text/plain");
            }
            catch (DbUpdateException ex)
            {
                if (ex.InnerException?.Message.Contains("UQ_Cliente_Dpi_Usuario") == true)
                    return BadRequest("Ya existe un cliente con ese DPI para este usuario");

                return BadRequest("Error al crear cliente");
            }
        }

        // =========================
        // Actualizar cliente
        // PUT: api/clientes/{id}
        // =========================
        [HttpPut("{id:int}")]
        public async Task<IActionResult> Actualizar(int id, [FromBody] Cliente cliente)
        {
            var existente = await _context.Clientes.FirstOrDefaultAsync(c => c.Id == id);
            if (existente == null)
                return NotFound("Cliente no encontrado");

            existente.Dpi = cliente.Dpi;
            existente.Nombre = cliente.Nombre;
            existente.Email = cliente.Email;
            existente.Telefono = cliente.Telefono;

            try
            {
                await _context.SaveChangesAsync();
                return Content("Cliente actualizado", "text/plain");
            }
            catch (DbUpdateException ex)
            {
                if (ex.InnerException?.Message.Contains("UQ_Cliente_Dpi_Usuario") == true)
                    return BadRequest("Ya existe un cliente con ese DPI para este usuario");

                return BadRequest("Error al actualizar cliente");
            }
        }

        // =========================
        // Eliminar cliente
        // DELETE: api/clientes/{id}
        // =========================
        [HttpDelete("{id:int}")]
        public async Task<IActionResult> Eliminar(int id)
        {
            var cliente = await _context.Clientes.FirstOrDefaultAsync(c => c.Id == id);
            if (cliente == null)
                return NotFound("Cliente no encontrado");

            _context.Clientes.Remove(cliente);
            await _context.SaveChangesAsync();

            return Content("Cliente eliminado", "text/plain");
        }

        // ============================================================
        // PERFIL CREDITICIO (Score)
        // GET: api/clientes/{clienteId}/score?usuarioId=123
        // Requiere: Deuda tiene navegación Pagos; AppDbContext tiene DbSet<Pago>
        // ============================================================
        [HttpGet("{clienteId:int}/score")]
        public async Task<IActionResult> GetScore(int clienteId, [FromQuery] int usuarioId)
        {
            // Trae deudas + pagos del cliente para este usuario
            var deudas = await _context.Deudas
                .Include(d => d.Pagos)
                .Where(d => d.ClienteId == clienteId && d.UsuarioId == usuarioId)
                .ToListAsync();

            // Si no tiene deudas, devuelve score alto por defecto
            if (deudas.Count == 0)
            {
                return Ok(new
                {
                    clienteId,
                    totalDeudas = 0,
                    deudasPagadas = 0,
                    deudasPagadasATiempo = 0,
                    montoActivo = 0m,
                    montoVencido = 0m,
                    pagosUltimos90Dias = 0,
                    diasDesdeUltimoAtraso = 9999,
                    score = 95.0,
                    tier = "Excelente"
                });
            }

            var totalDeudas = deudas.Count;

            decimal SumPagos(Deuda d) => d.Pagos?.Sum(p => p.Monto) ?? 0m;

            var pagadas = deudas.Count(d => SumPagos(d) >= (decimal)d.Monto - 0.01m);
            var aTiempo = deudas.Count(d =>
                SumPagos(d) >= (decimal)d.Monto - 0.01m &&
                (d.Pagos?.Max(p => (DateTime?)p.Fecha) ?? DateTime.MinValue) <= d.FechaLimite);

            var montoActivo = deudas.Sum(d => Math.Max(0m, (decimal)d.Monto - SumPagos(d)));
            var montoVencido = deudas
                .Where(d => d.FechaLimite < DateTime.Now)
                .Sum(d => Math.Max(0m, (decimal)d.Monto - SumPagos(d)));

            var pagos90d = deudas.SelectMany(d => d.Pagos ?? [])
                .Count(p => p.Fecha >= DateTime.Now.AddDays(-90));

            var ultAtraso = deudas
                .Where(d => d.FechaLimite < DateTime.Now && (decimal)d.Monto - SumPagos(d) > 0m)
                .Select(d => (DateTime?)d.FechaLimite)
                .DefaultIfEmpty(null)
                .Max();

            int diasDesdeAtraso = ultAtraso.HasValue
                ? (int)(DateTime.Now - ultAtraso.Value).TotalDays
                : 9999;

            // Heurística de score simple (ajústala a tu gusto)
            double score = 100;
            score -= Math.Min((double)montoVencido, 100);            // castiga monto vencido
            score -= Math.Max(0, (totalDeudas - pagadas) * 2);       // castiga deudas activas
            score = Math.Max(0, Math.Min(100, score));

            string tier = score >= 85 ? "Excelente"
                         : score >= 70 ? "Bueno"
                         : score >= 50 ? "Regular"
                         : "Riesgoso";

            return Ok(new
            {
                clienteId,
                totalDeudas,
                deudasPagadas = pagadas,
                deudasPagadasATiempo = aTiempo,
                montoActivo,
                montoVencido,
                pagosUltimos90Dias = pagos90d,
                diasDesdeUltimoAtraso = diasDesdeAtraso,
                score,
                tier
            });
        }
    }
}
