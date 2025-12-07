// lib/screens/items_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';

import '../providers/usuario_provider.dart';
import '../services/items_api.dart';
import 'agregar_item_screen.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  late int _usuarioId;

  // carga y búsqueda
  late Future<List<Map<String, dynamic>>> _future;
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];

  // edición / imagen
  final ImagePicker _picker = ImagePicker();
  bool _isPickingImage = false;
  String? _fotoBase64Tmp; // buffer temporal al editar

  @override
  void initState() {
    super.initState();
    final u = Provider.of<UsuarioProvider>(context, listen: false).usuario!;
    _usuarioId = u.id;
    _future = _cargar();
    _searchCtrl.addListener(_aplicarFiltro);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // === Data loading ===
  Future<List<Map<String, dynamic>>> _cargar() async {
    final data = await ItemsApi.listar(_usuarioId);
    _all = data;
    _filtered = List<Map<String, dynamic>>.from(_all);
    return _all;
  }

  Future<void> _reload() async {
    setState(() {
      _future = _cargar();
    });
    await _future;
  }

  void _aplicarFiltro() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (!mounted) return;
    setState(() {
      if (q.isEmpty) {
        _filtered = List<Map<String, dynamic>>.from(_all);
      } else {
        _filtered = _all
            .where((m) => (m['nombre'] ?? '')
                .toString()
                .toLowerCase()
                .contains(q))
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    });
  }

  // === Imagen ===
  Future<void> _pickImage() async {
    if (_isPickingImage) return; // evita doble apertura
    _isPickingImage = true;
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _fotoBase64Tmp = base64Encode(bytes);
        });
      }
    } finally {
      _isPickingImage = false;
    }
  }

  // === Editar ===
  Future<void> _editarItemDialog(Map<String, dynamic> item) async {
    final nombreCtrl = TextEditingController(text: (item['nombre'] ?? '').toString());
    final descCtrl   = TextEditingController(text: (item['descripcion'] ?? '').toString());
    final precioCtrl = TextEditingController(text: (item['precio'] as num?)?.toString() ?? '0');

    _fotoBase64Tmp = (item['foto'] as String?);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Editar artículo',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                const SizedBox(height: 16),

                // Foto
                GestureDetector(
                  onTap: () async => await _pickImage(),
                  child: _fotoBase64Tmp != null && _fotoBase64Tmp!.isNotEmpty
                      ? Image.memory(
                          _safeDecodeBase64(_fotoBase64Tmp!),
                          height: 120, width: 120, fit: BoxFit.cover,
                        )
                      : Container(
                          height: 120, width: 120,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add_a_photo, size: 40),
                        ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: "Nombre"),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: "Descripción"),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: precioCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: "Precio"),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                      child: const Text("Guardar", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (ok == true) {
      final nombre = nombreCtrl.text.trim();
      final descripcion = descCtrl.text.trim();
      final precio = double.tryParse(precioCtrl.text.trim()) ?? 0;

      await ItemsApi.actualizar(
        id: (item['id'] as num).toInt(),
        nombre: nombre,
        descripcion: (descripcion.isNotEmpty ? descripcion : null) ?? '',
        precio: precio,
        fotoBase64: _fotoBase64Tmp,
        usuarioId: _usuarioId,
      );
      await _reload();
    }
  }

  // === Eliminar ===
  Future<void> _eliminar(int id) async {
  // Optimista: quita de la UI mientras pega al server
  final old = List<Map<String, dynamic>>.from(_all);
  setState(() {
    _all = _all.where((i) => (i['id'] as num).toInt() != id).toList();
    _aplicarFiltro();
  });

  String? err;
  try {
    err = await ItemsApi.eliminar(id);
  } catch (e) {
    err = e.toString();
  }

  if (err != null) {
    // ❌ Falló de verdad -> rollback
    setState(() {
      _all = old;
      _aplicarFiltro();
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("No se pudo eliminar: $err")),
    );
  } else {
    // ✅ Éxito -> opcional mostrar confirmación
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Artículo eliminado")),
    );
  }
}


  // === UI ===
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mis artículos")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AgregarItemScreen()),
          );
          if (result == true) await _reload();
        },
        label: const Text("Agregar"),
        icon: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Text(
                  "Error al listar items:\n${snap.error}",
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: "Buscar por nombre...",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _reload,
                    child: _filtered.isEmpty
                        ? ListView(
                            children: [SizedBox(height: 300, child: Center(child: Text("Sin resultados")))],
                          )
                        : ListView.separated(
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final it = _filtered[i];
                              final id = (it['id'] as num).toInt();
                              final nombre = (it['nombre'] ?? '').toString();
                              final desc = (it['descripcion'] ?? '').toString();
                              final precio = (it['precio'] as num?)?.toDouble() ?? 0.0;
                              final foto = it['foto'] as String?;

                              return ListTile(
                                leading: _buildFoto(foto),
                                title: Text(nombre),
                                subtitle: Text(
                                  (desc.isEmpty ? "" : "$desc\n") + "Q.${precio.toStringAsFixed(2)}",
                                ),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _editarItemDialog(it),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _eliminar(id),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper para foto segura
  Widget _buildFoto(String? base64) {
    if (base64 == null || base64.isEmpty) {
      return const Icon(Icons.image_not_supported);
    }
    try {
      final bytes = _safeDecodeBase64(base64);
      return Image.memory(bytes, width: 50, height: 50, fit: BoxFit.cover);
    } catch (_) {
      return const Icon(Icons.broken_image);
    }
  }

  // Evita errores si el base64 trae prefijo tipo "data:image/png;base64,..."
  Uint8List _safeDecodeBase64(String b64) {
    final comma = b64.indexOf(',');
    final raw = comma >= 0 ? b64.substring(comma + 1) : b64;
    return base64Decode(raw);
  }
}
