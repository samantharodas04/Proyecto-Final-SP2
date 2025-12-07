import 'package:creditos/screens/pagos_deuda_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/usuario_provider.dart';
import '../services/deudas_api.dart';

enum OrdenDeudas {
  fechaDesc,             // más nuevo -> más antiguo
  fechaAsc,              // más antiguo -> más nuevo
  prioridadRojoVerde,    // rojo (moroso) -> naranja -> verde (pagadas al final)
  prioridadVerdeRojo,    // verde -> naranja -> rojo (pagadas al final)
}

class HistorialClienteScreen extends StatefulWidget {
  final int clienteId;
  final String nombre;

  const HistorialClienteScreen({
    super.key,
    required this.clienteId,
    required this.nombre,
  });

  @override
  State<HistorialClienteScreen> createState() => _HistorialClienteScreenState();
}

class _HistorialClienteScreenState extends State<HistorialClienteScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  late int _usuarioId;

  OrdenDeudas _orden = OrdenDeudas.fechaDesc;
  bool _soloPendientes = false;

  @override
  void initState() {
    super.initState();
    final u = Provider.of<UsuarioProvider>(context, listen: false).usuario!;
    _usuarioId = u.id;
    _future = DeudasApi.historialPorCliente(
      clienteId: widget.clienteId,
      usuarioId: _usuarioId,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _future = DeudasApi.historialPorCliente(
        clienteId: widget.clienteId,
        usuarioId: _usuarioId,
      );
    });
    await _future;
  }

  String _fmtFecha(dynamic iso) {
    if (iso == null) return "—";
    try {
      final d = DateTime.parse(iso.toString());
      return "${d.day}/${d.month}/${d.year}";
    } catch (_) {
      return "—";
    }
  }

  // ------- Estado y colores -------
  // Prioridad: 2 = rojo (vencida), 1 = naranja (<= 3 días), 0 = verde
  int _priorityRank(Map<String, dynamic> deuda) {
    final limIso = deuda['fechaLimite'];
    if (limIso == null) return 0;
    DateTime? limite;
    try {
      limite = DateTime.parse(limIso.toString());
    } catch (_) {
      return 0;
    }
    final hoy = DateTime.now();
    final onlyToday = DateTime(hoy.year, hoy.month, hoy.day);
    final onlyLimit = DateTime(limite.year, limite.month, limite.day);

    if (onlyLimit.isBefore(onlyToday)) return 2; // vencida -> rojo
    final diff = onlyLimit.difference(onlyToday).inDays;
    if (diff <= 3) return 1; // por vencer -> naranja
    return 0; // a tiempo -> verde
  }

  Color _statusColor(Map<String, dynamic> deuda) {
    switch (_priorityRank(deuda)) {
      case 2:
        return Colors.redAccent;
      case 1:
        return Colors.orangeAccent;
      default:
        return Colors.green;
    }
  }

  String _statusText(Map<String, dynamic> deuda) {
    switch (_priorityRank(deuda)) {
      case 2:
        return "Vencida";
      case 1:
        return "Por vencer";
      default:
        return "A tiempo";
    }
  }

  bool _estaPagada(Map<String, dynamic> d) {
    final flag = d['estaPagada'] as bool?;
    if (flag != null) return flag;
    final saldo = (d['saldo'] as num?)?.toDouble();
    return saldo != null ? saldo <= 0 : false;
  }

  // ------- Ordenamientos -------
  List<Map<String, dynamic>> _ordenar(List<Map<String, dynamic>> deudas) {
    final list = List<Map<String, dynamic>>.from(deudas);

    int cmpFechaDesc(a, b) {
      final fa = DateTime.tryParse((a['fechaCreacion'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final fb = DateTime.tryParse((b['fechaCreacion'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return fb.compareTo(fa);
    }

    int cmpFechaAsc(a, b) {
      final fa = DateTime.tryParse((a['fechaCreacion'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final fb = DateTime.tryParse((b['fechaCreacion'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return fa.compareTo(fb);
    }

    // 🔴🟠🟢 (pagadas al final)
    int cmpPrioridadRojoVerde(a, b) {
      final aPaid = _estaPagada(a);
      final bPaid = _estaPagada(b);
      if (aPaid && !bPaid) return 1;   // a al final
      if (!aPaid && bPaid) return -1;  // b al final

      final ra = _priorityRank(a);
      final rb = _priorityRank(b);
      // rojo(2) primero, luego naranja(1), luego verde(0)
      final byRank = rb.compareTo(ra);
      if (byRank != 0) return byRank;
      return cmpFechaDesc(a, b); // desempate por fecha desc
    }

    // 🟢🟠🔴 (pagadas al final)
    int cmpPrioridadVerdeRojo(a, b) {
      final aPaid = _estaPagada(a);
      final bPaid = _estaPagada(b);
      if (aPaid && !bPaid) return 1;   // a al final
      if (!aPaid && bPaid) return -1;  // b al final

      final ra = _priorityRank(a);
      final rb = _priorityRank(b);
      // verde(0) primero, luego naranja(1), luego rojo(2)
      final byRank = ra.compareTo(rb);
      if (byRank != 0) return byRank;
      return cmpFechaAsc(a, b); // desempate por fecha asc
    }

    switch (_orden) {
      case OrdenDeudas.fechaDesc:
        list.sort(cmpFechaDesc);
        break;
      case OrdenDeudas.fechaAsc:
        list.sort(cmpFechaAsc);
        break;
      case OrdenDeudas.prioridadRojoVerde:
        list.sort(cmpPrioridadRojoVerde);
        break;
      case OrdenDeudas.prioridadVerdeRojo:
        list.sort(cmpPrioridadVerdeRojo);
        break;
    }
    return list;
  }

  // ------- Registrar pago -------
  Future<void> _abrirRegistrarPago(Map<String, dynamic> deuda) async {
    final deudaId = (deuda['id'] as num).toInt();
    final saldo = (deuda['saldo'] as num?)?.toDouble();
    final controller = TextEditingController();
    String? errorText;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Registrar pago"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (saldo != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      "Saldo actual: Q.${saldo.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "Monto a pagar",
                    hintText: "Ej. 50.00",
                    errorText: errorText,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () {
                  final val = double.tryParse(controller.text.trim());
                  if (val == null || val <= 0) {
                    setState(() => errorText = "Ingresa un monto válido");
                    return;
                  }
                  if (saldo != null && val > saldo) {
                    setState(() => errorText = "El pago excede el saldo");
                    return;
                  }
                  Navigator.pop(context, true);
                },
                child: const Text("Registrar"),
              ),
            ],
          );
        },
      ),
    );

    if (ok == true) {
      final monto = double.parse(controller.text.trim());
      try {
        await DeudasApi.registrarPago(
          deudaId: deudaId,
          monto: monto,
          usuarioId: _usuarioId,
        );
        if (!mounted) return;
        await _reload();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pago registrado.")),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al registrar pago: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Historial • ${widget.nombre}"),
        actions: [
          PopupMenuButton<Object>(
            tooltip: "Ordenar/filtrar",
            onSelected: (value) {
              if (value is OrdenDeudas) {
                setState(() => _orden = value);
              } else if (value is String && value == 'toggle-pendientes') {
                setState(() => _soloPendientes = !_soloPendientes);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem<OrdenDeudas>(
                value: OrdenDeudas.fechaDesc,
                child: Text("Más nuevo → Más antiguo"),
              ),
              const PopupMenuItem<OrdenDeudas>(
                value: OrdenDeudas.fechaAsc,
                child: Text("Más antiguo → Más nuevo"),
              ),
              const PopupMenuItem<OrdenDeudas>(
                value: OrdenDeudas.prioridadRojoVerde,
                child: Text("Prioridad: Alta → Baja"),
              ),
              const PopupMenuItem<OrdenDeudas>(
                value: OrdenDeudas.prioridadVerdeRojo,
                child: Text("Prioridad: Baja → Alta"),
              ),
              const PopupMenuDivider(),
              CheckedPopupMenuItem<String>(
                value: 'toggle-pendientes',
                checked: _soloPendientes,
                child: const Text("Solo pendientes"),
              ),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
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

          final raw = snap.data ?? [];

          // aplicar filtro de "solo pendientes"
          final visibles = _soloPendientes
              ? raw.where((d) => !_estaPagada(d)).toList()
              : raw;

          if (visibles.isEmpty) {
            return const Center(child: Text("Sin deudas aún"));
          }

          // ordenar según selección (pagadas al final en órdenes por prioridad)
          final deudas = _ordenar(visibles);

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: deudas.length,
              itemBuilder: (_, i) {
                final d = deudas[i];
                final monto = (d['monto'] as num?)?.toDouble() ?? 0;
                final fecha = _fmtFecha(d['fechaCreacion']);
                final fechaLimite = _fmtFecha(d['fechaLimite']);
                final detalles = (d['detalles'] as List?) ?? const [];

                final saldo = (d['saldo'] as num?)?.toDouble();
                final estaPagada = _estaPagada(d);

                final colorEstado = _statusColor(d);
                final estadoTxt = _statusText(d);

                return Card(
                  elevation: 1,
                  child: InkWell(
                    onTap: () async {
                      final saldoTap = (d['saldo'] as num?)?.toDouble();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PagosDeudaScreen(
                            deudaId: (d['id'] as num).toInt(),
                            monto: (d['monto'] as num?)?.toDouble(),
                            saldoActual: saldoTap,
                          ),
                        ),
                      );
                      await _reload();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ======= HEADER NUEVO: Saldo grande a la izquierda, Monto original a la derecha =======
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 12,
                                color: estaPagada ? Colors.grey : colorEstado,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Saldo: Q.${(saldo ?? 0).toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: estaPagada ? Colors.grey : Colors.deepPurple,
                                  decoration: estaPagada
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "Monto: Q.${monto.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (!estaPagada)
                                Chip(
                                  label: Text(estadoTxt),
                                  backgroundColor: colorEstado.withOpacity(0.12),
                                  side: BorderSide(color: colorEstado.withOpacity(0.4)),
                                  labelStyle: TextStyle(color: colorEstado, fontWeight: FontWeight.w600),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.green.withOpacity(0.35)),
                                  ),
                                  child: const Text(
                                    "Pagado",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Text("Fecha límite: $fechaLimite", style: const TextStyle(fontSize: 12)),
                              const Spacer(),
                              Text(fecha, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                            ],
                          ),

                          if (detalles.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: -6,
                              children: detalles.map((e) {
                                final m = Map<String, dynamic>.from(e as Map);
                                final cant = (m['cantidad'] as num?)?.toInt() ?? 1;
                                final nombre = (m['itemNombre'] ?? '').toString();
                                final precio = (m['precioUnitario'] as num?)?.toDouble() ?? 0;
                                return Chip(
                                  label: Text("$cant × $nombre @ Q.${precio.toStringAsFixed(2)}"),
                                  backgroundColor: Colors.deepPurple.withOpacity(0.08),
                                );
                              }).toList(),
                            ),
                          ],

                          if (!estaPagada) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.payments),
                                label: const Text("Pagar"),
                                onPressed: () => _abrirRegistrarPago(d),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
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
