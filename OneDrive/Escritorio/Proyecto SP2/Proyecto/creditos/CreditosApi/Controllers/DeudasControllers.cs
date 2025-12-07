// RUTA: Controllers/DeudasController.cs
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CreditosApi.Data;
using CreditosApi.Models;
using CreditosApi.Models.DTOs;
using CreditosApi.Services;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace CreditosApi.Controllers
{
    public class BestSellerDto
    {
        public int ItemId { get; set; }
        public string ItemNombre { get; set; } = "";
        public int CantidadVendida { get; set; }
        public decimal MontoTotal { get; set; }
    }

    public class DeudorResumenDto
    {
        public int ClienteId { get; set; }
        public string Nombre { get; set; } = "";
        public decimal Total { get; set; }
        public int CantidadDeudas { get; set; }
        public DateTime? UltimaFecha { get; set; }
    }

    public class CrearPagoDto
    {
        public decimal Monto { get; set; }
        public string? Nota { get; set; }
        public int UsuarioId { get; set; }
    }

    public class PagoDto
    {
        public int Id { get; set; }
        public decimal Monto { get; set; }
        public DateTime Fecha { get; set; }
        public string? Nota { get; set; }
    }

    [ApiController]
    [Route("api/[controller]")]
    public class DeudasController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly BlockchainService _blockchain;

        public DeudasController(AppDbContext context, BlockchainService blockchain)
        {
            _context = context;
            _blockchain = blockchain;
        }

        // ======================================================
        // PAGOS
        // ======================================================

        [HttpPost("{deudaId:int}/pagos")]
        public async Task<IActionResult> RegistrarPago(int deudaId, [FromBody] CrearPagoDto dto)
        {
            var deuda = await _context.Deudas
                .Include(d => d.Pagos)
                .FirstOrDefaultAsync(d => d.Id == deudaId);

            if (deuda == null) return NotFound("Deuda no existe.");

            var saldoActual = (decimal)deuda.Monto - deuda.Pagos.Sum(p => p.Monto);
            if (dto.Monto <= 0) return BadRequest("El monto debe ser mayor que 0.");
            if (dto.Monto > saldoActual) return BadRequest("El pago excede el saldo.");

            var pago = new Pago
            {
                DeudaId = deudaId,
                Monto = dto.Monto,
                Nota = dto.Nota,
                Fecha = DateTime.Now,
                UsuarioId = dto.UsuarioId
            };

            _context.Pagos.Add(pago);

            var totalPagos = deuda.Pagos.Sum(p => p.Monto) + dto.Monto;
            var nuevoSaldo = (decimal)deuda.Monto - totalPagos;

            if (nuevoSaldo <= 0 && deuda.FechaPagada == null)
            {
                deuda.FechaPagada = DateTime.Now;
            }

            await _context.SaveChangesAsync();

            string? txHash = null;
            bool onChainOk = false;
            string? errorOnChain = null;

            try
            {
                txHash = await _blockchain.RegistrarPagoOnChainAsync(deuda, pago);
                onChainOk = txHash != null;
            }
            catch (Exception ex)
            {
                errorOnChain = ex.Message;
            }

            _context.BlockchainLogs.Add(new BlockchainLog
            {
                Tipo = "PAGO",
                DeudaId = deuda.Id,
                PagoId = pago.Id,
                TxHash = txHash,
                Exitoso = onChainOk,
                Error = errorOnChain,
                Fecha = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();

            return Ok(new
            {
                deudaId = deuda.Id,
                monto = deuda.Monto,
                totalPagos,
                saldo = nuevoSaldo,
                estaPagada = nuevoSaldo <= 0,
                fechaPagada = deuda.FechaPagada,
                txHash,
                onChain = onChainOk,
                errorOnChain
            });
        }

        [HttpGet("{deudaId:int}/pagos")]
        public async Task<IActionResult> ListarPagos(int deudaId)
        {
            var pagos = await _context.Pagos
                .Where(p => p.DeudaId == deudaId)
                .OrderByDescending(p => p.Fecha)
                .Select(p => new PagoDto
                {
                    Id = p.Id,
                    Monto = p.Monto,
                    Fecha = p.Fecha,
                    Nota = p.Nota
                })
                .ToListAsync();

            return Ok(pagos);
        }

        // ======================================================
        // DEUDORES (HOME TENDERO)
        // ======================================================

        [HttpGet("deudores")]
        public async Task<IActionResult> GetDeudores([FromQuery] int usuarioId)
        {
            var query = await _context.Deudas
                .Where(d => d.UsuarioId == usuarioId)
                .GroupJoin(
                    _context.Pagos,
                    d => d.Id,
                    p => p.DeudaId,
                    (d, pagos) => new { d, pagos }
                )
                .Join(_context.Clientes,
                    x => x.d.ClienteId,
                    c => c.Id,
                    (x, c) => new { x.d, x.pagos, c })
                .GroupBy(g => new { g.c.Id, g.c.Nombre })
                .Select(g => new
                {
                    ClienteId = g.Key.Id,
                    Nombre = g.Key.Nombre,
                    TotalDeudas = g.Sum(z => (decimal)z.d.Monto),
                    TotalPagos = g.Sum(z => z.pagos.Sum(p => p.Monto)),
                    CantidadDeudas = g.Count(),
                    UltimaFecha = g.Max(z => (DateTime?)z.d.FechaCreacion)
                })
                .Select(r => new
                {
                    r.ClienteId,
                    r.Nombre,
                    Total = r.TotalDeudas - r.TotalPagos,
                    r.CantidadDeudas,
                    r.UltimaFecha
                })
                .Where(r => r.Total > 0)
                .OrderByDescending(r => r.Total)
                .ToListAsync();

            return Ok(query);
        }

        // ======================================================
        // CREAR DEUDA
        // ======================================================

        [HttpPost]
        public async Task<IActionResult> Crear([FromBody] CrearDeudaDto dto)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var usuario = await _context.Usuarios.FindAsync(dto.UsuarioId);
            var cliente = await _context.Clientes.FindAsync(dto.ClienteId);
            if (usuario == null || cliente == null)
                return BadRequest("Cliente o usuario inválido.");

            var deuda = new Deuda
            {
                UsuarioId = dto.UsuarioId,
                ClienteId = dto.ClienteId,
                FechaCreacion = DateTime.Now,
                FechaLimite = dto.FechaLimite ?? DateTime.Now,
                Monto = 0
            };

            if (cliente.ClienteCuentaActiva)
            {
                deuda.AprobadaPorCliente = false;
                deuda.FechaAprobacionCliente = null;
            }
            else
            {
                deuda.AprobadaPorCliente = null;
                deuda.FechaAprobacionCliente = null;
            }

            decimal total = 0m;

            if (dto.Detalles != null && dto.Detalles.Count > 0)
            {
                var itemIds = dto.Detalles.Select(d => d.ItemId).Distinct().ToList();
                var items = await _context.Items
                    .Where(i => itemIds.Contains(i.Id))
                    .ToDictionaryAsync(i => i.Id);

                foreach (var det in dto.Detalles)
                {
                    if (!items.TryGetValue(det.ItemId, out var it))
                        return BadRequest($"Item {det.ItemId} no existe o está inactivo.");

                    var dd = new DeudaDetalle
                    {
                        ItemId = it.Id,
                        ItemNombre = it.Nombre,
                        PrecioUnitario = (decimal)it.Precio,
                        Cantidad = det.Cantidad
                    };

                    deuda.Detalles.Add(dd);
                    total += dd.PrecioUnitario * dd.Cantidad;
                }

                deuda.Monto = (double)total;
            }
            else
            {
                if (dto.Monto == null)
                    return BadRequest("Monto requerido si no envías Detalles.");
                deuda.Monto = dto.Monto.Value;
            }

            _context.Deudas.Add(deuda);
            await _context.SaveChangesAsync();

            string? txHash = null;
            bool onChainOk = false;
            string? errorOnChain = null;

            try
            {
                txHash = await _blockchain.RegistrarDeudaOnChainAsync(deuda);
                onChainOk = txHash != null;
            }
            catch (Exception ex)
            {
                errorOnChain = ex.Message;
            }

            deuda.TxHash = txHash;
            deuda.OnChain = onChainOk;
            await _context.SaveChangesAsync();

            _context.BlockchainLogs.Add(new BlockchainLog
            {
                Tipo = "DEUDA",
                DeudaId = deuda.Id,
                TxHash = txHash,
                Exitoso = onChainOk,
                Error = errorOnChain,
                Fecha = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();

            return Ok(new
            {
                deuda.Id,
                deuda.Monto,
                deuda.FechaCreacion,
                deuda.FechaLimite,
                deuda.ClienteId,
                deuda.UsuarioId,
                deuda.AprobadaPorCliente,
                deuda.FechaAprobacionCliente,
                txHash,
                onChain = onChainOk,
                errorOnChain,
                Detalles = deuda.Detalles.Select(d => new
                {
                    d.Id,
                    d.ItemId,
                    itemNombre = d.ItemNombre,
                    d.Cantidad,
                    d.PrecioUnitario
                })
            });
        }

        // ======================================================
        // HISTORIAL POR CLIENTE (tendero / cliente)
        // ======================================================

        [HttpGet("historial/{clienteId:int}")]
        public async Task<IActionResult> HistorialPorCliente(int clienteId, [FromQuery] int? usuarioId)
        {
            var query = _context.Deudas
                .AsNoTracking()
                .Where(d => d.ClienteId == clienteId);

            if (usuarioId.HasValue)
                query = query.Where(d => d.UsuarioId == usuarioId.Value);

            query = query.Where(d => d.AprobadaPorCliente != false);

            var deudas = await query
                .GroupJoin(_context.Pagos,
                    d => d.Id,
                    p => p.DeudaId,
                    (d, pagos) => new { d, pagos })
                .OrderByDescending(x => x.d.FechaCreacion)
                .Select(x => new
                {
                    x.d.Id,
                    x.d.Monto,
                    x.d.FechaCreacion,
                    x.d.FechaLimite,
                    x.d.ClienteId,
                    x.d.UsuarioId,
                    x.d.FechaPagada,
                    x.d.TxHash,
                    x.d.OnChain,
                    detalles = x.d.Detalles.Select(dd => new
                    {
                        dd.Id,
                        dd.ItemId,
                        itemNombre = dd.ItemNombre,
                        dd.Cantidad,
                        dd.PrecioUnitario
                    }),
                    totalPagos = x.pagos.Sum(p => p.Monto),
                    saldo = (decimal)x.d.Monto - x.pagos.Sum(p => p.Monto),
                    estaPagada = ((decimal)x.d.Monto - x.pagos.Sum(p => p.Monto)) <= 0
                })
                .ToListAsync();

            return Ok(deudas);
        }

        // ======================================================
        // ENDPOINT VIEW DEUDA ON-CHAIN
        // ======================================================

        [HttpGet("{id:int}/on-chain")]
        public async Task<IActionResult> GetDeudaOnChain(int id)
        {
            var deuda = await _context.Deudas.AsNoTracking().FirstOrDefaultAsync(d => d.Id == id);
            if (deuda == null) return NotFound("Deuda no encontrada.");

            var montoOnChain = await _blockchain.ObtenerMontoOnChainAsync(id);

            return Ok(new
            {
                deudaId = deuda.Id,
                montoLocal = deuda.Monto,
                montoOnChain
            });
        }

        // ======================================================
        // PENDIENTES CLIENTE / APROBAR / RECHAZAR / BEST SELLERS / RESUMEN
        // (aquí dejamos lo que ya tenías, sin cambios de blockchain)
        // ======================================================

        [HttpGet("pendientes/{clienteId:int}")]
        public async Task<IActionResult> DeudasPendientesCliente(int clienteId)
        {
            var deudas = await _context.Deudas
                .AsNoTracking()
                .Where(d =>
                    d.ClienteId == clienteId &&
                    d.AprobadaPorCliente == false)
                .GroupJoin(_context.Pagos,
                    d => d.Id,
                    p => p.DeudaId,
                    (d, pagos) => new { d, pagos })
                .OrderByDescending(x => x.d.FechaCreacion)
                .Select(x => new
                {
                    x.d.Id,
                    x.d.Monto,
                    x.d.FechaCreacion,
                    x.d.FechaLimite,
                    detalles = x.d.Detalles.Select(dd => new
                    {
                        dd.Id,
                        dd.ItemId,
                        itemNombre = dd.ItemNombre,
                        dd.Cantidad,
                        dd.PrecioUnitario
                    }),
                    totalPagos = x.pagos.Sum(p => p.Monto),
                    saldo = (decimal)x.d.Monto - x.pagos.Sum(p => p.Monto)
                })
                .ToListAsync();

            return Ok(deudas);
        }

        [HttpPost("aprobar-cliente/{id:int}")]
        public async Task<IActionResult> AprobarDeudaCliente(int id)
        {
            var deuda = await _context.Deudas.FindAsync(id);
            if (deuda == null) return NotFound("Deuda no encontrada.");

            if (deuda.AprobadaPorCliente == true)
                return BadRequest("La deuda ya estaba aprobada.");

            deuda.AprobadaPorCliente = true;
            deuda.FechaAprobacionCliente = DateTime.Now;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Deuda aprobada correctamente." });
        }

        [HttpPost("rechazar-cliente/{id:int}")]
        public async Task<IActionResult> RechazarDeudaCliente(int id)
        {
            var deuda = await _context.Deudas.FindAsync(id);
            if (deuda == null) return NotFound("Deuda no encontrada.");

            if (deuda.AprobadaPorCliente == true)
                return BadRequest("No se puede rechazar, ya estaba aprobada.");

            _context.Deudas.Remove(deuda);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Deuda rechazada y eliminada." });
        }

        [HttpGet("best-sellers")]
        public async Task<IActionResult> GetBestSellers(
            [FromQuery] int usuarioId,
            [FromQuery] DateTime? from,
            [FromQuery] DateTime? to,
            [FromQuery] int top = 5)
        {
            var deudas = _context.Deudas
                .Where(d => d.UsuarioId == usuarioId);

            if (from.HasValue)
                deudas = deudas.Where(d => d.FechaCreacion >= from.Value);

            if (to.HasValue)
                deudas = deudas.Where(d => d.FechaCreacion <= to.Value);

            var q = deudas
                .SelectMany(d => d.Detalles.Select(dd => new
                {
                    dd.ItemId,
                    dd.ItemNombre,
                    dd.Cantidad,
                    dd.PrecioUnitario
                }));

            var result = await q
                .GroupBy(x => new { x.ItemId, x.ItemNombre })
                .Select(g => new BestSellerDto
                {
                    ItemId = g.Key.ItemId ?? 0,
                    ItemNombre = g.Key.ItemNombre,
                    CantidadVendida = g.Sum(z => z.Cantidad),
                    MontoTotal = g.Sum(z => z.PrecioUnitario * z.Cantidad)
                })
                .OrderByDescending(r => r.CantidadVendida)
                .ThenByDescending(r => r.MontoTotal)
                .Take(top)
                .ToListAsync();

            return Ok(result);
        }

        [HttpGet("resumen")]
        public async Task<IActionResult> GetDashboardResumen(
            [FromQuery] int usuarioId,
            [FromQuery] DateTime? startDate,
            [FromQuery] DateTime? endDate)
        {
            var deudasQ = _context.Deudas
                .AsNoTracking()
                .Where(d => d.UsuarioId == usuarioId);

            if (startDate.HasValue) deudasQ = deudasQ.Where(d => d.FechaCreacion >= startDate.Value);
            if (endDate.HasValue) deudasQ = deudasQ.Where(d => d.FechaCreacion <= endDate.Value);

            var ventasTotales = await deudasQ.SumAsync(d => (decimal)d.Monto);

            var saldosQ =
                from d in _context.Deudas.AsNoTracking()
                where d.UsuarioId == usuarioId
                      && (!startDate.HasValue || d.FechaCreacion >= startDate.Value)
                      && (!endDate.HasValue || d.FechaCreacion <= endDate.Value)
                join p in _context.Pagos.AsNoTracking() on d.Id equals p.DeudaId into gp
                select new { Saldo = (decimal)d.Monto - gp.Sum(x => x.Monto) };

            var saldoPendiente = await saldosQ
                .Where(x => x.Saldo > 0m)
                .SumAsync(x => (decimal?)x.Saldo) ?? 0m;

            var detallesQ = _context.DeudaDetalles
                .AsNoTracking()
                .Include(dd => dd.Deuda)
                .Where(dd => dd.Deuda.UsuarioId == usuarioId);

            if (startDate.HasValue) detallesQ = detallesQ.Where(dd => dd.Deuda.FechaCreacion >= startDate.Value);
            if (endDate.HasValue) detallesQ = detallesQ.Where(dd => dd.Deuda.FechaCreacion <= endDate.Value);

            var top1 = await detallesQ
                .GroupBy(dd => new { dd.ItemId, dd.ItemNombre })
                .Select(g => new
                {
                    Nombre = g.Key.ItemNombre,
                    Cantidad = g.Sum(x => x.Cantidad),
                    Monto = g.Sum(x => x.PrecioUnitario * x.Cantidad)
                })
                .OrderByDescending(x => x.Cantidad)
                .ThenByDescending(x => x.Monto)
                .FirstOrDefaultAsync();

            var dto = new DashboardResumenDto
            {
                VentasTotales = ventasTotales,
                SaldoPendiente = saldoPendiente,
                TopItemNombre = top1?.Nombre,
                TopItemCantidad = top1?.Cantidad,
                TopItemMonto = top1?.Monto
            };

            return Ok(dto);
        }
    }
}
