using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CreditosApi.Data;
using CreditosApi.Models;

namespace CreditosApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ItemsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ItemsController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/items/{usuarioId}
        [HttpGet("{usuarioId}")]
        public async Task<ActionResult<IEnumerable<Item>>> GetItems(int usuarioId)
        {
            return await _context.Items
                .Where(i => i.UsuarioId == usuarioId)
                .ToListAsync();
        }

        // POST: api/items
        [HttpPost]
        public async Task<ActionResult<Item>> Crear(Item item)
        {
            _context.Items.Add(item);
            await _context.SaveChangesAsync();
            return Ok(item);
        }

        // PUT: api/items/{id}
        // 🔹 Actualizar item
        [HttpPut("{id}")]
        public async Task<IActionResult> Actualizar(int id, [FromBody] Item item)
        {
            Console.WriteLine("📥 Recibido en backend:");
            Console.WriteLine($"Id: {item.Id}");
            Console.WriteLine($"Nombre: {item.Nombre}");
            Console.WriteLine($"Descripcion: {item.Descripcion}");
            Console.WriteLine($"Precio: {item.Precio}");
            Console.WriteLine($"UsuarioId: {item.UsuarioId}");
            Console.WriteLine($"Foto: {(string.IsNullOrEmpty(item.Foto) ? "Sin foto" : "Con foto")}");

            var existente = await _context.Items.FirstOrDefaultAsync(i => i.Id == id);
            if (existente == null) return NotFound("Item no encontrado");

            existente.Nombre = item.Nombre;
            existente.Descripcion = item.Descripcion;
            existente.Precio = item.Precio;
            existente.Foto = item.Foto; // 👈 actualizar foto base64 si viene

            await _context.SaveChangesAsync();

            return Ok(new { message = "Item actualizado correctamente" });
        }




        // DELETE: api/items/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var item = await _context.Items.FindAsync(id);
            if (item == null) return NotFound();

            // 👇 soft delete
            item.IsActivo = false;
            item.DeletedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return NoContent();
        }
    }
}
