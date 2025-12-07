using Microsoft.EntityFrameworkCore;
using CreditosApi.Models;

namespace CreditosApi.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<Usuario> Usuarios { get; set; }
        public DbSet<Cliente> Clientes { get; set; }
        public DbSet<Item> Items { get; set; }
        public DbSet<Deuda> Deudas { get; set; }
        public DbSet<DeudaDetalle> DeudaDetalles { get; set; }
        public DbSet<Pago> Pagos { get; set; }  // 👈 nueva entidad
        public DbSet<Venta> Ventas { get; set; }
        public DbSet<VentaDetalle> VentaDetalles { get; set; }
        public DbSet<UsuarioNotificacion> UsuarioNotificaciones { get; set; }
        public DbSet<BlockchainLog> BlockchainLogs { get; set; }
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            base.OnModelCreating(modelBuilder);
            modelBuilder.Entity<Venta>()
                .Property(v => v.Total)
                .HasPrecision(18, 2);

            modelBuilder.Entity<VentaDetalle>()
                .Property(v => v.PrecioUnitario)
                .HasPrecision(18, 2);

            modelBuilder.Entity<UsuarioNotificacion>(e =>
            {
                e.Property(p => p.FechaRegistro)
                .HasColumnType("datetime2")
                .HasDefaultValueSql("SYSUTCDATETIME()");
            });
            
             // Venta
            modelBuilder.Entity<Venta>()
                .HasOne(v => v.Usuario)
                .WithMany()
                .HasForeignKey(v => v.UsuarioId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Venta>()
                .HasOne(v => v.Cliente)
                .WithMany()
                .HasForeignKey(v => v.ClienteId)
                .OnDelete(DeleteBehavior.Restrict);

            // VentaDetalle
            modelBuilder.Entity<VentaDetalle>()
                .HasOne(d => d.Venta)
                .WithMany(v => v.Detalles)
                .HasForeignKey(d => d.VentaId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<VentaDetalle>()
                .HasOne(d => d.Item)
                .WithMany()
                .HasForeignKey(d => d.ItemId)
                .OnDelete(DeleteBehavior.SetNull);

            // Índices útiles
            modelBuilder.Entity<Venta>()
                .HasIndex(v => new { v.UsuarioId, v.Fecha });

            modelBuilder.Entity<Item>()
                .Property(i => i.Stock)
                .HasDefaultValue(0);

            modelBuilder.Entity<Pago>(b =>
            {
                b.ToTable("Pagos");
                b.Property(p => p.Monto).HasColumnType("decimal(10,2)");
                b.HasOne(p => p.Deuda)
                .WithMany(d => d.Pagos)       // 👈 agrega la colección en Deuda
                .HasForeignKey(p => p.DeudaId)
                .OnDelete(DeleteBehavior.Cascade);
            });


            // 🔒 Soft-delete en Items
            modelBuilder.Entity<Item>()
                .HasQueryFilter(i => i.IsActivo); // todos los queries ignoran items borrados

            // 🧾 Tabla y relaciones de DeudaDetalle
            modelBuilder.Entity<DeudaDetalle>().ToTable("DeudaDetalle");

            modelBuilder.Entity<DeudaDetalle>()
                .HasOne(dd => dd.Deuda)
                .WithMany(d => d.Detalles)
                .HasForeignKey(dd => dd.DeudaId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<DeudaDetalle>()
                .HasOne(dd => dd.Item)
                .WithMany() // sin navegación inversa
                .HasForeignKey(dd => dd.ItemId)
                .OnDelete(DeleteBehavior.SetNull); // 👈 si borras el item, queda null
            // 🔹 Configuración Usuario
            modelBuilder.Entity<Usuario>()
                .Property(u => u.Dpi)
                .HasColumnName("dpi"); // 👈 fuerza el nombre real en BD

            modelBuilder.Entity<Usuario>()
                .HasIndex(u => u.Email)
                .IsUnique();

            modelBuilder.Entity<Usuario>()
                .HasIndex(u => u.Dpi)
                .IsUnique();

            // 🔹 Configuración Cliente
            modelBuilder.Entity<Cliente>()
                .HasIndex(c => new { c.UsuarioId, c.Dpi })
                .IsUnique(); // 👈 DPI único solo dentro de cada usuario

            modelBuilder.Entity<Cliente>()
                .HasOne(c => c.Usuario)
                .WithMany(u => u.Clientes) // ✅ relación 1 Usuario -> N Clientes
                .HasForeignKey(c => c.UsuarioId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Cliente>()
                .Property(c => c.Nombre)
                .HasMaxLength(200)
                .IsRequired();

            modelBuilder.Entity<Cliente>()
                .Property(c => c.Email)
                .HasMaxLength(200);

            modelBuilder.Entity<Cliente>()
                .Property(c => c.Telefono)
                .HasMaxLength(20);

            modelBuilder.Entity<Cliente>()
                .Property(c => c.FechaRegistro)
                .HasDefaultValueSql("GETDATE()");

            // 🔹 Configuración Item
            modelBuilder.Entity<Item>()
                .Property(i => i.Nombre)
                .HasMaxLength(200)
                .IsRequired();

            modelBuilder.Entity<Item>()
                .Property(i => i.Descripcion)
                .HasMaxLength(500);

            modelBuilder.Entity<Item>()
                .Property(i => i.Foto).HasColumnType("nvarchar(max)");

            modelBuilder.Entity<Item>()
                .Property(i => i.Precio)
                .HasColumnType("decimal(10,2)")
                .IsRequired();

            modelBuilder.Entity<Item>()
                .Property(i => i.FechaRegistro)
                .HasDefaultValueSql("GETDATE()");

            //Deudas
            // 🔹 Relación Deuda -> Usuario
            modelBuilder.Entity<Deuda>()
                .HasOne(d => d.Usuario)
                .WithMany()
                .HasForeignKey(d => d.UsuarioId)
                .OnDelete(DeleteBehavior.Cascade);

            // Relación Cliente → Deudas
            modelBuilder.Entity<Deuda>()
                .HasOne(d => d.Cliente)
                .WithMany()
                .HasForeignKey(d => d.ClienteId)
                .OnDelete(DeleteBehavior.Restrict); // 👈 evita cascade conflict

            // Relación Usuario → Deudas
            modelBuilder.Entity<Deuda>()
                .HasOne(d => d.Usuario)
                .WithMany()
                .HasForeignKey(d => d.UsuarioId)
                .OnDelete(DeleteBehavior.Restrict);

            // 🔹 Relación 1 Usuario -> N Items
            modelBuilder.Entity<Item>()
            .HasOne(i => i.Usuario)
            .WithMany(u => u.Items)
            .HasForeignKey(i => i.UsuarioId)
            .OnDelete(DeleteBehavior.Cascade);
        // 🔗 NUEVO: configuración de BlockchainLog
            modelBuilder.Entity<BlockchainLog>(b =>
            {
                b.ToTable("BlockchainLogs");
                b.HasKey(x => x.Id);

                b.Property(x => x.Tipo)
                    .HasMaxLength(50)
                    .IsRequired();

                b.Property(x => x.TxHash)
                    .HasMaxLength(200);

                b.Property(x => x.Error)
                    .HasColumnType("nvarchar(max)");

                b.Property(x => x.Fecha)
                    .HasColumnType("datetime2");
            });
        }
    }
}