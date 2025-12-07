using Amazon;
using Amazon.Rekognition;
using Amazon.Rekognition.Model;
using Amazon.Runtime;

namespace CreditosApi.Services
{
    public class AwsRekognitionService
    {
        private readonly AmazonRekognitionClient _client;

        public AwsRekognitionService(IConfiguration config)
        {
            var creds = new BasicAWSCredentials(
                config["AWS:AccessKey"],
                config["AWS:SecretKey"]
            );

            _client = new AmazonRekognitionClient(creds, RegionEndpoint.USEast1);
        }

        // 👤 Comparar rostros entre selfie y foto DPI
        public async Task<bool> CompararRostros(byte[] selfie, byte[] dpiFoto)
        {
            var request = new CompareFacesRequest
            {
                SourceImage = new Image { Bytes = new MemoryStream(selfie) },
                TargetImage = new Image { Bytes = new MemoryStream(dpiFoto) },
                SimilarityThreshold = 85 // nivel mínimo de similitud
            };

            var response = await _client.CompareFacesAsync(request);
            return response.FaceMatches.Any();
        }

        // 🔍 Buscar el número de DPI dentro del texto que aparece en la foto del DPI
        public async Task<bool> ValidarTextoDpi(byte[] dpiFoto, string dpiIngresado)
        {
            var request = new DetectTextRequest
            {
                Image = new Image { Bytes = new MemoryStream(dpiFoto) }
            };

            var response = await _client.DetectTextAsync(request);

            return response.TextDetections
                .Any(t => t.DetectedText != null &&
                          t.DetectedText.Replace(" ", "").Contains(dpiIngresado.Replace(" ", "")));
        }
    }
}
