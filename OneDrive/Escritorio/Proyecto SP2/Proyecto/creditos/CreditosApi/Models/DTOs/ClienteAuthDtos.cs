using System;
using System.Collections.Generic;

public class ValidarClienteRequest
{
    public string Dpi { get; set; } = null!;
    public string Email { get; set; } = null!;
}

public class ValidarClienteResponse
{
    public bool Existe { get; set; }
    public int? ClienteId { get; set; }
    public string? Nombre { get; set; }
    public bool CuentaActiva { get; set; } 
}

public class ActivarCuentaClienteRequest
{
    public int ClienteId { get; set; }
    public string EmailLogin { get; set; } = null!;
    public string Password { get; set; } = null!;
}

public class ValidarSelfieDpiRequest
    {
        public int ClienteId { get; set; }
        public string DpiNumero { get; set; } = string.Empty;
        public string SelfieBase64 { get; set; } = string.Empty;
        public string DpiBase64 { get; set; } = string.Empty;
    }

    public class ValidarSelfieDpiResponse
    {
        public bool EsValido { get; set; }
        public string Mensaje { get; set; } = string.Empty;
    }