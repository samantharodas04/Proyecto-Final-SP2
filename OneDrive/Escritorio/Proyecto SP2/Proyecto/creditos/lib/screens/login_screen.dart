import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/usuario_provider.dart';
import '../widgets/input_decoration.dart'; // tu helper de estilos

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final provider = Provider.of<UsuarioProvider>(context, listen: false);
    final error = await provider.login(
      _emailCtrl.text.trim(),
      _passCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login exitoso"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, 'home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                Cajamorada(size),
                const IconoWallet(),
                const IconoCirculo(),
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 220),
                      Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.symmetric(horizontal: 30),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5)),
                          ],
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            Text("Login de Tendero",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                )),
                            const SizedBox(height: 30),

                            Form(
                              key: _formKey,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              child: Column(
                                children: [
                                  // Email
                                  TextFormField(
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecorations.inputDecoration(
                                      hintext: 'ejemplo@gmail.com',
                                      labeltext: 'Correo Electrónico',
                                      icono: const Icon(Icons.alternate_email_rounded),
                                    ),
                                    validator: (value) =>
                                        (value != null && value.contains("@")) ? null : "Correo inválido",
                                  ),
                                  const SizedBox(height: 20),

                                  // Password
                                  TextFormField(
                                    controller: _passCtrl,
                                    obscureText: true,
                                    decoration: InputDecorations.inputDecoration(
                                      hintext: '******',
                                      labeltext: 'Contraseña',
                                      icono: const Icon(Icons.lock_outline_rounded),
                                    ),
                                    validator: (v) => (v != null && v.length >= 6)
                                        ? null
                                        : "Mínimo 6 caracteres",
                                  ),
                                  const SizedBox(height: 28),

                                  // Botón ingresar
                                  SizedBox(
                                    width: double.infinity,
                                    child: MaterialButton(
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                      disabledColor: Colors.grey,
                                      color: Colors.deepPurple,
                                      onPressed: _loading ? null : _login,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 14),
                                        child: _loading
                                            ? const SizedBox(
                                                width: 22, height: 22,
                                                child: CircularProgressIndicator(
                                                    strokeWidth: 2, color: Colors.white),
                                              )
                                            : const Text("Ingresar",
                                                style: TextStyle(color: Colors.white)),
                                      ),
                                    ),
                                  ),
                                  

                                  TextButton(
                                    onPressed: _loading
                                        ? null
                                        : () => Navigator.pushReplacementNamed(context, 'register'),
                                    child: const Text("Crear una nueva cuenta"),
                                  ),

                                  

                                  // Botón ingresar cliente
                                  SizedBox(
                                    width: double.infinity,
                                    child: MaterialButton(
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                      disabledColor: Colors.grey,
                                      color: const Color.fromARGB(255, 29, 185, 73),
                                      onPressed: _loading
                                        ? null
                                        : () => Navigator.pushNamed(context, 'cliente_login'),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 14),
                                        child: _loading
                                            ? const SizedBox(
                                                width: 22, height: 22,
                                                child: CircularProgressIndicator(
                                                    strokeWidth: 2, color: Colors.white),
                                              )
                                            : const Text("¿Eres cliente? Inicia sesión aquí",
                                                style: TextStyle(color: Colors.white)),
                                      ),
                                    ),
                                  ),

                                 TextButton(
                                    onPressed: _loading
                                        ? null
                                        : () => Navigator.pushNamed(context, 'cliente_register'),
                                    child: const Text("Activa tu cuenta de cliente"),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------ Iconos y Fondo ------------------------
class IconoCirculo extends StatelessWidget {
  const IconoCirculo({super.key});
  @override
  Widget build(BuildContext context) =>
      Container(margin: const EdgeInsets.only(top: 5), width: double.infinity, child: const Icon(Icons.circle_outlined, color: Colors.white, size: 200));
}

class IconoWallet extends StatelessWidget {
  const IconoWallet({super.key});
  @override
  Widget build(BuildContext context) =>
      Container(margin: const EdgeInsets.only(top: 50), width: double.infinity, child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 100));
}

class Cajamorada extends StatelessWidget {
  final Size size;
  const Cajamorada(this.size, {super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [
          Color.fromRGBO(77, 77, 198, 1),
          Color.fromRGBO(111, 123, 192, 1),
        ]),
      ),
      width: double.infinity,
      height: size.height * 0.4,
      child: Stack(children: const [
        Positioned(child: Burbuja(), top: 90, left: 30),
        Positioned(child: Burbuja(), top: -40, left: -30),
        Positioned(child: Burbuja(), top: -50, right: -20),
        Positioned(child: Burbuja(), bottom: -50, left: 10),
        Positioned(child: Burbuja(), bottom: 120, right: -20),
        Positioned(child: Burbuja(), bottom: -50, right: 10),
      ]),
    );
  }
}

class Burbuja extends StatelessWidget {
  const Burbuja({super.key});
  @override
  Widget build(BuildContext context) => Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(80),
        color: const Color.fromRGBO(132, 151, 214, 0.20),
      ));
}
