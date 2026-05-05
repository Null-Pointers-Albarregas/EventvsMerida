class ApiResponse<T> {
  final bool exito;
  final String mensaje;
  final T? datos;
  final int codigoEstado;

  const ApiResponse({required this.exito, required this.mensaje, required this.codigoEstado, this.datos});

  factory ApiResponse.exito({required T? datos, required String mensaje, required int codigoEstado}) {
    return ApiResponse<T>(
      exito: true,
      mensaje: mensaje,
      codigoEstado: codigoEstado,
      datos: datos,
    );
  }

  factory ApiResponse.error({required String mensaje, required int codigoEstado}) {
    return ApiResponse<T>(
      exito: false,
      mensaje: mensaje,
      codigoEstado: codigoEstado,
      datos: null,
    );
  }

  factory ApiResponse.sinConexion({required String mensaje}) {
    return ApiResponse<T>(
      exito: false,
      mensaje: mensaje,
      codigoEstado: 0,
      datos: null,
    );
  }
}