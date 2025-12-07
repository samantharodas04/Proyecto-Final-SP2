// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/usuario_provider.dart';
import '../services/dashboard_api.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late int _usuarioId;
  late Future<Map<String, dynamic>> _future;
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    final u = Provider.of<UsuarioProvider>(context, listen: false).usuario!;
    _usuarioId = u.id;
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() {
    return DashboardApi.getResumen(usuarioId: _usuarioId, from: _from, to: _to);
  }

  Future<void> _pickFrom() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _from ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() {
        _from = DateTime(d.year, d.month, d.day);
        _future = _load();
      });
    }
  }

  Future<void> _pickTo() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _to ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      // incluimos todo el día seleccionado
      setState(() {
        _to = DateTime(d.year, d.month, d.day, 23, 59, 59);
        _future = _load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}"));
          }

          final d = snap.data ?? {};

          // Nuevos KPIs
          final clientesMorosos = (d["clientesMorosos"] as num?)?.toInt() ?? 0;
          final promedioDiasAtraso = (d["promedioDiasAtraso"] as num?)?.toDouble() ?? 0;

          // KPI ventas/saldo + top item
          final ventasTotales = (d["ventasTotales"] as num?)?.toDouble() ?? 0;
          final saldoPendiente = (d["saldoPendiente"] as num?)?.toDouble() ?? 0;
          final topItemNombre = (d["topItemNombre"] ?? "-").toString();
          final topItemCantidad = (d["topItemCantidad"] as num?)?.toInt();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Filtros de fecha
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickFrom,
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          _from == null
                              ? "Desde"
                              : "${_from!.day}/${_from!.month}/${_from!.year}",
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTo,
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          _to == null
                              ? "Hasta"
                              : "${_to!.day}/${_to!.month}/${_to!.year}",
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Fila 1: NUEVOS KPIs
                Row(
                  children: [
                    _card(
                      title: "Clientes morosos",
                      value: "$clientesMorosos",
                      color: Colors.redAccent,
                      icon: Icons.warning_amber_rounded,
                    ),
                    const SizedBox(width: 12),
                    _card(
                      title: "Prom. días atraso",
                      value: "${promedioDiasAtraso.toStringAsFixed(1)}",
                      color: Colors.orange,
                      icon: Icons.timer_outlined,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Fila 2: Ventas totales + Saldo pendiente
                Row(
                  children: [
                    _card(
                      title: "Ventas totales (ítems)",
                      value: "Q. ${ventasTotales.toStringAsFixed(2)}",
                      color: Colors.green,
                      icon: Icons.attach_money,
                    ),
                    const SizedBox(width: 12),
                    _card(
                      title: "Saldo pendiente",
                      value: "Q. ${saldoPendiente.toStringAsFixed(2)}",
                      color: Colors.blueAccent,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Fila 3: Producto estrella
                Row(
                  children: [
                    _card(
                      title: "Producto estrella",
                      value: topItemNombre == "-"
                          ? "-"
                          : "$topItemNombre (${topItemCantidad ?? 0})",
                      color: Colors.deepPurple,
                      icon: Icons.star,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Expanded _card({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
