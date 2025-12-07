import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 para Clipboard
import '../services/deudas_api.dart';
import 'cliente_pagos_screen.dart';

class ClienteDeudasScreen extends StatefulWidget {
  final int clienteId;
  final String nombre;

  const ClienteDeudasScreen({
    super.key,
    required this.clienteId,
    required this.nombre,
  });

  @override
  State<ClienteDeudasScreen> createState() => _ClienteDeudasScreenState();
}

class _ClienteDeudasScreenState extends State<ClienteDeudasScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _deudas = [];

  // ✅ Filtros
  String _orden = 'nuevo';
  bool _soloPendientes = false;

  @override
  void initState() {
    super.initState();
    _cargarDeudas();
  }

  Future<void> _cargarDeudas() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await DeudasApi.historialPorCliente(
        clienteId: widget.clienteId,
        usuarioId: null,
      );
      setState(() {
        _deudas = data;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar deudas: $e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ✅ Aplicar filtro
  List<Map<String, dynamic>> _deudasFiltradas() {
    List<Map<String, dynamic>> lista = List.from(_deudas);

    if (_soloPendientes) {
      lista = lista.where((d) {
        final saldo =
            (d['saldo'] ?? d['saldoPendiente'] ?? 0 as num).toDouble();
        return saldo > 0;
      }).toList();
    }

    switch (_orden) {
      case 'antiguo':
        lista.sort((a, b) => (a['id'] ?? 0).compareTo(b['id'] ?? 0));
        break;
      case 'nuevo':
        lista.sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));
        break;
      case 'alta':
        lista.sort((a, b) {
          final sa = (a['saldo'] ?? 0 as num).toDouble();
          final sb = (b['saldo'] ?? 0 as num).toDouble();
          return sb.compareTo(sa);
        });
        break;
      case 'baja':
        lista.sort((a, b) {
          final sa = (a['saldo'] ?? 0 as num).toDouble();
          final sb = (b['saldo'] ?? 0 as num).toDouble();
          return sa.compareTo(sb);
        });
        break;
    }

    return lista;
  }

  // 🔥 Popup on-chain (MISMO estilo que en el tendero)
  Future<void> _mostrarDialogoOnChain({
    required int deudaId,
    required double monto,
    required double saldo,
  }) async {
    try {
      final estado = await DeudasApi.deudaOnChain(deudaId);

      final txHash = estado['txHash']?.toString();
      final bool onChain = estado['onChain'] == true;
      final double? montoOnChain =
          (estado['montoOnChain'] as num?)?.toDouble();
      final String? error = estado['errorOnChain']?.toString();

      String estadoTxt;
      if (txHash != null && txHash.isNotEmpty && onChain) {
        estadoTxt = "Confirmado en blockchain";
      } else if (txHash != null && txHash.isNotEmpty) {
        estadoTxt = "Pending (tx enviada, pendiente de confirmación)";
      } else {
        estadoTxt = "Sin registro en blockchain todavía.";
      }

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text("Detalle on-chain de la deuda"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ID deuda: $deudaId"),
              Text("Monto local: Q${monto.toStringAsFixed(2)}"),
              Text("Saldo actual: Q${saldo.toStringAsFixed(2)}"),
              if (montoOnChain != null)
                Text("Monto on-chain: Q${montoOnChain.toStringAsFixed(2)}"),
              const SizedBox(height: 10),
              
             
              if (txHash != null && txHash.isNotEmpty) ...[
                const SizedBox(height: 10),
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
                  "Copia este hash y pégalo en un explorador de Ethereum Sepolia (Routescan, Blockscout, etc).",
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
              if (error != null && error.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  "Error on-chain:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  error,
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error consultando blockchain: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffbefff),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(
          'Historial · ${widget.nombre}',
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
                      child: Text('No tienes deudas registradas.'),
                    )
                  : Column(
                      children: [
                        // ✅ Barra de filtros
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.filter_list),
                                onSelected: (v) =>
                                    setState(() => _orden = v),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: 'nuevo',
                                      child: Text(
                                          'Más nuevo → Más antiguo')),
                                  PopupMenuItem(
                                      value: 'antiguo',
                                      child: Text(
                                          'Más antiguo → Más nuevo')),
                                  PopupMenuItem(
                                      value: 'alta',
                                      child: Text(
                                          'Prioridad: Alta → Baja')),
                                  PopupMenuItem(
                                      value: 'baja',
                                      child: Text(
                                          'Prioridad: Baja → Alta')),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text('Solo pendientes'),
                                  Switch(
                                    value: _soloPendientes,
                                    onChanged: (v) => setState(
                                        () => _soloPendientes = v),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // ✅ Lista
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _deudasFiltradas().length,
                            itemBuilder: (context, index) {
                              final d = _deudasFiltradas()[index];

                              final deudaId = d['id'] ?? d['deudaId'];
                              final monto =
                                  (d['monto'] ?? 0.0 as num).toDouble();
                              final saldo =
                                  (d['saldo'] ?? 0.0 as num).toDouble();
                              final fechaLimite =
                                  (d['fechaLimite'] ?? '').toString();

                              final bool pagado = saldo <= 0.0001;

                              return Card(
                                elevation: 2,
                                margin:
                                    const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  onTap: deudaId == null
                                      ? null
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ClientePagosScreen(
                                                deudaId:
                                                    (deudaId as num)
                                                        .toInt(),
                                                montoTotal: monto,
                                                saldo: saldo,
                                              ),
                                            ),
                                          );
                                        },
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              pagado
                                                  ? Icons
                                                      .check_circle
                                                  : Icons.error,
                                              color: pagado
                                                  ? Colors.green
                                                  : Colors.redAccent,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Saldo: Q.${saldo.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.bold,
                                                color: pagado
                                                    ? Colors.grey
                                                    : Colors
                                                        .deepPurple,
                                                decoration: pagado
                                                    ? TextDecoration
                                                        .lineThrough
                                                    : TextDecoration
                                                        .none,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              'Monto: Q.${monto.toStringAsFixed(2)}',
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 8),

                                        if (fechaLimite.isNotEmpty)
                                          Text(
                                            'Fecha límite: $fechaLimite',
                                            style: const TextStyle(
                                                fontSize: 12),
                                          ),

                                        // ✅ DETALLES DE ITEMS
                                        if (d['detalles'] != null) ...[
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children:
                                                List<Widget>.from(
                                              (d['detalles'] as List)
                                                  .map((item) {
                                                final it = Map<
                                                        String,
                                                        dynamic>.from(
                                                    item);

                                                final cantidad =
                                                    it['cantidad'] ??
                                                        0;
                                                final nombreItem =
                                                    (it['itemNombre'] ??
                                                            it['descripcion'] ??
                                                            '')
                                                        .toString();
                                                final precioUnit =
                                                    (it['precioUnitario'] ??
                                                            it['precio'] ??
                                                            0)
                                                        as num;

                                                return Container(
                                                  padding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  decoration:
                                                      BoxDecoration(
                                                    color:
                                                        const Color(
                                                            0xfff5e9ff),
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                                12),
                                                  ),
                                                  child: Text(
                                                    "$cantidad × $nombreItem @ Q.${precioUnit.toDouble().toStringAsFixed(2)}",
                                                    style:
                                                        const TextStyle(
                                                            fontSize:
                                                                12),
                                                  ),
                                                );
                                              }),
                                            ),
                                          ),
                                        ],

                                        const SizedBox(height: 10),

                                        Row(
                                          children: [
                                            const Text(
                                              'Toca la tarjeta para ver pagos',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    Colors.black54,
                                              ),
                                            ),
                                            const Spacer(),
                                            if (deudaId != null)
                                              TextButton(
                                                onPressed: () =>
                                                    _mostrarDialogoOnChain(
                                                  deudaId:
                                                      (deudaId as num)
                                                          .toInt(),
                                                  monto: monto,
                                                  saldo: saldo,
                                                ),
                                                child: const Text(
                                                  'Ver on-chain',
                                                  style: TextStyle(
                                                    fontSize: 12,
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
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}
