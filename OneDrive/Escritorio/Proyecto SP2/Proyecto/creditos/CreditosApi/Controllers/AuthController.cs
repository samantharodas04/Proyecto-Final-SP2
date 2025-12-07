using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CreditosApi.Data;
using CreditosApi.Models;

namespace CreditosApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _context;

        public AuthController(AppDbContext context)
        {
            _context = context;
        }

        // 🔹 Registro
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] Usuario usuario)
        {
            // Validar email único
            if (await _context.Usuarios.AnyAsync(u => u.Email == usuario.Email))
                return Conflict("El correo ya está registrado");

            // Validar DPI único
            if (await _context.Usuarios.AnyAsync(u => u.Dpi == usuario.Dpi))
                return Conflict("El DPI ya está registrado");

            // Hash de contraseña
            usuario.Password = BCrypt.Net.BCrypt.HashPassword(usuario.Password);

            // Fecha de registro
            usuario.FechaRegistro = DateTime.Now;

            _context.Usuarios.Add(usuario);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Usuario registrado correctamente" });
        }

        // 🔹 Login
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] Usuario login)
        {
            var user = await _context.Usuarios
                .FirstOrDefaultAsync(u => u.Email == login.Email);

            if (user == null)
                return Unauthorized("Correo o contraseña incorrectos");

            // ✅ Comparar hash usando BCrypt
            if (!BCrypt.Net.BCrypt.Verify(login.Password, user.Password))
                return Unauthorized("Correo o contraseña incorrectos");

            return Ok(new
            {
                message = "Login exitoso",
                usuario = new
                {
                    user.Id,
                    user.Nombre,
                    user.Apellido,
                    user.Email,
                    user.Dpi,
                    user.FechaRegistro
                }
            });
        }
    }
}
