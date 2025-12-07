import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/usuario_provider.dart';
import '../services/deudas_api.dart';

import 'deudas_screen.dart';
import 'historial_cliente_screen.dart';

class DeudasHomeScreen extends StatefulWidget {
  const DeudasHomeScreen({super.key});

  @override
  State<DeudasHomeScreen> createState() => _DeudasHomeScreenState();
}

class _DeudasHomeScreenState extends State<DeudasHomeScreen> {
  late int _usuarioId;
  late Future<List<Map<String, dynamic>>> _future;

  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];

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

  Future<List<Map<String, dynamic>>> _cargar() async {
    final data = await DeudasApi.deudores(_usuarioId);
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

  String _fmtFecha(dynamic iso) {
    if (iso == null) return "—";
    try {
      final d = DateTime.parse(iso.toString());
      return "${d.day}/${d.month}/${d.year}";
    } catch (_) {
      return "—";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Deudores"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Abrir pantalla para crear deuda; al volver, recargar
          final _ = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DeudasScreen()),
          );
          await _reload();
        },
        label: const Text("Agregar deuda"),
        icon: const Icon(Icons.add),
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
              child: SingleChildScrollView(
                child: Text(
                  "Error al cargar deudores:\n${snap.error}",
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          // UI: búsqueda + lista
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: "Buscar cliente...",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _reload,
                    child: _filtered.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(
                                height: 300,
                                child: Center(child: Text("Sin deudores")),
                              ),
                            ],
                          )
                        : ListView.separated(
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final c = _filtered[i];
                              final clienteId =
                                  (c['clienteId'] as num?)?.toInt();
                              final nombre = (c['nombre'] ?? '').toString();
                              final total =
                                  (c['total'] as num?)?.toDouble() ?? 0.0;
                              final count =
                                  (c['cantidadDeudas'] as num?)?.toInt() ?? 0;
                              final ultima = _fmtFecha(c['ultimaFecha']);

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.deepPurple.shade100,
                                  child: const Icon(Icons.person,
                                      color: Colors.deepPurple),
                                ),
                                title: Text(
                                  nombre,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  "Deudas: $count • Última: $ultima",
                                  style:
                                      const TextStyle(color: Colors.black54),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Q.${total.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: total > 0
                                            ? Colors.redAccent
                                            : Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text("Saldo",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black45)),
                                  ],
                                ),
                                onTap: clienteId == null
                                    ? null
                                    : () async {
                                        // Abrir historial; al volver, recargar (por si se registraron pagos)
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                HistorialClienteScreen(
                                              clienteId: clienteId,
                                              nombre: nombre,
                                            ),
                                          ),
                                        );
                                        await _reload();
                                      },
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
}
