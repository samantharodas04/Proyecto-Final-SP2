using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;

namespace CreditosApi.Services
{
    /// <summary>
    /// Servicio en segundo plano que periódicamente ejecuta
    /// NotificacionesService.EjecutarRecordatoriosGlobales()
    /// para enviar recordatorios de deudas pendientes.
    /// </summary>
    public class RecordatorioBackgroundService : BackgroundService
    {
        private readonly ILogger<RecordatorioBackgroundService> _logger;
        private readonly IServiceProvider _serviceProvider;

        // ⏱ Intervalo entre ejecuciones
        // Para pruebas: TimeSpan.FromMinutes(1)
        // En producción podrías usar: TimeSpan.FromHours(1)
        private readonly TimeSpan _intervalo = TimeSpan.FromMinutes(1);

        public RecordatorioBackgroundService(
            ILogger<RecordatorioBackgroundService> logger,
            IServiceProvider serviceProvider)
        {
            _logger = logger;
            _serviceProvider = serviceProvider;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("RecordatorioBackgroundService iniciado.");

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    _logger.LogInformation("Ejecutando recordatorios globales de deudas...");

                    // Creamos un scope para usar NotificacionesService (Scoped)
                    using (var scope = _serviceProvider.CreateScope())
                    {
                        var notiService = scope.ServiceProvider.GetRequiredService<NotificacionesService>();

                        // 👇 Este método debe revisar deudas próximas/vencidas
                        //    y enviar notificaciones con OneSignal.
                        await notiService.EjecutarRecordatoriosGlobales();
                    }

                    _logger.LogInformation("Recordatorios globales ejecutados correctamente.");
                }
                catch (TaskCanceledException)
                {
                    // Se está cerrando la app / servicio
                    break;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error al ejecutar los recordatorios globales.");
                }

                try
                {
                    _logger.LogInformation($"Esperando {_intervalo.TotalMinutes} minutos para la siguiente ejecución...");
                    await Task.Delay(_intervalo, stoppingToken);
                }
                catch (TaskCanceledException)
                {
                    break;
                }
            }

            _logger.LogInformation("RecordatorioBackgroundService detenido.");
        }
    }
}
