import 'dart:convert';
import 'package:http/http.dart' as http;

class DeudasApi {
  static const String baseUrl = "http://10.0.2.2:5218/api";

  /// Historial por cliente (solo deudas APROBADAS)
  static Future<List<Map<String, dynamic>>> historialPorCliente({
    required int clienteId,
    int? usuarioId,
  }) async {
    final uri = Uri.parse(
      usuarioId == null
          ? "$baseUrl/deudas/historial/$clienteId"
          : "$baseUrl/deudas/historial/$clienteId?usuarioId=$usuarioId",
    );

    final res = await http
        .get(uri, headers: {"Content-Type": "application/json"})
        .timeout(const Duration(seconds: 12));

    if (res.statusCode != 200) {
      throw Exception("Error al obtener historial: ${res.body}");
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) return [];
    return decoded.map<Map<String, dynamic>>((e) {
      if (e is Map<String, dynamic>) return e;
      return Map<String, dynamic>.from(e as Map);
    }).toList();
  }

  /// Deudores (home tendero)
  static Future<List<Map<String, dynamic>>> deudores(int usuarioId) async {
    final uri = Uri.parse("$baseUrl/deudas/deudores?usuarioId=$usuarioId");

    final res = await http
        .get(uri, headers: {"Content-Type": "application/json"})
        .timeout(const Duration(seconds: 12));

    if (res.statusCode != 200) {
      throw Exception("Error al obtener deudores: ${res.body}");
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) return [];
    return decoded.map<Map<String, dynamic>>((e) {
      if (e is Map<String, dynamic>) return e;
      return Map<String, dynamic>.from(e as Map);
    }).toList();
  }

