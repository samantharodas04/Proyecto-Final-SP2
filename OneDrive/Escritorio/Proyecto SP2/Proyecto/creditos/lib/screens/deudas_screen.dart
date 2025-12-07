import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 para Clipboard
import 'package:provider/provider.dart';

import '../services/clientes_api.dart';
import '../services/items_api.dart';
import '../services/deudas_api.dart';
import '../providers/usuario_provider.dart';
import 'clientes_screen.dart';

class DeudasScreen extends StatefulWidget {
  const DeudasScreen({super.key});

  @override
  State<DeudasScreen> createState() => _DeudasScreenState();
}

class _DeudasScreenState extends State<DeudasScreen> {
  late int _usuarioId;

  final TextEditingController _clienteCtrl = TextEditingController();
  final TextEditingController _montoCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _itemsFiltrados = [];

  // cantidades por itemId
  final Map<int, int> _cantidades = {};

  bool _usarMontoDirecto = false;

  DateTime? _fechaLimite;
  TimeOfDay? _horaLimite;
  Map<String, dynamic>? _clienteSeleccionado;

  @override
  void initState() {
    super.initState();
    final usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    _usuarioId = usuario!.id;

    _cargarClientes();
    _cargarItems();

    _montoCtrl.addListener(() => setState(() {}));
    _searchCtrl.addListener(_aplicarFiltro);
  }

