namespace CreditosApi.Models
{
    public class UsuarioNotificacion
    {
        public int Id { get; set; }
        public int UsuarioId { get; set; }
        public string PlayerId { get; set; } = "";
        public DateTime FechaRegistro { get; set; }
    }
}