    /// Crear deuda
  static Future<Map<String, dynamic>> crear({
    required int usuarioId,
    required int clienteId,
    double? monto,
    DateTime? fechaLimite,
    required List<Map<String, int>> detalles,
  }) async {
    final List<Map<String, dynamic>> detallesBody = detalles.map((d) {
      return {
        "ItemId": d["ItemId"] ?? d["itemId"],
        "Cantidad": d["Cantidad"] ?? d["cantidad"] ?? 1,
      };
    }).toList();

    final body = <String, dynamic>{
      "UsuarioId": usuarioId,
      "ClienteId": clienteId,
      "FechaLimite": fechaLimite?.toIso8601String(),
      if (monto != null) "Monto": monto,
      "Detalles": detallesBody,
    };

    final url = Uri.parse("$baseUrl/deudas");
    final res = await http
        .post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 12));

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Error al crear deuda: ${res.body}");
    }

    if (res.body.isEmpty) return {};

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return Map<String, dynamic>.from(decoded as Map);
  }



  /// Obtener una deuda
  static Future<Map<String, dynamic>?> getById(int id) async {
    final url = Uri.parse("$baseUrl/deudas/$id");
    final res = await http
        .get(url, headers: {"Content-Type": "application/json"})
        .timeout(const Duration(seconds: 12));

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return Map<String, dynamic>.from(decoded as Map);
    } else if (res.statusCode == 404) {
      return null;
    } else {
      throw Exception("Error al cargar deuda: ${res.body}");
    }
  }

  // ========================= PAGOS =========================

  static Future<Map<String, dynamic>> registrarPago({
    required int deudaId,
    required double monto,
    String? nota,
    int? usuarioId,
  }) async {
    final uri = Uri.parse("$baseUrl/deudas/$deudaId/pagos");
    final res = await http
        .post(
          uri,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "monto": monto,
            "nota": nota,
            "usuarioId": usuarioId ?? 0,
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (res.statusCode != 200) {
      throw Exception("Error al registrar pago: ${res.body}");
    }

    final decoded = jsonDecode(res.body);
    return decoded is Map<String, dynamic>
        ? decoded
        : Map<String, dynamic>.from(decoded as Map);
  }

  static Future<List<Map<String, dynamic>>> pagos(int deudaId) async {
    final url = Uri.parse("$baseUrl/deudas/$deudaId/pagos");
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception("Error al cargar pagos: ${res.body}");
    }
    final decoded = jsonDecode(res.body);
    final list = decoded is List ? decoded : <dynamic>[];
    return list
        .map<Map<String, dynamic>>(
            (e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> pagosDeDeuda(int deudaId) async {
    final uri = Uri.parse("$baseUrl/deudas/$deudaId/pagos");
    final res = await http
        .get(uri, headers: {"Content-Type": "application/json"})
        .timeout(const Duration(seconds: 12));

    if (res.statusCode != 200) {
      throw Exception("Error al cargar pagos: ${res.body}");
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) return [];
    return decoded.map<Map<String, dynamic>>((e) {
      if (e is Map<String, dynamic>) return e;
      return Map<String, dynamic>.from(e as Map);
    }).toList();
  }

  /// Best sellers
  static Future<List<Map<String, dynamic>>> bestSellers({
    required int usuarioId,
    DateTime? from,
    DateTime? to,
    int top = 5,
  }) async {
    final params = <String, String>{
      "usuarioId": "$usuarioId",
      "top": "$top",
    };
    if (from != null) params["from"] = from.toIso8601String();
    if (to != null) params["to"] = to.toIso8601String();

    final uri = Uri.parse("$baseUrl/deudas/best-sellers")
        .replace(queryParameters: params);

    final res = await http
        .get(uri, headers: {"Content-Type": "application/json"})
        .timeout(const Duration(seconds: 12));

    if (res.statusCode != 200) {
      throw Exception("Error (${res.statusCode}): ${res.body}");
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) return [];
    return decoded
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // ========================= ON-CHAIN POR DEUDA =========================

static Future<Map<String, dynamic>> deudaOnChain(int deudaId) async {
  final uri = Uri.parse("$baseUrl/deudas/$deudaId/onchain");
  final res = await http
      .get(uri, headers: {"Content-Type": "application/json"})
      .timeout(const Duration(seconds: 12));

  if (res.statusCode != 200) {
    throw Exception("Error al consultar on-chain: ${res.body}");
  }

  final decoded = jsonDecode(res.body);
  return decoded is Map<String, dynamic>
      ? decoded
      : Map<String, dynamic>.from(decoded as Map);
}



    // =========================
  // DEUDAS POR APROBAR (cliente)
  // =========================

  static Future<Map<String, dynamic>> estadoDeudaOnChain(int deudaId) async {
  final url = Uri.parse("$baseUrl/deudas/onchain/$deudaId");
  final resp = await http.get(url);

  if (resp.statusCode >= 400) {
    throw "Error consultando on-chain";
  }

  return json.decode(resp.body);
}


  static Future<List<Map<String, dynamic>>> deudasPendientesCliente(
      int clienteId) async {
    final uri = Uri.parse("$baseUrl/deudas/pendientes/$clienteId");

    final res = await http
        .get(uri, headers: {"Content-Type": "application/json"})
        .timeout(const Duration(seconds: 12));

    if (res.statusCode != 200) {
      throw Exception("Error al obtener deudas por aprobar (${res.statusCode}): ${res.body}");
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) return [];
    return decoded
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<void> aprobarDeudaCliente(int deudaId) async {
    final uri = Uri.parse("$baseUrl/deudas/aprobar-cliente/$deudaId");

    final res = await http
        .post(uri, headers: {"Content-Type": "application/json"})
        .timeout(const Duration(seconds: 12));

    if (res.statusCode != 200) {
      throw Exception(
          "Error al aprobar deuda (${res.statusCode}): ${res.body}");
    }
  }

  static Future<void> rechazarDeudaCliente(int deudaId) async {
    final uri = Uri.parse("$baseUrl/deudas/rechazar-cliente/$deudaId");

    final res = await http
        .post(uri, headers: {"Content-Type": "application/json"})
        .timeout(const Duration(seconds: 12));

    if (res.statusCode != 200) {
      throw Exception(
          "Error al rechazar deuda (${res.statusCode}): ${res.body}");
    }
  }

}
