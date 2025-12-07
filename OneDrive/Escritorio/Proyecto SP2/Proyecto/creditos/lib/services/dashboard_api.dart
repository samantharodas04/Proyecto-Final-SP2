// lib/services/dashboard_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardApi {
  // Ajusta el host/puerto si tu API cambia
  static const String _baseUrl = "http://10.0.2.2:5218/api/dashboard";

  /// Nuevo: obtiene el resumen del dashboard
  /// Endpoint esperado: GET /api/dashboard/resumen?usuarioId=123&from=YYYY-MM-DD&to=YYYY-MM-DD
  static Future<Map<String, dynamic>> getResumen({
    required int usuarioId,
    DateTime? from,
    DateTime? to,
  }) async {
    final params = <String, String>{
      "usuarioId": "$usuarioId",
      if (from != null) "from": _fmtDate(from),
      if (to != null) "to": _fmtDate(to),
    };

    final uri = Uri.parse("$_baseUrl/resumen").replace(queryParameters: params);
    final resp = await http
        .get(uri, headers: {"Content-Type": "application/json"})
        .timeout(const Duration(seconds: 12));

    if (resp.statusCode != 200) {
      throw Exception(
          "Error al obtener dashboard (${resp.statusCode}): ${resp.body}");
    }

    final decoded = jsonDecode(resp.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return Map<String, dynamic>.from(decoded as Map);
  }

  /// Alias por compatibilidad con llamados previos que usaban getData(...)
  static Future<Map<String, dynamic>> getData({
    required int usuarioId,
    DateTime? from,
    DateTime? to,
  }) {
    return getResumen(usuarioId: usuarioId, from: from, to: to);
  }

  /// Formatea solo la parte de fecha (YYYY-MM-DD)
  static String _fmtDate(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-"
      "${d.month.toString().padLeft(2, '0')}-"
      "${d.day.toString().padLeft(2, '0')}";
}
