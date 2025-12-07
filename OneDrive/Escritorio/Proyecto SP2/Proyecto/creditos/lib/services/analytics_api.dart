import 'dart:convert';
import 'package:http/http.dart' as http;

class AnalyticsApi {
  static const String baseUrl = "http://10.0.2.2:5218/api/analytics";

  static Future<List<Map<String, dynamic>>> bestSellers({
    required int usuarioId,
    DateTime? from,
    DateTime? to,
    int top = 10,
  }) async {
    final params = <String, String>{
      "usuarioId": "$usuarioId",
      "top": "$top",
    };
    if (from != null) params["from"] = from.toIso8601String();
    if (to != null) params["to"] = to.toIso8601String();

    final uri = Uri.parse("$baseUrl/best-sellers").replace(queryParameters: params);
    final res = await http
        .get(uri, headers: {"Content-Type": "application/json"})
        .timeout(const Duration(seconds: 12));

    if (res.statusCode != 200) {
      throw Exception("Error (${res.statusCode}): ${res.body}");
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) return [];
    return decoded.map<Map<String, dynamic>>((e) {
      return e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map);
    }).toList();
  }
}
