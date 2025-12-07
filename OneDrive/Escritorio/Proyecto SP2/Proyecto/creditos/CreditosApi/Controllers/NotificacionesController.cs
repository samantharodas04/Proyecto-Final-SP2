using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CreditosApi.Data;
using CreditosApi.Models;
using CreditosApi.Services;

namespace CreditosApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class NotificacionesController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly NotificacionesService _notiService;

        public NotificacionesController(AppDbContext context, NotificacionesService notiService)
        {
            _context = context;
            _notiService = notiService;
        }

        public class RegistrarPlayerDto
        {
            public int UsuarioId { get; set; }
            public string PlayerId { get; set; } = "";
        }

        [HttpPost("registrar-player")]
        public async Task<IActionResult> RegistrarPlayer([FromBody] RegistrarPlayerDto dto)
        {
            if (string.IsNullOrWhiteSpace(dto.PlayerId))
                return BadRequest("PlayerId requerido.");

            var entity = new UsuarioNotificacion
            {
                UsuarioId = dto.UsuarioId,
                PlayerId = dto.PlayerId,
                FechaRegistro = DateTime.Now
            };

            _context.UsuarioNotificaciones.Add(entity);
            await _context.SaveChangesAsync();

            return Ok(new { ok = true });
        }

        // opcional: disparar manualmente
        [HttpPost("disparar-global")]
        public async Task<IActionResult> DispararGlobal()
        {
            await _notiService.EjecutarRecordatoriosGlobales();
            return Ok(new { ok = true });
        }
    }
}
