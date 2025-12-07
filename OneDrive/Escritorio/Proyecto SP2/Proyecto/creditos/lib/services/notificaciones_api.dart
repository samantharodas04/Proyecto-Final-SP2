import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificacionesApi {
  static const String _baseUrl = 'http://10.0.2.2:5218'; // emulador Android, cambia si usas físico

  static Future<void> registrarPlayer({
    required int usuarioId,
    required String playerId,
  }) async {
    final url = Uri.parse('$_baseUrl/api/notificaciones/registrar-player');

    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'usuarioId': usuarioId,
        'playerId': playerId,
      }),
    );

    if (resp.statusCode >= 400) {
      throw Exception('Error al registrar playerId: ${resp.body}');
    }
  }
    // opcional, si quieres disparar recordatorios manualmente desde Flutter
  static Future<void> dispararGlobal() async {
    final url = Uri.parse('$_baseUrl/disparar-global');
    final resp = await http.post(url);
    if (resp.statusCode >= 400) {
      throw Exception(
          'Error dispararGlobal: ${resp.statusCode} - ${resp.body}');
    }
  }
}
  



