import 'dart:convert';
import 'package:http/http.dart' as http;

class ClientesApi {
  static const String baseUrl = "http://10.0.2.2:5218/api/clientes";

  // Listar clientes de un usuario
  static Future<List<Map<String, dynamic>>> listar(int usuarioId) async {
    final resp = await http
        .get(Uri.parse("$baseUrl/$usuarioId"))
        .timeout(const Duration(seconds: 12));

    if (resp.statusCode == 200) {
      if (resp.body.isEmpty) return [];
      final data = jsonDecode(resp.body) as List;
      return data.map((c) => Map<String, dynamic>.from(c)).toList();
    } else {
      throw Exception("Error al listar clientes (${resp.statusCode}): ${resp.body}");
    }
  }

  // Crear cliente
  static Future<String?> crear({
    required String dpi,
    required String nombre,
    String? email,
    String? telefono,
    required int usuarioId,
  }) async {
    final resp = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "dpi": dpi,
        "nombre": nombre,
        "email": email,
        "telefono": telefono,
        "usuarioId": usuarioId,
      }),
    );

    if (resp.statusCode == 200) return null;
    return resp.body;
  }

  // Actualizar cliente
  static Future<String?> actualizar({
    required int id,
    required String dpi,
    required String nombre,
    String? email,
    String? telefono,
    required int usuarioId,
  }) async {
    final resp = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id": id,
        "dpi": dpi,
        "nombre": nombre,
        "email": email,
        "telefono": telefono,
        "usuarioId": usuarioId,
      }),
    );

    if (resp.statusCode == 200) return null;
    return resp.body;
  }

  // Eliminar cliente
  static Future<String?> eliminar(int id) async {
    final resp = await http.delete(Uri.parse("$baseUrl/$id"));
    if (resp.statusCode == 200) return null;
    return resp.body;
  }

  // Score crediticio por cliente/usuario
  // GET /api/clientes/{clienteId}/score?usuarioId=123
  static Future<Map<String, dynamic>> score({
    required int clienteId,
    required int usuarioId,
  }) async {
    final uri = Uri.parse("$baseUrl/$clienteId/score?usuarioId=$usuarioId");
    final resp = await http
        .get(uri, headers: {"Content-Type": "application/json"})
        .timeout(const Duration(seconds: 12));

    if (resp.statusCode != 200) {
      throw Exception("Error al obtener score (${resp.statusCode}): ${resp.body}");
    }

    final decoded = jsonDecode(resp.body);
    return decoded is Map<String, dynamic>
        ? decoded
        : Map<String, dynamic>.from(decoded as Map);
  }
}
