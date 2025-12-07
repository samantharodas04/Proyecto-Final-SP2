class Usuario {
  final int id;
  final String nombre;
  final String apellido;
  final String email;
  final String dpi;
  final String fechaRegistro;

  Usuario({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.dpi,
    required this.fechaRegistro,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      email: json['email'],
      dpi: json['dpi'], 
      fechaRegistro: json['fechaRegistro'],
    );
  }
}
