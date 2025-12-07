import 'dart:convert';
import 'package:http/http.dart' as http;

class ClienteDeudasApi {
  static const String baseUrl = 'http://10.0.2.2:5218';

  // Lista de deudas del cliente
  static Future<List<dynamic>> getDeudasCliente(int clienteId) async {
    // Usa el MISMO path que tu app de tendero
    final uri = Uri.parse('$baseUrl/api/deudas/cliente/$clienteId');

    final resp = await http.get(uri);

    if (resp.statusCode != 200) {
      throw Exception('Error ${resp.statusCode}: ${resp.body}');
    }

    return jsonDecode(resp.body) as List<dynamic>;
  }

  // Historial de pagos de una deuda
  static Future<List<dynamic>> getPagosDeuda(int deudaId) async {
    final uri = Uri.parse('$baseUrl/api/deudas/$deudaId/pagos');

    final resp = await http.get(uri);

    if (resp.statusCode != 200) {
      throw Exception('Error ${resp.statusCode}: ${resp.body}');
    }

    return jsonDecode(resp.body) as List<dynamic>;
  }
}
