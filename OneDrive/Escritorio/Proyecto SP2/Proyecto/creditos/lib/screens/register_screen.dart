import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/usuario_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _dpiCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _emailCtrl.dispose();
    _dpiCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _loading = true);

  final provider = Provider.of<UsuarioProvider>(context, listen: false);
  final error = await provider.register(
    _nombreCtrl.text.trim(),
    _apellidoCtrl.text.trim(),
    _emailCtrl.text.trim(),
    _dpiCtrl.text.trim(),
    _passCtrl.text.trim(),
  );

  if (!mounted) return;
  setState(() => _loading = false);

  if (error == null) {
    // ✅ Registro exitoso
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Usuario registrado con éxito"),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pushReplacementNamed(context, 'login');
  } else {
    // ✅ Manejo de error tanto para Email como para Dpi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error), // 👈 aquí muestra "El dpi ya está registrado." o "El correo ya está registrado."
        backgroundColor: Colors.red,
      ),
    );
    // El formulario sigue activo → puedes cambiar correo o dpi y volver a intentar
  }
}


  @override
Widget build(BuildContext context) {
  final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');

  return WillPopScope(
    onWillPop: () async {
      // 🔹 Navegar al login en vez de hacer pop
      Navigator.pushReplacementNamed(context, 'login');
      return false; // evita el pop normal
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text("Registro"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, 'login');
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: "Nombre",
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => (v == null || v.isEmpty) ? "Ingrese su nombre" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _apellidoCtrl,
                decoration: const InputDecoration(
                  labelText: "Apellido",
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => (v == null || v.isEmpty) ? "Ingrese su apellido" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Correo electrónico",
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (v) => emailRegex.hasMatch(v ?? '') ? null : "Correo inválido",
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _dpiCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(13),
                ],
                decoration: const InputDecoration(
                  labelText: "DPI",
                  prefixIcon: Icon(Icons.credit_card),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Ingrese su DPI";
                  if (v.length != 13) return "Debe tener 13 dígitos";
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (v) =>
                    (v != null && v.length >= 6) ? null : "Mínimo 6 caracteres",
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: _loading ? null : _registrar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Registrar", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    )
    );
  }
}
