import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/deudas_api.dart';

class PagosDeudaScreen extends StatefulWidget {
  final int deudaId;
  final double? monto;
  final double? saldoActual;

  const PagosDeudaScreen({
    super.key,
    required this.deudaId,
    this.monto,
    this.saldoActual,
  });

  @override
  State<PagosDeudaScreen> createState() => _PagosDeudaScreenState();
}

class _PagosDeudaScreenState extends State<PagosDeudaScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  Future<Map<String, dynamic>>? _onChainFuture;

  @override
  void initState() {
    super.initState();
    _future = DeudasApi.pagos(widget.deudaId);
    _onChainFuture = DeudasApi.deudaOnChain(widget.deudaId);
  }

  String _fmtFecha(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} "
      "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";

  Future<void> _reload() async {
    setState(() {
      _future = DeudasApi.pagos(widget.deudaId);
      _onChainFuture = DeudasApi.deudaOnChain(widget.deudaId);
    });

    await Future.wait([
      _future,
      if (_onChainFuture != null) _onChainFuture!,
    ]);
  }

  // ========= DIALOGO DETALLE PAGO + BLOCKCHAIN =========
  Future<void> _mostrarDetalleBlockchainPago(
      Map<String, dynamic> pago) async {
    final monto = (pago['monto'] as num?)?.toDouble() ?? 0;
    final fechaStr = pago['fecha']?.toString();
    DateTime? fecha;
    try {
      if (fechaStr != null) fecha = DateTime.parse(fechaStr);
    } catch (_) {}

    final nota = (pago['nota'] ?? '').toString();
    final txHash = pago['txHash'] as String?;
    final bool onChain = pago['onChain'] == true;

    String estado;
    if (onChain && txHash != null && txHash.isNotEmpty) {
      estado = "Pago registrado en blockchain ✅";
    } else if (txHash != null && txHash.isNotEmpty) {
      estado = "Transacción enviada (pending) ⏳";
    } else {
      estado = "Sin información on-chain ⚠️";
    }

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Detalle de pago"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Monto: Q.${monto.toStringAsFixed(2)}"),
            if (fecha != null)
              Text("Fecha: ${_fmtFecha(fecha)}"),
            if (nota.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text("Nota: $nota"),
            ],
            const SizedBox(height: 8),
            const Text(
              "Estado blockchain:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              estado,
              style: TextStyle(
                color: onChain ? Colors.green : Colors.orange,
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
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Hash copiado al portapapeles"),
                    ),
                  );
                }
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
  // =============================================

  @override
  Widget build(BuildContext context) {
    final resumen = (widget.monto != null || widget.saldoActual != null)
        ? "Monto: ${widget.monto != null ? "Q.${widget.monto!.toStringAsFixed(2)}" : "-"}   •   "
            "Saldo: ${widget.saldoActual != null ? "Q.${widget.saldoActual!.toStringAsFixed(2)}" : "-"}"
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de pagos"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Error: ${snap.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final pagos = snap.data ?? [];

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              children: [
                // Resumen local (monto/saldo)
                if (resumen != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      resumen,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),

                // Tarjeta de estado on-chain (por deuda)
                if (_onChainFuture != null)
                  FutureBuilder<Map<String, dynamic>>(
                    future: _onChainFuture,
                    builder: (_, snapOnChain) {
                      if (snapOnChain.connectionState ==
                          ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: LinearProgressIndicator(),
                        );
                      }
                      if (snapOnChain.hasError) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Text(
                            "No se pudo consultar en blockchain: ${snapOnChain.error}",
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }

                      final data = snapOnChain.data!;
                      final montoLocal =
                          (data['montoLocal'] as num?)?.toDouble() ??
                              widget.monto ??
                              0.0;
                      final montoOnChain =
                          (data['montoOnChain'] as num?)?.toDouble();

                      return Card(
                        margin:
                            const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            
                          ),
                        ),
                      );
                    },
                  ),

                // Lista de pagos
                if (pagos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text("Esta deuda no tiene pagos aún."),
                    ),
                  )
                else
                  ...pagos.map((p) {
                    final monto =
                        (p['monto'] as num?)?.toDouble() ?? 0;
                    final fechaStr = p['fecha']?.toString();
                    DateTime? fecha;
                    try {
                      if (fechaStr != null) {
                        fecha = DateTime.parse(fechaStr);
                      }
                    } catch (_) {}
                    final nota = (p['nota'] ?? '').toString();

                    return ListTile(
                      leading: const Icon(Icons.payments),
                      title: Text(
                        "Q.${monto.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        "${fecha != null ? _fmtFecha(fecha) : "—"}"
                        "${nota.isNotEmpty ? "\n$nota" : ""}",
                      ),
                      onTap: () => _mostrarDetalleBlockchainPago(p),
                    );
                  }),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
