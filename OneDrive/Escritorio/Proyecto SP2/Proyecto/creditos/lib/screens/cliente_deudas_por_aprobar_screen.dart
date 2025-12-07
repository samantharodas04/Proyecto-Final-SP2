import 'package:flutter/material.dart';
import '../services/deudas_api.dart';

class ClienteDeudasPorAprobarScreen extends StatefulWidget {
  final int clienteId;
  final String nombre;

  const ClienteDeudasPorAprobarScreen({
    super.key,
    required this.clienteId,
    required this.nombre,
  });

  @override
  State<ClienteDeudasPorAprobarScreen> createState() =>
      _ClienteDeudasPorAprobarScreenState();
}

class _ClienteDeudasPorAprobarScreenState
    extends State<ClienteDeudasPorAprobarScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _deudas = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data =
          await DeudasApi.deudasPendientesCliente(widget.clienteId);
      setState(() {
        _deudas = data;
      });
    } catch (e) {
      setState(() {
        _error = "Error al cargar deudas: $e";
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _aprobar(int deudaId) async {
    try {
      await DeudasApi.aprobarDeudaCliente(deudaId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Deuda aprobada correctamente."),
        backgroundColor: Colors.green,
      ));
      await _cargar();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error al aprobar deuda: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _rechazar(int deudaId) async {
    try {
      await DeudasApi.rechazarDeudaCliente(deudaId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Deuda rechazada."),
        backgroundColor: Colors.orange,
      ));
      await _cargar();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error al rechazar deuda: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffbefff),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(
          'Deudas por aprobar · ${widget.nombre}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : _deudas.isEmpty
                  ? const Center(
                      child: Text("No tienes deudas pendientes."),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _deudas.length,
                      itemBuilder: (context, index) {
                        final d = _deudas[index];
                        final deudaId = d['id'] ?? d['deudaId'];
                        final monto =
                            (d['monto'] ?? d['total'] ?? 0).toDouble();
                        final fechaCreacion =
                            (d['fechaCreacion'] ?? '').toString();
                        final fechaLimite =
                            (d['fechaLimite'] ?? '').toString();

                        final detalles = (d['detalles'] as List?) ?? [];

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.hourglass_top,
                                        color: Colors.deepPurple),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Monto: Q.${monto.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (fechaCreacion.isNotEmpty)
                                  Text(
                                    "Creada: $fechaCreacion",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                if (fechaLimite.isNotEmpty)
                                  Text(
                                    "Fecha límite: $fechaLimite",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                if (detalles.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: detalles.map<Widget>((item) {
                                      final it = Map<String, dynamic>.from(
                                          item as Map);
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color:
                                              const Color(0xfff5e9ff),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          "${it['cantidad']} × ${it['itemNombre']} @ Q.${it['precioUnitario']}",
                                          style:
                                              const TextStyle(fontSize: 12),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                              color: Colors.redAccent),
                                          foregroundColor: Colors.redAccent,
                                        ),
                                        onPressed: deudaId == null
                                            ? null
                                            : () => _rechazar(deudaId),
                                        child: const Text("Rechazar"),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.deepPurple,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: deudaId == null
                                            ? null
                                            : () => _aprobar(deudaId),
                                        child: const Text("Aceptar"),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
