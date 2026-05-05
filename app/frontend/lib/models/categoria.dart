class Categoria {
  final int id;
  final String nombre;

  Categoria({
    required this.id,
    required this.nombre,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
  };

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
    id: json['id'] ?? 12,
    nombre: json['nombre'] ?? '',
  );
}