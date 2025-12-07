using System.Xml.Serialization;
using CreditosApi.Data;
using CreditosApi.Services; // donde esté NotificacionesService y RecordatorioBackgroundService
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using CreditosApi.Config;

var builder = WebApplication.CreateBuilder(args);


// ---------- DB ----------
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// ---------- CORS ----------
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", p =>
        p.AllowAnyOrigin()
         .AllowAnyHeader()
         .AllowAnyMethod());
});

// ---------- Blockchain ----------
builder.Services.Configure<BlockchainSettings>(
    builder.Configuration.GetSection("Blockchain"));
builder.Services.AddScoped<BlockchainService>();
// ---------- Controllers ----------
builder.Services.AddControllers();

builder.Services.AddScoped<AwsRekognitionService>();

// ---------- Swagger (opcional) ----------
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// ---------- OneSignal / Notificaciones ----------
builder.Services.AddHttpClient<NotificacionesService>();
builder.Services.AddScoped<NotificacionesService>();

// 🔁 Servicio en segundo plano para recordatorios automáticos
builder.Services.AddHostedService<RecordatorioBackgroundService>();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowAll");

app.UseHttpsRedirection();
app.UseAuthorization();

app.MapControllers();

app.Run();
