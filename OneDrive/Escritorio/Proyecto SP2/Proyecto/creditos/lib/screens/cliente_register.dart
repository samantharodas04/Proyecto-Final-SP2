import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/cliente_auth_api.dart';

class ClienteRegisterScreen extends StatefulWidget {
  const ClienteRegisterScreen({super.key});

  @override
  State<ClienteRegisterScreen> createState() => _ClienteRegisterScreenState();
}

class _ClienteRegisterScreenState extends State<ClienteRegisterScreen> {
  int _currentStep = 0;
  bool _loading = false;

  // Paso 1
  final _formPaso1Key = GlobalKey<FormState>();
  final _dpiCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // Paso 2
  final ImagePicker _picker = ImagePicker();
  XFile? _selfie;
  XFile? _fotoDpi;
  int? _clienteId;
  String? _clienteNombre;

  // Paso 3
  final _formPaso3Key = GlobalKey<FormState>();
  final _emailLoginCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();

  @override
  void dispose() {
    _dpiCtrl.dispose();
    _emailCtrl.dispose();
    _emailLoginCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  // ----------- CÁMARAS / FOTOS -----------

  Future<void> _tomarSelfie() async {
    final img = await _picker.pickImage(
      source: ImageSource.camera, // solo cámara, frontal
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 80,
    );
    if (img != null) {
      setState(() => _selfie = img);
    }
  }

  Future<void> _tomarFotoDpi() async {
    // Permitir cámara o galería
    final opcion = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar foto con cámara'),
              onTap: () => Navigator.pop(ctx, 'camara'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir desde galería'),
              onTap: () => Navigator.pop(ctx, 'galeria'),
            ),
          ],
        ),
      ),
    );

    if (opcion == null) return;

    final source =
        opcion == 'camara' ? ImageSource.camera : ImageSource.gallery;

    final img = await _picker.pickImage(
      source: source,
      imageQuality: 75,
    );
    if (img != null) {
      setState(() => _fotoDpi = img);
    }
  }

  // ----------- FLUJO DE STEPPER -----------

  Future<void> _continuar() async {
    if (_currentStep == 0) {
      // Paso 1: validar DPI+correo
      if (!_formPaso1Key.currentState!.validate()) return;

      setState(() => _loading = true);
      try {
        final res = await ClienteAuthApi.validarCliente(
          dpi: _dpiCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
        );

        final existe = res["existe"] == true;

        if (!existe) {
        final mensaje = res["mensaje"] ?? "No coincide, intenta otra vez";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

        _clienteId = res["clienteId"] as int?;
        _clienteNombre = res["nombre"] as String?;

        setState(() {
          _currentStep = 1;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Cliente encontrado: ${_clienteNombre ?? ''}. Continúa con la validación."),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al validar cliente: $e"),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    } else if (_currentStep == 1) {
      // Paso 2: validar que ya hay selfie + foto DPI y enviar a AWS
      if (_selfie == null || _fotoDpi == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Debes tomar tu selfie y la foto de tu DPI."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _loading = true);
      try {
        final res = await ClienteAuthApi.validarIdentidad(
          dpi: _dpiCtrl.text.trim(),
          selfie: _selfie!,
          dpiFoto: _fotoDpi!,
        );

        final ok = res['ok'] == true;
        final rostroOk = res['rostroCoincide'] == true;
        final dpiOk = res['dpiCoincide'] == true;

        if (!ok) {
          String msg = "No se pudo validar tu identidad.";
          if (!rostroOk && !dpiOk) {
            msg = "El rostro y el número de DPI no coinciden con la imagen.";
          } else if (!rostroOk) {
            msg = "La selfie no coincide con la foto del DPI.";
          } else if (!dpiOk) {
            msg = "El número de DPI no coincide con la imagen del documento.";
          }
        
        final mensaje = (res['mensaje'] ?? 'No coincide, intenta otra vez') as String;

        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
          );
          return; // te quedas en el paso 2 y el usuario puede intentar otra vez
        }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
          
          return;
        }

        setState(() => _currentStep = 2);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Identidad validada correctamente."),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al validar identidad: $e"),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    } else if (_currentStep == 2) {
      // Paso 3: crear contraseña / cuenta
      if (!_formPaso3Key.currentState!.validate()) return;
      if (_clienteId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error interno: cliente no definido."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _loading = true);
      try {
        final error = await ClienteAuthApi.activarCuentaCliente(
          clienteId: _clienteId!,
          emailLogin: _emailLoginCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );

        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cuenta de cliente activada con éxito."),
              backgroundColor: Colors.green,
            ),
          );
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, 'login');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al activar cuenta: $e"),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  void _atras() {
    if (_currentStep == 0) {
      Navigator.pushReplacementNamed(context, 'login');
    } else {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  // ----------- UI -----------

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _atras();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Activar cuenta de cliente"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _atras,
          ),
        ),
        body: AbsorbPointer(
          absorbing: _loading,
          child: Stack(
            children: [
              Stepper(
                currentStep: _currentStep,
                onStepContinue: _continuar,
                onStepCancel: _atras,
                controlsBuilder: (context, details) {
                  return Row(
                    children: [
                      ElevatedButton(
                        onPressed: _loading ? null : details.onStepContinue,
                        child: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_currentStep == 2 ? "Finalizar" : "Siguiente"),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: Text(_currentStep == 0 ? "Cancelar" : "Atrás"),
                      ),
                    ],
                  );
                },
                steps: [
                  // ----- Paso 1 -----
                  Step(
                    title: const Text('Verificar datos'),
                    isActive: _currentStep >= 0,
                    content: Form(
                      key: _formPaso1Key,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _dpiCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'DPI',
                              hintText: 'Ingresa tu DPI',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return "Ingresa tu DPI";
                              }
                              if (v.trim().length < 8) {
                                return "DPI inválido";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Correo registrado en la tienda',
                              hintText: 'ejemplo@correo.com',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return "Ingresa tu correo";
                              }
                              if (!v.contains("@")) {
                                return "Correo inválido";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Usamos estos datos para verificar que realmente estás registrado como cliente.",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ----- Paso 2 -----
                  Step(
                    title: const Text('Validar identidad'),
                    isActive: _currentStep >= 1,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _clienteNombre != null
                              ? 'Hola, ${_clienteNombre!}. Toma una selfie y una foto de tu DPI.'
                              : 'Toma una selfie y una foto de tu DPI.',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _tomarSelfie,
                                    icon: const Icon(Icons.camera_alt_outlined),
                                    label: const Text("Selfie"),
                                  ),
                                  const SizedBox(height: 8),
                                  _selfie != null
                                      ? Image.file(
                                          File(_selfie!.path),
                                          height: 100,
                                          fit: BoxFit.cover,
                                        )
                                      : const Text(
                                          "Sin selfie",
                                          style: TextStyle(fontSize: 12),
                                        ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _tomarFotoDpi,
                                    icon: const Icon(Icons.badge_outlined),
                                    label: const Text("Foto DPI"),
                                  ),
                                  const SizedBox(height: 8),
                                  _fotoDpi != null
                                      ? Image.file(
                                          File(_fotoDpi!.path),
                                          height: 100,
                                          fit: BoxFit.cover,
                                        )
                                      : const Text(
                                          "Sin foto DPI",
                                          style: TextStyle(fontSize: 12),
                                        ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "La selfie siempre se toma con la cámara. La foto del DPI puede ser tomada o seleccionada de la galería.",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  // ----- Paso 3 -----
                  Step(
                    title: const Text('Crear contraseña'),
                    isActive: _currentStep >= 2,
                    content: Form(
                      key: _formPaso3Key,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailLoginCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Correo para iniciar sesión',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return "Ingresa un correo";
                              }
                              if (!v.contains("@")) return "Correo inválido";
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: (v) {
                              if (v == null || v.length < 6) {
                                return "Mínimo 6 caracteres";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _pass2Ctrl,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Repite la contraseña',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: (v) {
                              if (v != _passCtrl.text) {
                                return "Las contraseñas no coinciden";
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
