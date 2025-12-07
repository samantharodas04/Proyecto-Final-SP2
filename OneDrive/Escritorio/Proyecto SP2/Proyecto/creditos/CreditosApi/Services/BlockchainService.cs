using System;
using System.Numerics;
using System.Threading.Tasks;
using CreditosApi.Config;
using CreditosApi.Models;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Nethereum.Hex.HexTypes;
using Nethereum.Web3;
using Nethereum.Web3.Accounts;

namespace CreditosApi.Services
{
    public class BlockchainService
    {
        private readonly BlockchainSettings _settings;
        private readonly Web3 _web3;
        private readonly ILogger<BlockchainService> _logger;
        private readonly string _accountAddress;

        // ABI mínimo con tus 3 funciones del contrato CreditosChain
        private const string ContractAbi = @"
[
  {
    ""inputs"": [
      { ""internalType"": ""uint256"", ""name"": ""deudaId"", ""type"": ""uint256"" },
      { ""internalType"": ""uint256"", ""name"": ""clienteId"", ""type"": ""uint256"" },
      { ""internalType"": ""uint256"", ""name"": ""montoCents"", ""type"": ""uint256"" },
      { ""internalType"": ""uint256"", ""name"": ""fechaLimite"", ""type"": ""uint256"" }
    ],
    ""name"": ""registrarDeuda"",
    ""outputs"": [],
    ""stateMutability"": ""nonpayable"",
    ""type"": ""function""
  },
  {
    ""inputs"": [
      { ""internalType"": ""uint256"", ""name"": ""deudaId"", ""type"": ""uint256"" },
      { ""internalType"": ""uint256"", ""name"": ""pagoId"", ""type"": ""uint256"" },
      { ""internalType"": ""uint256"", ""name"": ""montoCents"", ""type"": ""uint256"" }
    ],
    ""name"": ""registrarPago"",
    ""outputs"": [],
    ""stateMutability"": ""nonpayable"",
    ""type"": ""function""
  },
  {
    ""inputs"": [
      { ""internalType"": ""uint256"", ""name"": ""deudaId"", ""type"": ""uint256"" }
    ],
    ""name"": ""obtenerMontoDeuda"",
    ""outputs"": [
      { ""internalType"": ""uint256"", ""name"": ""montoCents"", ""type"": ""uint256"" }
    ],
    ""stateMutability"": ""view"",
    ""type"": ""function""
  }
]
";

        public BlockchainService(
            IOptions<BlockchainSettings> options,
            ILogger<BlockchainService> logger)
        {
            _settings = options.Value;
            _logger = logger;

            if (string.IsNullOrWhiteSpace(_settings.RpcUrl))
                throw new InvalidOperationException("Blockchain:RpcUrl no está configurado.");

            if (string.IsNullOrWhiteSpace(_settings.PrivateKey))
                throw new InvalidOperationException("Blockchain:PrivateKey no está configurado.");

            if (string.IsNullOrWhiteSpace(_settings.ContractAddress))
                throw new InvalidOperationException("Blockchain:ContractAddress no está configurado.");

            var account = new Account(_settings.PrivateKey);
            _accountAddress = account.Address;
            _web3 = new Web3(account, _settings.RpcUrl);

            _logger.LogInformation(
                "BlockchainService inicializado. Address: {address}, RPC: {rpc}",
                account.Address,
                _settings.RpcUrl
            );
        }

