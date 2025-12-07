import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 para Clipboard
import '../services/deudas_api.dart';

class ClientePagosScreen extends StatefulWidget {
  final int deudaId;
  final double montoTotal;
  final double saldo;

  const ClientePagosScreen({
    super.key,
    required this.deudaId,
    required this.montoTotal,
    required this.saldo,
  });

  @override
  State<ClientePagosScreen> createState() => _ClientePagosScreenState();
}

class _ClientePagosScreenState extends State<ClientePagosScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _pagos = [];

  @override
  void initState() {
    super.initState();
    _cargarPagos();
  }

  Future<void> _cargarPagos() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await DeudasApi.pagosDeDeuda(widget.deudaId);
      setState(() {
        _pagos = data;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar pagos: $e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // 🧾 Diálogo con detalle + hash on-chain
  Future<void> _mostrarDetallePago(Map<String, dynamic> pago) async {
    final double monto = (pago['monto'] as num?)?.toDouble() ?? 0.0;
    final String fecha =
        (pago['fecha'] ?? pago['fechaPago'] ?? '').toString();
    final String nota =
        (pago['nota'] ?? pago['comentario'] ?? '').toString();

    final String? txHash = pago['txHash']?.toString();
    final bool onChain = pago['onChain'] == true;
    final String? errorOnChain = pago['errorOnChain']?.toString();

    String estado;
    if (txHash == null || txHash.isEmpty) {
      estado = "Este pago todavía no tiene registro on-chain.";
    } else if (onChain) {
      estado = "Confirmado en blockchain ✅";
    } else {
      estado = "Transacción enviada, pendiente de confirmación ⌛";
    }

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Detalle del pago"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Monto: Q${monto.toStringAsFixed(2)}"),
            if (fecha.isNotEmpty) Text("Fecha: $fecha"),
            if (nota.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text("Nota: $nota"),
            ],
            const SizedBox(height: 12),
            const Text(
              "Estado en blockchain:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              estado,
              style: TextStyle(
                color: (txHash != null && txHash.isNotEmpty && onChain)
                    ? Colors.green
                    : Colors.black87,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            if (txHash != null && txHash.isNotEmpty) ...[
              const Text(
                "TxHash:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              SelectableText(
                txHash,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              const Text(
                "Puedes copiar este hash y verlo en un explorador de Ethereum Sepolia (Routescan, Blockscout, etc).",
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
            if (txHash != null &&
                txHash.isNotEmpty &&
                !onChain &&
                errorOnChain != null &&
                errorOnChain.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                "Error on-chain:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                errorOnChain,
                style: const TextStyle(fontSize: 11, color: Colors.red),
              ),
            ],
          ],
        ),
        actions: [
          if (txHash != null && txHash.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text("Copiar hash"),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: txHash));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Hash copiado al portapapeles"),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffbefff),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text(
          'Historial de pagos',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monto: Q.${widget.montoTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Saldo: Q.${widget.saldo.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          Expanded(
            child: _loading
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
                    : _pagos.isEmpty
                        ? const Center(
                            child: Text('No hay pagos registrados.'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _pagos.length,
                            itemBuilder: (context, index) {
                              final p = _pagos[index];
                              final monto =
                                  (p['monto'] as num?)?.toDouble() ?? 0.0;
                              final fecha =
                                  (p['fecha'] ?? p['fechaPago'] ?? '') as String;
                              final nota =
                                  (p['nota'] ?? p['comentario'] ?? '') as String;

                              return Card(
                                elevation: 1,
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const Icon(Icons.payments),
                                  title: Text('Q.${monto.toStringAsFixed(2)}'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (fecha.isNotEmpty)
                                        Text(
                                          fecha,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      if (nota.isNotEmpty)
                                        Text(
                                          nota,
                                          style:
                                              const TextStyle(fontSize: 12),
                                        ),
                                    ],
                                  ),
                                  // 👇 Al tocar el pago, mostramos el diálogo con hash
                                  onTap: () => _mostrarDetallePago(p),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