  @override
  void dispose() {
    _clienteCtrl.dispose();
    _montoCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarClientes() async {
    final data = await ClientesApi.listar(_usuarioId);
    setState(() {
      _clientes = data
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();
    });
  }

  Future<void> _cargarItems() async {
    final data = await ItemsApi.listar(_usuarioId);
    setState(() {
      _items = data
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();
      _itemsFiltrados = List<Map<String, dynamic>>.from(_items);
    });
  }

  void _aplicarFiltro() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _itemsFiltrados = List<Map<String, dynamic>>.from(_items);
      } else {
        _itemsFiltrados = _items
            .where((m) =>
                (m['nombre'] ?? '').toString().toLowerCase().contains(q))
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    });
  }

  double _calcularTotal() {
    if (_usarMontoDirecto) {
      return double.tryParse(_montoCtrl.text.trim()) ?? 0;
    } else {
      double total = 0;
      for (final entry in _cantidades.entries) {
        final itemId = entry.key;
        final cant = entry.value;
        if (cant <= 0) continue;
        final item = _items.firstWhere(
          (it) => (it['id'] as num).toInt() == itemId,
          orElse: () => const {},
        );
        final precio = (item['precio'] as num?)?.toDouble() ?? 0.0;
        total += precio * cant;
      }
      return total;
    }
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale("es", "ES"),
    );
    if (picked != null) {
      setState(() => _fechaLimite = picked);
    }
  }

  Future<void> _seleccionarHora(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horaLimite ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _horaLimite = picked);
    }
  }

  DateTime? _combinarFechaHora() {
    if (_fechaLimite == null && _horaLimite == null) return null;
    if (_fechaLimite != null && _horaLimite != null) {
      return DateTime(
        _fechaLimite!.year,
        _fechaLimite!.month,
        _fechaLimite!.day,
        _horaLimite!.hour,
        _horaLimite!.minute,
      );
    }
    if (_fechaLimite != null) {
      return DateTime(
          _fechaLimite!.year, _fechaLimite!.month, _fechaLimite!.day, 23, 59);
    }
    final now = DateTime.now();
    return DateTime(
        now.year, now.month, now.day, _horaLimite!.hour, _horaLimite!.minute);
  }

  // 🔥 Diálogo que muestra el estado en blockchain
  Future<void> _mostrarDialogoBlockchain(
    BuildContext context,
    Map<String, dynamic> resp,
  ) async {
    final id = resp['id'];
    final monto = resp['monto'];
    final txHash = resp['txHash'] as String?;
    final bool onChain = resp['onChain'] == true;
    final String? errorOnChain = resp['errorOnChain'];

    String estado;
    if (onChain && txHash != null && txHash.isNotEmpty) {
      estado = "Confirmado (tx registrada en la red)";
    } else if (txHash != null && txHash.isNotEmpty) {
      estado = "Pending (tx enviada, pendiente de confirmación)";
    } else {
      estado = "Error (no se pudo enviar la transacción)";
    }

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Deuda registrada"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ID: $id"),
            Text("Monto: Q$monto"),
            const SizedBox(height: 8),

            const Text(
              "Estado blockchain:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              estado,
              style: TextStyle(
                color: onChain ? Colors.green : Colors.red,
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
                "Copia este hash y pégalo en un explorador de Ethereum Sepolia (por ejemplo Routescan o Blockscout) para ver la transacción.",
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],

            if (!onChain && errorOnChain != null) ...[
              const SizedBox(height: 8),
              const Text(
                "Error on-chain:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                errorOnChain,
                style: const TextStyle(fontSize: 12, color: Colors.red),
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

  Future<void> _onGuardarDeuda() async {
    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona un cliente válido.")),
      );
      return;
    }

    try {
      final fechaLimite = _combinarFechaHora();

      // RESPUESTA DEL BACKEND (en ambos casos)
      late Map<String, dynamic> resp;

      if (_usarMontoDirecto) {
        // ================= MODO MONTO DIRECTO =================
        final monto = _calcularTotal();

        if (monto <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Ingresa un monto mayor a 0."),
            ),
          );
          return;
        }

        resp = await DeudasApi.crear(
          usuarioId: _usuarioId,
          clienteId: _clienteSeleccionado!['id'],
          monto: monto, // 👈 monto directo
          fechaLimite: fechaLimite,
          detalles: const [], // 👈 sin detalles
        );
      } else {
        // ================= MODO DETALLES / ÍTEMS =================
        final detalles = _cantidades.entries
            .where((e) => e.value > 0)
            .map((e) => {'ItemId': e.key, 'Cantidad': e.value})
            .toList();

        if (detalles.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Agrega al menos 1 ítem con cantidad > 0."),
            ),
          );
          return;
        }

        resp = await DeudasApi.crear(
          usuarioId: _usuarioId,
          clienteId: _clienteSeleccionado!['id'],
          monto: null, // 👈 backend calcula por ítems
          fechaLimite: fechaLimite,
          detalles: detalles,
        );
      }

      // 👉 Mostrar SIEMPRE el diálogo con info on-chain
      await _mostrarDialogoBlockchain(context, resp);

      // Luego de cerrar el diálogo, volvemos a la pantalla anterior
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Widget _buildBody(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Cliente:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Autocomplete + agregar cliente
                  Autocomplete<Map<String, dynamic>>(
                    displayStringForOption: (Map<String, dynamic> option) =>
                        option['nombre'],
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return _clientes;
                      }
                      return _clientes
                          .where((c) => (c['nombre'] as String)
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase()))
                          .toList();
                    },
                    onSelected: (Map<String, dynamic> seleccion) {
                      setState(() {
                        _clienteSeleccionado = seleccion;
                        _clienteCtrl.text = seleccion['nombre'];
                      });
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onEditingComplete) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: "Buscar cliente",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: options.length + 1,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              if (index == options.length) {
                                return ListTile(
                                  leading: const Icon(Icons.add,
                                      color: Colors.deepPurple),
                                  title: const Text("➕ Agregar cliente"),
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ClientesScreen(),
                                      ),
                                    );
                                    _cargarClientes();
                                  },
                                );
                              }

                              final option = options.elementAt(index);
                              final isSelected = _clienteSeleccionado != null &&
                                  _clienteSeleccionado!['id'] == option['id'];

                              return ListTile(
                                title: Text(option['nombre']),
                                trailing: isSelected
                                    ? const Icon(Icons.check,
                                        color: Colors.green)
                                    : null,
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Tipo de deuda
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text("Monto directo"),
                          value: true,
                          groupValue: _usarMontoDirecto,
                          onChanged: (v) =>
                              setState(() => _usarMontoDirecto = v ?? false),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text("Seleccionar items"),
                          value: false,
                          groupValue: _usarMontoDirecto,
                          onChanged: (v) =>
                              setState(() => _usarMontoDirecto = v ?? false),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (_usarMontoDirecto)
                    TextField(
                      controller: _montoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Monto de la deuda",
                        prefixIcon: Icon(Icons.monetization_on),
                        border: OutlineInputBorder(),
                      ),
                    ),

                  if (!_usarMontoDirecto) ...[
                    // Buscador de ítems
                    TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Buscar ítems por nombre...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Lista de ítems con cantidades (encogible dentro del scroll padre)
                    ListView.builder(
                      itemCount: _itemsFiltrados.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (_, i) {
                        final it = _itemsFiltrados[i];
                        final id = (it['id'] as num).toInt();
                        final nombre = (it['nombre'] ?? 'Item').toString();
                        final precio =
                            (it['precio'] as num?)?.toDouble() ?? 0.0;
                        final qty = _cantidades[id] ?? 0;

                        return ListTile(
                          title: Text(nombre),
                          subtitle: Text('Q.${precio.toStringAsFixed(2)}'),
                          trailing: SizedBox(
                            width: 160,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                      Icons.remove_circle_outline),
                                  onPressed: qty > 0
                                      ? () => setState(
                                          () => _cantidades[id] = qty - 1)
                                      : null,
                                ),
                                Text(
                                  '$qty',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                IconButton(
                                  icon:
                                      const Icon(Icons.add_circle_outline),
                                  onPressed: () => setState(
                                      () => _cantidades[id] = qty + 1),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Fecha límite
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Colors.deepPurple),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _fechaLimite == null
                              ? "Sin fecha límite seleccionada"
                              : "Fecha límite: ${_fechaLimite!.day}/${_fechaLimite!.month}/${_fechaLimite!.year}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _seleccionarFecha(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                        ),
                        child: const Text(
                          "Elegir fecha",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Hora límite
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          color: Colors.deepPurple),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _horaLimite == null
                              ? "Sin hora seleccionada"
                              : "Hora límite: ${_horaLimite!.hour.toString().padLeft(2, '0')}:${_horaLimite!.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _seleccionarHora(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                        ),
                        child: const Text(
                          "Elegir hora",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Total
                  Text(
                    "Total: Q.${_calcularTotal().toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Botón
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Agregar deuda"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _onGuardarDeuda,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Deudas"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(context),
    );
  }
}
