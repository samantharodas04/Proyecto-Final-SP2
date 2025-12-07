import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/auth_api.dart';

class UsuarioProvider extends ChangeNotifier {
  Usuario? _usuario;

  Usuario? get usuario => _usuario;

  // 👉 GETTERS ÚTILES
  int get usuarioId => _usuario?.id ?? -1; // <-- el que te pedía deudas_screen
  String? get email => _usuario?.email;
  String get displayName {
    final n = (_usuario?.nombre ?? '').trim();
    final a = (_usuario?.apellido ?? '').trim();
    final full = [n, a].where((s) => s.isNotEmpty).join(' ');
    return full.isNotEmpty ? full : (_usuario?.email ?? '');
  }
  bool get isLogged => _usuario != null;

  // ====================
  // LOGIN
  // ====================
  Future<String?> login(String email, String password) async {
    final result = await AuthApi.login(email: email, password: password);

    if (result["success"] == true) {
      // mapear usuario del backend
      _usuario = Usuario.fromJson(result["usuario"]);
      notifyListeners();
      return null; // éxito
    } else {
      return result["message"]; // mensaje de error
    }
  }

  // ====================
  // REGISTRO
  // ====================
  Future<String?> register(
    String nombre,
    String apellido,
    String email,
    String dpi,
    String password,
  ) async {
    final error = await AuthApi.register(
      nombre: nombre,
      apellido: apellido,
      email: email,
      dpi: dpi,
      password: password,
    );

    if (error == null) {
      // El backend no devuelve usuario en registro, solo confirmación
      _usuario = Usuario(
        id: 0, // temporal, el ID real lo asigna el backend
        nombre: nombre,
        apellido: apellido,
        email: email,
        dpi: dpi,
        fechaRegistro: DateTime.now().toIso8601String(),
      );
      notifyListeners();
      return null; // éxito
    } else {
      return error; // mensaje de error
    }
  }

  // ====================
  // LOGOUT
  // ====================
  void logout() {
    _usuario = null;
    notifyListeners();
  }
}
