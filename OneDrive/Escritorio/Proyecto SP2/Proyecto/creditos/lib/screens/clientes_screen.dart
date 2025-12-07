import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/clientes_api.dart';
import '../providers/usuario_provider.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  late int _usuarioId;

  // 🔎 Search bar (nuevo)
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final usuario =
        Provider.of<UsuarioProvider>(context, listen: false).usuario;
    _usuarioId = usuario!.id;
    _future = ClientesApi.listar(_usuarioId);

    // Redibujar al tipear para aplicar el filtro
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _future = ClientesApi.listar(_usuarioId);
    });
  }

  // ------------------- VALIDACIONES -------------------
  String? validarDpi(String? value) {
    if (value == null || value.isEmpty) return "El DPI es obligatorio";
    if (!RegExp(r'^[0-9]{13}$').hasMatch(value)) {
      return "El DPI debe tener 13 dígitos";
    }
    return null;
  }

  String? validarEmail(String? value) {
    if (value == null || value.isEmpty) return null; // opcional
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.(com)$').hasMatch(value)) {
      return "Correo inválido (ejemplo: cliente@test.com)";
    }
    return null;
  }

  // ------------------- FORMATO TELÉFONO -------------------
  String formatPhoneNumber(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), ''); // solo números
    if (digits.isEmpty) return "";
    if (digits.length <= 3) return "(${digits}";
    if (digits.length <= 6) return "(${digits.substring(0, 3)})-${digits.substring(3)}";
    if (digits.length <= 10) {
      return "(${digits.substring(0, 3)})-${digits.substring(3, 7)}-${digits.substring(7)}";
    }
    return "(${digits.substring(0, 3)})-${digits.substring(3, 7)}-${digits.substring(7, 11)}";
  }

  // ------------------- CREAR CLIENTE -------------------
  Future<void> _crearClienteDialog() async {
    final formKey = GlobalKey<FormState>();
    final dpiCtrl = TextEditingController();
    final nombreCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Nuevo cliente",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple)),
                const SizedBox(height: 16),

                // DPI
                TextFormField(
                  controller: dpiCtrl,
                  decoration: InputDecoration(
                    labelText: 'DPI',
                    prefixIcon: const Icon(Icons.credit_card),
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: validarDpi,
                ),
                const SizedBox(height: 12),

                // Nombre
                TextFormField(
                  controller: nombreCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: const Icon(Icons.person),
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Email
                TextFormField(
                  controller: emailCtrl,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: validarEmail,
                ),
                const SizedBox(height: 12),

                // Teléfono con formato automático
                TextFormField(
                  controller: telCtrl,
                  decoration: InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: const Icon(Icons.phone),
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: (val) {
                    final newText = formatPhoneNumber(val);
                    telCtrl.value = TextEditingValue(
                      text: newText,
                      selection: TextSelection.collapsed(offset: newText.length),
                    );
                  },
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(context, true);
                        }
                      },
                      child: const Text('Guardar',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (ok == true && nombreCtrl.text.trim().isNotEmpty) {
      await ClientesApi.crear(
        dpi: dpiCtrl.text.trim(),
        nombre: nombreCtrl.text.trim(),
        email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
        telefono: telCtrl.text.trim().isEmpty ? null : telCtrl.text.trim(),
        usuarioId: _usuarioId,
      );
      await _reload();
    }
  }

  // ------------------- EDITAR CLIENTE -------------------
  Future<void> _editarClienteDialog(Map<String, dynamic> cliente) async {
    final formKey = GlobalKey<FormState>();
    final dpiCtrl = TextEditingController(text: cliente['dpi']);
    final nombreCtrl = TextEditingController(text: cliente['nombre']);
    final emailCtrl = TextEditingController(text: cliente['email'] ?? '');
    final telCtrl = TextEditingController(text: cliente['telefono'] ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Editar cliente",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple)),
                const SizedBox(height: 16),

                // DPI (editable)
                TextFormField(
                  controller: dpiCtrl,
                  decoration: InputDecoration(
                    labelText: 'DPI',
                    prefixIcon: const Icon(Icons.credit_card),
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: validarDpi,
                ),
                const SizedBox(height: 12),

                // Nombre
                TextFormField(
                  controller: nombreCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: const Icon(Icons.person),
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Email
                TextFormField(
                  controller: emailCtrl,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: validarEmail,
                ),
                const SizedBox(height: 12),

                // Teléfono con formato automático
                TextFormField(
                  controller: telCtrl,
                  decoration: InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: const Icon(Icons.phone),
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (val) {
                    final newText = formatPhoneNumber(val);
                    telCtrl.value = TextEditingValue(
                      text: newText,
                      selection: TextSelection.collapsed(offset: newText.length),
                    );
                  },
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(context, true);
                        }
                      },
                      child: const Text('Guardar',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (ok == true && nombreCtrl.text.trim().isNotEmpty) {
      await ClientesApi.actualizar(
        id: cliente['id'],
        dpi: dpiCtrl.text.trim(),
        nombre: nombreCtrl.text.trim(),
        email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
        telefono: telCtrl.text.trim().isEmpty ? null : telCtrl.text.trim(),
        usuarioId: _usuarioId,
      );
      await _reload();
    }
  }

  // ------------------- ELIMINAR CLIENTE -------------------
  Future<void> _eliminar(int id) async {
    setState(() {
      _future = _future.then(
        (clientes) => clientes.where((c) => c['id'] != id).toList(),
      );
    });
    try {
      await ClientesApi.eliminar(id);
    } catch (_) {
      await _reload();
    }
  }

  // ------------------- UI PRINCIPAL -------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis clientes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearClienteDialog,
        label: const Text('Agregar'),
        icon: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final data = (snap.data ?? [])
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

          // 🔎 Aplica filtro sin cambiar tu lógica previa
          final q = _searchCtrl.text.trim().toLowerCase();
          final filtered = q.isEmpty
              ? data
              : data.where((c) {
                  final nombre   = (c['nombre']   ?? '').toString().toLowerCase();
                  final dpi      = (c['dpi']      ?? '').toString().toLowerCase();
                  final email    = (c['email']    ?? '').toString().toLowerCase();
                  final telefono = (c['telefono'] ?? '').toString().toLowerCase();
                  return nombre.contains(q) ||
                      dpi.contains(q) ||
                      email.contains(q) ||
                      telefono.contains(q);
                }).toList();

          if (data.isEmpty) {
            return const Center(child: Text('Sin clientes aún'));
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length + 1, // +1 para incluir la search bar
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                if (i == 0) {
                  // 🔎 Search bar arriba de todo
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Buscar por nombre, DPI, email o teléfono...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  );
                }

                final c = filtered[i - 1];
                return ListTile(
                  title: Text("${c['nombre']}"),
                  subtitle: Text(
                    "DPI: ${c['dpi']}\n${c['email'] ?? ''} • ${c['telefono'] ?? ''}",
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editarClienteDialog(c),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _eliminar(c['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
