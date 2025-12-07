// lib/screens/best_sellers_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/usuario_provider.dart';
import '../services/deudas_api.dart';

class BestSellersScreen extends StatefulWidget {
  const BestSellersScreen({super.key});

  @override
  State<BestSellersScreen> createState() => _BestSellersScreenState();
}

class _BestSellersScreenState extends State<BestSellersScreen> {
  late int _usuarioId;

  DateTime? _desde;
  DateTime? _hasta;
  int _top = 5;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _data = [];

  @override
  void initState() {
    super.initState();
    final u = Provider.of<UsuarioProvider>(context, listen: false).usuario!;
    _usuarioId = u.id;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await DeudasApi.bestSellers(
        usuarioId: _usuarioId,
        from: _desde,
        to: _hasta,
        top: _top,
      );
      setState(() => _data = res);
    } catch (e) {
      setState(() => _error = "Error (${e.runtimeType}): $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDesde() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 2);
    final picked = await showDatePicker(
      context: context,
      initialDate: _desde ?? now,
      firstDate: first,
      lastDate: DateTime(now.year + 2),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() => _desde = DateTime(picked.year, picked.month, picked.day));
      await _load();
    }
  }

  Future<void> _pickHasta() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 2);
    final picked = await showDatePicker(
      context: context,
      initialDate: _hasta ?? now,
      firstDate: first,
      lastDate: DateTime(now.year + 2),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      // Normalizamos a fin de día para no perder ventas del mismo día
      setState(() => _hasta = DateTime(picked.year, picked.month, picked.day, 23, 59, 59));
      await _load();
    }
  }

  String _fmt(DateTime? d) {
    if (d == null) return "";
    return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
  }

  Color _rowColor(int index) {
    // leve gradiente por posición
    switch (index % 4) {
      case 0:
        return Colors.deepPurple.withOpacity(.06);
      case 1:
        return Colors.indigo.withOpacity(.06);
      case 2:
        return Colors.blueGrey.withOpacity(.06);
      default:
        return Colors.purple.withOpacity(.06);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = _data.fold<int>(0, (a, b) => a + (b['cantidadVendida'] as num?)!.toInt());
    final totalMonto = _data.fold<double>(0.0, (a, b) => a + ((b['montoTotal'] as num?)?.toDouble() ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Best Sellers"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filtros
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                // Desde
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDesde,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_desde == null ? "Desde" : _fmt(_desde)),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Hasta
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickHasta,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_hasta == null ? "Hasta" : _fmt(_hasta)),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Top N
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _top,
                    onChanged: (v) async {
                      if (v == null) return;
                      setState(() => _top = v);
                      await _load();
                    },
                    items: const [5, 10, 20, 50]
                        .map((n) => DropdownMenuItem(value: n, child: Text("Top $n")))
                        .toList(),
                  ),
                ),
                IconButton(
                  tooltip: "Limpiar filtros",
                  onPressed: () async {
                    setState(() {
                      _desde = null;
                      _hasta = null;
                      _top = 5;
                    });
                    await _load();
                  },
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Contenido
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorView(
                        message: _error!,
                        onRetry: _load,
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _data.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 260),
                                  Center(child: Text("Sin resultados para el rango seleccionado")),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                                itemCount: _data.length + 1,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (_, i) {
                                  if (i == 0) {
                                    // Cabecera de totales
                                    return Card(
                                      elevation: 0,
                                      color: Colors.deepPurple.withOpacity(.05),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.bar_chart, color: Colors.deepPurple),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                "Ítems: $totalItems",
                                                style: const TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                            Text(
                                              "Q.${totalMonto.toStringAsFixed(2)}",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.deepPurple),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  final m = _data[i - 1];
                                  final nombre = (m['itemNombre'] ?? '').toString();
                                  final cant = (m['cantidadVendida'] as num?)?.toInt() ?? 0;
                                  final monto = (m['montoTotal'] as num?)?.toDouble() ?? 0.0;

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: _rowColor(i),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.deepPurple.shade100,
                                        child: Text("$i",
                                            style: const TextStyle(color: Colors.deepPurple)),
                                      ),
                                      title: Text(
                                        nombre.isEmpty ? "Sin nombre" : nombre,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Text("Vendidos: $cant"),
                                      trailing: Text(
                                        "Q.${monto.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepPurple),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            const Text("No se pudo cargar el reporte."),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("Reintentar"),
            ),
          ],
        ),
      ),
    );
  }
}
