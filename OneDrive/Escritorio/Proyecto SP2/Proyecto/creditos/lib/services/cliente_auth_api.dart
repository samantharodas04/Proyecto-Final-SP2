import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ClienteAuthApi {
  static const String baseUrl = 'http://10.0.2.2:5218';

  // -------- Paso 1: validar DPI + email --------
  static Future<Map<String, dynamic>> validarCliente({
    required String dpi,
    required String email,
  }) async {
    final uri = Uri.parse('$baseUrl/api/clientes-auth/validar');

    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'dpi': dpi, 'email': email}),
    );

    if (resp.statusCode != 200) {
      throw Exception('Error ${resp.statusCode}: ${resp.body}');
    }

    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // -------- Paso 2: validar identidad con AWS --------
  static Future<Map<String, dynamic>> validarIdentidad({
    required String dpi,
    required XFile selfie,
    required XFile dpiFoto,
  }) async {
    final uri = Uri.parse('$baseUrl/api/clientes-auth/validar-identidad');

    final request = http.MultipartRequest('POST', uri)
      ..fields['dpi'] = dpi
      ..files.add(await http.MultipartFile.fromPath('selfie', selfie.path))
      ..files.add(await http.MultipartFile.fromPath('dpiFoto', dpiFoto.path));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw Exception('Error ${streamed.statusCode}: $body');
    }

    return jsonDecode(body) as Map<String, dynamic>;
  }

  // -------- Paso 3: activar cuenta --------
  static Future<String?> activarCuentaCliente({
    required int clienteId,
    required String emailLogin,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/clientes-auth/activar-cuenta');

    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'clienteId': clienteId,
        'emailLogin': emailLogin,
        'password': password,
      }),
    );

    if (resp.statusCode == 200) return null;

    try {
      final json = jsonDecode(resp.body);
      if (json is Map && json['message'] is String) {
        return json['message'] as String;
      }
    } catch (_) {}

    return 'Error ${resp.statusCode}: ${resp.body}';
  }

  // -------- Login de cliente --------
  static Future<Map<String, dynamic>> loginCliente({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/clientes-auth/login-cliente');

    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (resp.statusCode != 200) {
      throw Exception('Error ${resp.statusCode}: ${resp.body}');
    }

    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}
