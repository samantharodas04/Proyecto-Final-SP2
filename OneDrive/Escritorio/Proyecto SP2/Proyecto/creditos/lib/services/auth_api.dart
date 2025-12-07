import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApi {
  // Cambia según tu entorno:
  // Emulador Android → 10.0.2.2
  // Dispositivo físico → IP de tu PC (ej: 192.168.0.15)
  // Web → localhost
  static const String baseUrl = "http://10.0.2.2:5218/api/auth";

  // ====================
  // REGISTRO
  // ====================
  static Future<String?> register({
    required String nombre,
    required String apellido,
    required String email,
    required String dpi,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nombre": nombre,
          "apellido": apellido,
          "email": email,
          "dpi": dpi,
          "password": password,
        }),
      );

     if (response.statusCode == 200) {
  return null; // ✅ éxito
} else {
  try {
    // 👇 Intentamos parsear como JSON
    final error = jsonDecode(response.body);
    if (error is Map && error.containsKey("message")) {
      return error["message"];
    }
    return error.toString();
  } catch (_) {
    // 👇 Si no es JSON válido, devolvemos el texto plano tal cual
    return response.body;
  }
}

 
    } catch (e) {
      return "Error de conexión con el servidor: $e";
    }
  }

  // ====================
  // LOGIN
  // ====================
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {"success": true, "usuario": data['usuario']};
      } else {
        // 🔹 Si el backend devuelve texto plano (no JSON)
        return {"success": false, "message": response.body};
      }
    } catch (e) {
      return {"success": false, "message": "Error de conexión"};
    }
  }
}
