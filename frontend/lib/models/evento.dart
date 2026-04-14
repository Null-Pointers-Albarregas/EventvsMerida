class Evento {
  final String titulo;
  final String descripcion;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String localizacion;
  final String foto;
  final String emailUsuario;
  final String nombreCategoria;

  Evento({
    required this.titulo,
    required this.descripcion,
    required this.fechaInicio,
    required this.fechaFin,
    required this.localizacion,
    required this.foto,
    required this.emailUsuario,
    required this.nombreCategoria,
  });

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      fechaInicio: DateTime.parse(json['fechaInicio'].toString()),
      fechaFin: DateTime.parse(json['fechaFin'].toString()),
      localizacion: json['localizacion'] ?? '',
      foto: json['foto'] ?? '',
      emailUsuario: json['emailUsuario'] ?? '',
      nombreCategoria: json['nombreCategoria'] ?? '',
    );
  }
}