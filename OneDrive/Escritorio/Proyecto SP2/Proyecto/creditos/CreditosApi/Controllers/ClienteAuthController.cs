using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CreditosApi.Data;
using CreditosApi.Services;

namespace CreditosApi.Controllers
{
    [ApiController]
    [Route("api/clientes-auth")]
    public class ClienteAuthController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly AwsRekognitionService _rekognition;

        public ClienteAuthController(AppDbContext context, AwsRekognitionService rekognition)
        {
            _context = context;
            _rekognition = rekognition;
        }

        // ======================= DTOs =======================

        public class ValidarClienteRequest
        {
            public string Dpi { get; set; } = string.Empty;
            public string Email { get; set; } = string.Empty;
        }

        public class ValidarClienteResponse
        {
            public bool Existe { get; set; }
            public int? ClienteId { get; set; }
            public string? Nombre { get; set; }
            public string? Mensaje { get; set; }
            public bool CuentaActiva { get; set; }
        }

        public class ActivarCuentaClienteRequest
        {
            public int ClienteId { get; set; }
            public string EmailLogin { get; set; } = string.Empty;
            public string Password { get; set; } = string.Empty;
        }

        public class LoginClienteRequest
        {
            public string Email { get; set; } = string.Empty;
            public string Password { get; set; } = string.Empty;
        }

        // ======================= Helpers =======================

        private static string HashPassword(string password)
        {
            using var sha = SHA256.Create();
            var bytes = Encoding.UTF8.GetBytes(password);
            var hash = sha.ComputeHash(bytes);
            return Convert.ToBase64String(hash);
        }

        // ======================= Endpoints =======================

        // ---------- Paso 1: validar DPI + correo ----------
        [HttpPost("validar")]
        public async Task<ActionResult<ValidarClienteResponse>> ValidarCliente([FromBody] ValidarClienteRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Dpi) || string.IsNullOrWhiteSpace(request.Email))
            {
                return BadRequest("DPI y Email son requeridos.");
            }

            var emailNorm = request.Email.Trim().ToLower();

            var cliente = await _context.Clientes
                .FirstOrDefaultAsync(c =>
                    c.Dpi == request.Dpi &&
                    c.Email != null &&
                    c.Email.ToLower() == emailNorm);

            if (cliente == null)
            {
                return Ok(new ValidarClienteResponse
                {
                    Existe = false,
                    Mensaje = "No coincide, intenta otra vez",
                    ClienteId = null,
                    Nombre = null,
                    CuentaActiva = false
                });
            }

            return Ok(new ValidarClienteResponse
            {
                Existe = true,
                ClienteId = cliente.Id,
                Nombre = cliente.Nombre,
                CuentaActiva = cliente.ClienteCuentaActiva
            });
        }

        // ---------- Paso 2: validar identidad (selfie + DPI) ----------
        [HttpPost("validar-identidad")]
        public async Task<IActionResult> ValidarIdentidad()
        {
            var form = await Request.ReadFormAsync();

            var dpiNumero = form["dpi"].ToString();
            var selfieFile = form.Files.GetFile("selfie");
            var dpiFile = form.Files.GetFile("dpiFoto");

            if (string.IsNullOrWhiteSpace(dpiNumero))
                return BadRequest("DPI es requerido.");

            if (selfieFile == null || dpiFile == null)
                return BadRequest("Selfie y foto de DPI son requeridas.");

            using var msSelfie = new MemoryStream();
            using var msDpi = new MemoryStream();

            await selfieFile.CopyToAsync(msSelfie);
            await dpiFile.CopyToAsync(msDpi);

            var selfieBytes = msSelfie.ToArray();
            var dpiBytes = msDpi.ToArray();

            var rostroCoincide = await _rekognition.CompararRostros(selfieBytes, dpiBytes);
            var dpiCoincide = await _rekognition.ValidarTextoDpi(dpiBytes, dpiNumero);

            return Ok(new
            {
                ok = rostroCoincide && dpiCoincide,
                rostroCoincide,
                dpiCoincide
            });
        }

        // ---------- Paso 3: activar cuenta ----------
        [HttpPost("activar-cuenta")]
        public async Task<IActionResult> ActivarCuenta([FromBody] ActivarCuentaClienteRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.EmailLogin) ||
                string.IsNullOrWhiteSpace(request.Password))
            {
                return BadRequest("Email y contraseña son requeridos.");
            }

            var cliente = await _context.Clientes
                .FirstOrDefaultAsync(c => c.Id == request.ClienteId);

            if (cliente == null)
                return NotFound("Cliente no encontrado.");

            if (cliente.ClienteCuentaActiva)
            {
                return BadRequest("Esta cuenta de cliente ya está activada.");
            }

            // El correo de login debe coincidir con el correo registrado
            if (cliente.Email == null ||
                !cliente.Email.Equals(request.EmailLogin.Trim(), StringComparison.OrdinalIgnoreCase))
            {
                return BadRequest("El correo para inicio de sesión debe coincidir con el registrado en la tienda.");
            }

            cliente.ClienteEmailLogin = request.EmailLogin.Trim();
            cliente.ClientePasswordHash = HashPassword(request.Password);
            cliente.ClienteCuentaActiva = true;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                ok = true,
                message = "Cuenta de cliente activada correctamente."
            });
        }

        // ---------- Login de cliente ----------
        [HttpPost("login-cliente")]
        public async Task<IActionResult> LoginCliente([FromBody] LoginClienteRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Email) ||
                string.IsNullOrWhiteSpace(request.Password))
            {
                return BadRequest(new { ok = false, message = "Email y contraseña son requeridos." });
            }

            var emailNorm = request.Email.Trim().ToLower();
            var passwordHash = HashPassword(request.Password);

            var cliente = await _context.Clientes
                .FirstOrDefaultAsync(c =>
                    c.ClienteEmailLogin != null &&
                    c.ClienteEmailLogin.ToLower() == emailNorm);

            if (cliente == null || !cliente.ClienteCuentaActiva)
            {
                return Unauthorized(new
                {
                    ok = false,
                    message = "Credenciales inválidas o cuenta no activa."
                });
            }

            if (!string.Equals(cliente.ClientePasswordHash, passwordHash, StringComparison.Ordinal))
            {
                return Unauthorized(new
                {
                    ok = false,
                    message = "Correo o contraseña incorrectos."
                });
            }

            return Ok(new
            {
                ok = true,
                message = "Login de cliente exitoso.",
                clienteId = cliente.Id,
                nombre = cliente.Nombre,
                dpi = cliente.Dpi   // 👈 aquí mandamos el DPI
            });
        }
    }
}
