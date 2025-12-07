using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;
namespace CreditosApi.Config
{
    public class BlockchainSettings
    {
        public string RpcUrl { get; set; } = string.Empty;
        public string PrivateKey { get; set; } = string.Empty;
        public string ContractAddress { get; set; } = string.Empty;
    }
}