        // =========================================================
        // REGISTRAR DEUDA EN LA BLOCKCHAIN
        // =========================================================
        public async Task<string?> RegistrarDeudaOnChainAsync(Deuda deuda)
        {
            try
            {
                if (deuda == null)
                {
                    _logger.LogWarning("RegistrarDeudaOnChainAsync recibió una deuda nula.");
                    return null;
                }

                var contract = _web3.Eth.GetContract(ContractAbi, _settings.ContractAddress);
                var function = contract.GetFunction("registrarDeuda");

                // monto -> centavos
                var montoDecimal = (decimal)deuda.Monto;
                if (montoDecimal < 0)
                {
                    _logger.LogWarning("Monto de deuda negativo. DeudaId={Id}, Monto={Monto}",
                        deuda.Id, montoDecimal);
                    return null;
                }

                var montoCents = new BigInteger(montoDecimal * 100m);

                // Fecha límite -> Unix time
                DateTime fechaLimite = deuda.FechaLimite;
                if (fechaLimite.Kind == DateTimeKind.Unspecified)
                {
                    // asumimos UTC para evitar problemas
                    fechaLimite = DateTime.SpecifyKind(fechaLimite, DateTimeKind.Utc);
                }

                var fechaLimiteUnix = new BigInteger(
                    new DateTimeOffset(fechaLimite).ToUnixTimeSeconds()
                );

                var txHash = await function.SendTransactionAsync(
                    from: _accountAddress,
                    gas: new HexBigInteger(300000),
                    value: null,
                    functionInput: new object[]
                    {
                        (BigInteger)deuda.Id,
                        (BigInteger)deuda.ClienteId,
                        montoCents,
                        fechaLimiteUnix
                    });

                _logger.LogInformation(
                    "Tx registrarDeuda enviada. DeudaId={DeudaId}, ClienteId={ClienteId}, Hash={Hash}",
                    deuda.Id,
                    deuda.ClienteId,
                    txHash
                );

                return txHash;
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "Error al registrar deuda on-chain. DeudaId={DeudaId}, ClienteId={ClienteId}",
                    deuda?.Id,
                    deuda?.ClienteId
                );
                return null;
            }
        }

        // =========================================================
        // REGISTRAR PAGO EN LA BLOCKCHAIN
        // =========================================================
        public async Task<string?> RegistrarPagoOnChainAsync(Deuda deuda, Pago pago)
        {
            try
            {
                if (deuda == null || pago == null)
                {
                    _logger.LogWarning(
                        "RegistrarPagoOnChainAsync recibió deuda o pago nulos. Deuda={DeudaNull}, Pago={PagoNull}",
                        deuda == null, pago == null
                    );
                    return null;
                }

                var contract = _web3.Eth.GetContract(ContractAbi, _settings.ContractAddress);
                var function = contract.GetFunction("registrarPago");

                var montoDecimal = pago.Monto;
                if (montoDecimal < 0)
                {
                    _logger.LogWarning("Monto de pago negativo. PagoId={PagoId}, Monto={Monto}",
                        pago.Id, montoDecimal);
                    return null;
                }

                var montoCents = new BigInteger(montoDecimal * 100m);

                var txHash = await function.SendTransactionAsync(
                    from: _accountAddress,
                    gas: new HexBigInteger(300000),
                    value: null,
                    functionInput: new object[]
                    {
                        (BigInteger)deuda.Id,
                        (BigInteger)pago.Id,
                        montoCents
                    });

                _logger.LogInformation(
                    "Tx registrarPago enviada. DeudaId={DeudaId}, PagoId={PagoId}, Hash={Hash}",
                    deuda.Id,
                    pago.Id,
                    txHash
                );

                return txHash;
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "Error al registrar pago on-chain. DeudaId={DeudaId}, PagoId={PagoId}",
                    deuda?.Id,
                    pago?.Id
                );
                return null;
            }
        }

        // =========================================================
        // CONSULTA (VIEW): OBTENER MONTO ON-CHAIN
        // =========================================================
        public async Task<decimal?> ObtenerMontoOnChainAsync(int deudaId)
        {
            try
            {
                var contract = _web3.Eth.GetContract(ContractAbi, _settings.ContractAddress);
                var function = contract.GetFunction("obtenerMontoDeuda");

                var result = await function.CallAsync<BigInteger>((BigInteger)deudaId);

                var montoDecimal = (decimal)result / 100m;
                _logger.LogInformation(
                    "Monto on-chain consultado. DeudaId={DeudaId}, MontoCents={Cents}, Monto={Monto}",
                    deudaId,
                    result,
                    montoDecimal
                );

                return montoDecimal;
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "Error al leer monto on-chain. DeudaId={DeudaId}",
                    deudaId
                );
                return null;
            }
        }
    }
}
