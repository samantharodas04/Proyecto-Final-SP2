import 'package:flutter/material.dart';

class ClienteHomeScreen extends StatelessWidget {
  final int clienteId;
  final String nombre;
  final String dpi;

  const ClienteHomeScreen({
    super.key,
    required this.clienteId,
    required this.nombre,
    required this.dpi,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffbefff),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text(
          'Inicio cliente',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              // Solo regresamos al login de cliente
              Navigator.pushReplacementNamed(context, 'cliente_login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  children: [
                    Text(
                      'Bienvenid@ $nombre 👋',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ID de cliente: $clienteId',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'DPI: $dpi',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botón: Mis deudas
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text(
                  'Mis deudas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    'cliente_deudas',
                    arguments: {
                      'clienteId': clienteId,
                      'nombre': nombre,
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Botón: Deudas por aprobar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.pending_actions_outlined),
                label: const Text(
                  'Deudas por aprobar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    'cliente_deudas_por_aprobar',
                    arguments: {
                      'clienteId': clienteId,
                      'nombre': nombre,
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
