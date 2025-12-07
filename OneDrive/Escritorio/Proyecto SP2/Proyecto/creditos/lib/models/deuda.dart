class Deuda {
  final int id;
  final int usuarioId;
  final int clienteId;
  final double monto;
  final String? items; // JSON o texto con los items seleccionados
  final DateTime fechaCreacion;
  final DateTime fechaLimite;

  Deuda({
    required this.id,
    required this.usuarioId,
    required this.clienteId,
    required this.monto,
    this.items,
    required this.fechaCreacion,
    required this.fechaLimite,
  });

  factory Deuda.fromJson(Map<String, dynamic> json) {
    return Deuda(
      id: json['id'],
      usuarioId: json['usuarioId'],
      clienteId: json['clienteId'],
      monto: (json['monto'] as num).toDouble(),
      items: json['items'],
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      fechaLimite: DateTime.parse(json['fechaLimite']),
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "usuarioId": usuarioId,
        "clienteId": clienteId,
        "monto": monto,
        "items": items,
        "fechaCreacion": fechaCreacion.toIso8601String(),
        "fechaLimite": fechaLimite.toIso8601String(),
      };
}
