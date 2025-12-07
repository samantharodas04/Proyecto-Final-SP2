// lib/services/ventas_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class VentasApi {
  static const String base = "http://10.0.2.2:5218/api";

  static Future<void> crear({
    required int usuarioId,
    int? clienteId,
    DateTime? fecha,
    required List<Map<String, int>> detalles, // [{itemId, cantidad}]
  }) async {
    final body = {
      "usuarioId": usuarioId,
      "clienteId": clienteId,
      "fecha": fecha?.toIso8601String(),
      "detalles": detalles.map((e) => {
        "itemId": e["itemId"],
        "cantidad": e["cantidad"],
      }).toList(),
    };

    final resp = await http.post(
      Uri.parse("$base/ventas"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (resp.statusCode != 200) {
      throw Exception("Error al crear venta: ${resp.body}");
    }
  }

  static Future<Map<String, dynamic>> resumen({
    required int usuarioId,
    DateTime? from,
    DateTime? to,
  }) async {
    final q = <String, String>{"usuarioId": "$usuarioId"};
    if (from != null) q["from"] = from.toIso8601String();
    if (to != null) q["to"] = to.toIso8601String();

    final uri = Uri.parse("$base/ventas/resumen").replace(queryParameters: q);
    final resp = await http.get(uri);

    if (resp.statusCode != 200) {
      throw Exception("Error al cargar resumen: ${resp.body}");
    }
    final d = jsonDecode(resp.body);
    return Map<String, dynamic>.from(d);
  }
}
