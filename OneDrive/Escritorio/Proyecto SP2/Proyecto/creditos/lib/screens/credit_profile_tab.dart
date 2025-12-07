import 'package:flutter/material.dart';
import '../services/clientes_api.dart';

class CreditProfileTab extends StatefulWidget {
  final int usuarioId;
  const CreditProfileTab({super.key, required this.usuarioId});

  @override
  State<CreditProfileTab> createState() => _CreditProfileTabState();
}

class _CreditProfileTabState extends State<CreditProfileTab> {
  // Estado de clientes
  bool _loadingClientes = true;
  String? _errorClientes;
  List<Map<String, dynamic>> _clientes = [];

  // Selección y score
  Map<String, dynamic>? _clienteSel;
  bool _loadingScore = false;
  String? _errorScore;
  Map<String, dynamic>? _score;

  // controlador del buscador
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarClientes());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarClientes() async {
    setState(() {
      _loadingClientes = true;
      _errorClientes = null;
      _clientes = [];
      _clienteSel = null;
      _score = null;
      _errorScore = null;
    });
    try {
      final data = await ClientesApi.listar(widget.usuarioId)
          .timeout(const Duration(seconds: 12));
      if (!mounted) return;
      setState(() => _clientes = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorClientes = "$e");
    } finally {
      if (mounted) setState(() => _loadingClientes = false);
    }
  }

  Future<void> _cargarScore(int clienteId) async {
    setState(() {
      _loadingScore = true;
      _errorScore = null;
      _score = null;
    });
    try {
      final s = await ClientesApi.score(
        clienteId: clienteId,
        usuarioId: widget.usuarioId,
      ).timeout(const Duration(seconds: 12));
      if (!mounted) return;
      setState(() => _score = s);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorScore = "$e");
    } finally {
      if (mounted) setState(() => _loadingScore = false);
    }
  }

  Color _colorPorScore(double s) {
    if (s >= 85) return Colors.green;
    if (s >= 70) return Colors.lightGreen;
    if (s >= 50) return Colors.orange;
    return Colors.redAccent;
  }

  Widget _miniStat(String title, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  Widget _scoreCard(Map<String, dynamic> s) {
    final score = (s['score'] as num?)?.toDouble() ?? 0;
    final tier = (s['tier'] ?? '').toString();
    final totalDeudas = s['totalDeudas'] ?? 0;
    final deudasPagadas = s['deudasPagadas'] ?? 0;
    final aTiempo = s['deudasPagadasATiempo'] ?? 0;
    final montoActivo = (s['montoActivo'] as num?)?.toDouble() ?? 0;
    final montoVencido = (s['montoVencido'] as num?)?.toDouble() ?? 0;
    final pagos90d = s['pagosUltimos90Dias'] ?? 0;
    final diasDesdeAtraso = s['diasDesdeUltimoAtraso'] ?? 0;

    final c = _colorPorScore(score);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Score crediticio: $tier", style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (score.clamp(0, 100)) / 100.0,
              color: c,
              minHeight: 12,
              backgroundColor: Colors.black12,
            ),
          ),
          const SizedBox(height: 8),
          Text("Puntaje: ${score.toStringAsFixed(1)} / 100",
              style: TextStyle(color: c, fontWeight: FontWeight.bold)),
          const Divider(height: 20),
          Wrap(spacing: 16, runSpacing: 8, children: [
            _miniStat("Deudas totales", "$totalDeudas"),
            _miniStat("Pagadas", "$deudasPagadas"),
            _miniStat("A tiempo", "$aTiempo"),
            _miniStat("Pagos 90d", "$pagos90d"),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 16, runSpacing: 8, children: [
            _miniStat("Monto activo", "Q.${montoActivo.toStringAsFixed(2)}"),
            _miniStat("Monto vencido", "Q.${montoVencido.toStringAsFixed(2)}",
                color: montoVencido > 0 ? Colors.red : null),
            _miniStat("Días desde atraso", "$diasDesdeAtraso"),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil crediticio"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _cargarClientes,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text("Perfil crediticio por cliente",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            if (_loadingClientes)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorClientes != null) ...[
              _ErrorState(
                message: "No se pudieron cargar los clientes.\n$_errorClientes",
                onRetry: _cargarClientes,
              ),
            ] else ...[
              // === BUSCADOR (Autocomplete) ===
              Autocomplete<Map<String, dynamic>>(
                optionsBuilder: (TextEditingValue te) {
                  final q = te.text.toLowerCase().trim();
                  if (q.isEmpty) return _clientes;
                  return _clientes.where((c) =>
                      (c['nombre'] ?? '').toString().toLowerCase().contains(q));
                },
                displayStringForOption: (opt) => (opt['nombre'] ?? '').toString(),
                onSelected: (opt) {
                  _searchCtrl.text = (opt['nombre'] ?? '').toString();
                  setState(() => _clienteSel = opt);
                  _cargarScore((opt['id'] as num).toInt());
                },
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  // guarda el controller para que el texto quede visible
                  if (_searchCtrl.text.isNotEmpty && controller.text.isEmpty) {
                    controller.text = _searchCtrl.text;
                  }
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: "Buscar cliente",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  final opts = options.toList();
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220, minWidth: 300),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: opts.length,
                          itemBuilder: (_, i) {
                            final c = opts[i];
                            return ListTile(
                              title: Text((c['nombre'] ?? '').toString()),
                              onTap: () => onSelected(c),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              if (_clienteSel == null)
                const Text("Elige un cliente para ver su score.",
                    style: TextStyle(color: Colors.black54)),

              if (_clienteSel != null && _loadingScore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),

              if (_clienteSel != null && _errorScore != null)
                _ErrorState(
                  message: "No se pudo cargar el score.\n$_errorScore",
                  onRetry: () => _cargarScore((_clienteSel!['id'] as num).toInt()),
                ),

              if (_clienteSel != null &&
                  !_loadingScore &&
                  _errorScore == null &&
                  _score != null)
                _scoreCard(_score!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String actionText;
  const _ErrorState({
    required this.message,
    required this.onRetry,
    this.actionText = "Reintentar",
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 38, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(actionText),
            ),
          ],
        ),
      ),
    );
  }
}
