using System;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using CreditosApi.Data;

namespace CreditosApi.Services
{
    public class NotificacionesService
    {
        private readonly AppDbContext _context;
        private readonly HttpClient _http;
        private readonly ILogger<NotificacionesService> _logger;

        // ⚠ Tus credenciales de OneSignal
        private const string ONE_SIGNAL_APP_ID = "0f89ee35-077f-4411-a0b3-ad2ae2ff1997";
        private const string ONE_SIGNAL_REST_API_KEY = "os_v2_app_b6e64nihp5cbdiftvuvof7yzs6jk4r72yx3uczn2bb2jgiefeqk6xxm7gdlbvsipvzhljsaslp5vcccvcf3helbyso5fiyvrmvuiz2q";

        public NotificacionesService(
            AppDbContext context,
            HttpClient http,
            ILogger<NotificacionesService> logger)
        {
            _context = context;
            _http = http;
            _logger = logger;

            _http.DefaultRequestHeaders.Clear();
            _http.DefaultRequestHeaders.Add("Authorization", $"Basic {ONE_SIGNAL_REST_API_KEY}");
        }

        private async Task EnviarNotificacionUsuario(int usuarioId, string? mensaje)
        {
            var playerId = await _context.UsuarioNotificaciones
                .Where(x => x.UsuarioId == usuarioId)
                .OrderByDescending(x => x.Id)
                .Select(x => x.PlayerId)
                .FirstOrDefaultAsync();

            if (string.IsNullOrWhiteSpace(playerId))
            {
                _logger.LogInformation($"Usuario {usuarioId} sin playerId, no se notifica.");
                return;
            }

            var msg = string.IsNullOrWhiteSpace(mensaje)
                ? "You have overdue debts. Please review your charges today."
                : mensaje.Trim();

            var body = new
            {
                app_id = ONE_SIGNAL_APP_ID,
                include_player_ids = new[] { playerId },
                contents = new Dictionary<string, string>
                {
                    ["en"] = msg,
                    ["es"] = msg
                },
                headings = new Dictionary<string, string>
                {
                    ["en"] = "Recordatorio de cobro",
                    ["es"] = "Recordatorio de cobro"
                },
                priority = 10,
                ttl = 3600
            };

            try { _logger.LogInformation("OneSignal payload: {payload}", System.Text.Json.JsonSerializer.Serialize(body)); } catch { }

            var resp = await _http.PostAsJsonAsync("https://onesignal.com/api/v1/notifications", body);
            var txt = await resp.Content.ReadAsStringAsync();

            _logger.LogInformation($"Notif usuario {usuarioId}: status {resp.StatusCode}, resp {txt}");
        }

        private async Task ProcesarUsuario(int usuarioId)
        {
            var hoy = DateTime.Now.Date;

            // 🔹 Obtener nombre del usuario
            var usuario = await _context.Usuarios
                .AsNoTracking()
                .Where(u => u.Id == usuarioId)
                .Select(u => new { u.Nombre, u.Apellido })
                .FirstOrDefaultAsync();

            var nombreUsuario = usuario != null
                ? $"{usuario.Nombre} {usuario.Apellido}".Trim()
                : $"Usuario {usuarioId}";

            // 🔹 Deudas vencidas (fecha límite antes de hoy y saldo > 0)
            var deudasVencidas = await _context.Deudas
                .Where(d => d.UsuarioId == usuarioId && d.FechaLimite < hoy)
                .GroupJoin(
                    _context.Pagos,
                    d => d.Id,
                    p => p.DeudaId,
                    (d, pagos) => new
                    {
                        deuda = d,
                        totalPagos = pagos.Sum(p => p.Monto)
                    }
                )
                .Select(x => new
                {
                    saldo = (decimal)x.deuda.Monto - x.totalPagos
                })
                .Where(x => x.saldo > 0)
                .ToListAsync();

            var totalVencidas = deudasVencidas.Count;

            if (totalVencidas <= 0)
            {
                _logger.LogInformation($"Usuario {usuarioId} no tiene deudas vencidas. No se envía push.");
                return;
            }

            // 🔹 Mensaje personalizado con el nombre
            await EnviarNotificacionUsuario(
                usuarioId,
                $"{nombreUsuario}, tienes {totalVencidas} deudas vencidas. ¡No olvides cobrar hoy! 💸"
            );
        }

        public async Task EjecutarRecordatoriosGlobales()
        {
            _logger.LogInformation("⏰ EjecutarRecordatoriosGlobales corriendo...");

            var usuariosConNotificaciones = await _context.UsuarioNotificaciones
                .Select(un => un.UsuarioId)
                .Distinct()
                .ToListAsync();

            foreach (var uid in usuariosConNotificaciones)
            {
                try
                {
                    await ProcesarUsuario(uid);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, $"Error procesando usuario {uid}");
                }
            }
        }
    }
}
