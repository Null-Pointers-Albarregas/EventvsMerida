class Usuario {
  final int id;
  final String nombre;
  final String apellidos;
  final DateTime fechaNacimiento;
  final String email;
  final String telefono;
  final String rol;
  final String? fotoUrl;

  Usuario({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.fechaNacimiento,
    required this.email,
    required this.telefono,
    required this.rol,
    this.fotoUrl
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'apellidos': apellidos,
    'fechaNacimiento': fechaNacimiento.toIso8601String(),
    'email': email,
    'telefono': telefono,
    'idRol': rol,
    'fotoUrl': fotoUrl,
  };

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: json['id'] ?? 0,
    nombre: json['nombre'] ?? '',
    apellidos: json['apellidos'] ?? '',
    fechaNacimiento: DateTime.parse(json['fechaNacimiento']),
    email: json['email'] ?? '',
    telefono: json['telefono'] ?? '',
    rol: json['rol'] ?? '',
    fotoUrl: json['fotoUrl'],
  );
}