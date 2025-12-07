import 'dart:convert';
import 'package:http/http.dart' as http;

class ItemsApi {
  static const String baseUrl = "http://10.0.2.2:5218/api/items";

  // 🔹 Listar items de un usuario
  static Future<List<Map<String, dynamic>>> listar(int usuarioId) async {
    final response = await http.get(Uri.parse("$baseUrl/$usuarioId"));

    if (response.statusCode == 200) {
      if (response.body.isEmpty) return [];
      final data = jsonDecode(response.body) as List;
      return data.map((i) => Map<String, dynamic>.from(i)).toList();
    } else {
      throw Exception("Error al listar items: ${response.body}");
    }
  }

  // 🔹 Crear item
  static Future<String?> crear({
    required String nombre,
    String? descripcion,
    required double precio,
    String? fotoBase64, // 👈 se manda la foto en base64
    required int usuarioId,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nombre": nombre,
        "descripcion": descripcion,
        "precio": precio,
        "foto": fotoBase64, // 👈 foto en base64
        "usuarioId": usuarioId,
      }),
    );

    if (response.statusCode == 200) return null;
    return response.body;
  }

  // 🔹 Actualizar item
  static Future<void> actualizar({
  required int id,
  required String nombre,
  required String descripcion,
  required double precio,
  String? fotoBase64,
  required int usuarioId,
}) async {
  final body = {
    "id": id,
    "nombre": nombre,
    "descripcion": descripcion,
    "precio": precio,
    "foto": fotoBase64,
    "usuarioId": usuarioId,
  };

  final resp = await http.put(
    Uri.parse("http://10.0.2.2:5218/api/Items/$id"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(body),
  );

  if (resp.statusCode != 200) {
    throw Exception("Error al actualizar item: ${resp.body}");
  }
}


  // 🔹 Eliminar item (acepta 200..299 como éxito)
  static Future<String?> eliminar(int id) async {
    final resp = await http.delete(Uri.parse("$baseUrl/$id"));

    // Éxito para cualquier 2xx (200, 204, etc)
    if (resp.statusCode >= 200 && resp.statusCode < 300) return null;

    // Si viene sin body, al menos devuelve el código
    if ((resp.body).isEmpty) return "Error ${resp.statusCode}";
    return resp.body;
  }

  
}
