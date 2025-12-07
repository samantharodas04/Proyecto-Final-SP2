import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/items_api.dart';
import '../providers/usuario_provider.dart';

class AgregarItemScreen extends StatefulWidget {
  const AgregarItemScreen({super.key});

  @override
  State<AgregarItemScreen> createState() => _AgregarItemScreenState();
}

class _AgregarItemScreenState extends State<AgregarItemScreen> {
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();

  String? _fotoBase64;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _fotoBase64 = base64Encode(bytes);
      });
    }
  }

  Widget _buildImagePreview() {
    if (_fotoBase64 == null) {
      return GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[300],
          ),
          child: const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
        ),
      );
    } else {
      try {
        Uint8List bytes = base64Decode(_fotoBase64!);
        return GestureDetector(
          onTap: _pickImage,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              bytes,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
        );
      } catch (_) {
        return const Icon(Icons.broken_image, size: 40, color: Colors.red);
      }
    }
  }

  Future<void> _guardar() async {
    final usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;

    if (_nombreCtrl.text.trim().isEmpty || _precioCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nombre y precio son obligatorios")),
      );
      return;
    }

    await ItemsApi.crear(
      nombre: _nombreCtrl.text.trim(),
      descripcion: _descCtrl.text.trim(),
      precio: double.tryParse(_precioCtrl.text.trim()) ?? 0,
      fotoBase64: _fotoBase64 ?? "",
      usuarioId: usuario!.id,
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Agregar artículo")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildImagePreview(),
            const SizedBox(height: 20),
            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                labelText: "Nombre",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: "Descripción",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _precioCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Precio",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _guardar,
              icon: const Icon(Icons.save),
              label: const Text("Guardar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
