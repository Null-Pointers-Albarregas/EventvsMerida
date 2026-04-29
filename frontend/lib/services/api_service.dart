import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/api_response.dart';
import '../models/evento.dart';
import '../models/usuario.dart';
import '../models/categoria.dart';

class ApiService {
  static const String baseUrl = 'https://eventvsmerida.onrender.com/api';
  static const Duration _tiempoLimite = Duration(seconds: 10);
  static const Map<String, String> _cabecerasJson = {'Content-Type': 'application/json',};
  static const String _mensajeSinConexion = 'No hay conexión. Intenta de nuevo más tarde.';

  // ============================================================================
  // USUARIOS
  // ============================================================================

  /// POST /api/usuarios/add
  static Future<ApiResponse<Usuario>> registrarUsuario(Map<String, dynamic> datosUsuario,) async {
    final respuesta = await _post('/usuarios/add', datosUsuario);

    if (respuesta == null) {
      return ApiResponse<Usuario>.sinConexion(mensaje: _mensajeSinConexion,);
    }

    if (respuesta.statusCode == 201) {
      try {
        final mapa = jsonDecode(respuesta.body) as Map<String, dynamic>;
        final usuario = Usuario.fromJson(mapa);

        return ApiResponse<Usuario>.exito(
          datos: usuario,
          mensaje: 'Registro exitoso',
          codigoEstado: 201,
        );
      } catch (_) {
        return ApiResponse<Usuario>.error(
          mensaje: 'No se pudo leer la respuesta del servidor',
          codigoEstado: 201,
        );
      }
    }

    return _manejarError<Usuario>(respuesta);
  }

  /// POST /api/usuarios/login
  static Future<ApiResponse<Usuario>> iniciarSesion(String email, String password) async {
    final respuesta = await _post('/auth/login', {'email': email, 'password': password,});

    if (respuesta == null) {
      return ApiResponse<Usuario>.sinConexion(
        mensaje: _mensajeSinConexion,
      );
    }

    switch (respuesta.statusCode) {
      case 200:
        try {
          final mapa = jsonDecode(respuesta.body) as Map<String, dynamic>;
          final usuario = Usuario.fromJson(mapa);

          return ApiResponse<Usuario>.exito(
            datos: usuario,
            mensaje: 'Login exitoso',
            codigoEstado: 200,
          );
        } catch (_) {
          return ApiResponse<Usuario>.error(
            mensaje: 'No se pudo leer la respuesta del servidor',
            codigoEstado: 200,
          );
        }

      case 400:
      case 401:
      case 404:
        return ApiResponse<Usuario>.error(
          mensaje: 'Credenciales inválidas.',
          codigoEstado: respuesta.statusCode,
        );

      case 500:
        return ApiResponse<Usuario>.error(
          mensaje: 'Error interno del servidor. Intenta más tarde.',
          codigoEstado: 500,
        );

      default:
        return ApiResponse<Usuario>.error(
          mensaje: 'Error desconocido (${respuesta.statusCode}).',
          codigoEstado: respuesta.statusCode,
        );
    }
  }

  // ============================================================================
  // EVENTOS
  // ============================================================================

  /// GET /api/eventos/all
  static Future<ApiResponse<List<Evento>>> obtenerEventos() async {
    final respuesta = await _get('/eventos/all');

    if (respuesta == null) {
      return ApiResponse<List<Evento>>.sinConexion(
        mensaje: _mensajeSinConexion,
      );
    }

    if (respuesta.statusCode == 200) {
      try {
        final lista = jsonDecode(respuesta.body) as List<dynamic>;
        final eventos = lista
            .map((item) => Evento.fromJson(item as Map<String, dynamic>))
            .toList();

        return ApiResponse<List<Evento>>.exito(
          datos: eventos,
          mensaje: 'Eventos cargados correctamente',
          codigoEstado: 200,
        );
      } catch (_) {
        return ApiResponse<List<Evento>>.error(
          mensaje: 'No se pudieron leer los eventos',
          codigoEstado: 200,
        );
      }
    }

    return _manejarError<List<Evento>>(respuesta);
  }

  /// GET /api/eventos/search?q="Query"&limit="Límite"
  static Future<ApiResponse<List<Evento>>> buscarEventos(String query) async {
    if (query.trim().isEmpty) {
      return ApiResponse<List<Evento>>.exito(
        datos: const [],
        mensaje: 'Introduce un término de búsqueda para encontrar eventos.',
        codigoEstado: 200,
      );
    }

    final uri = Uri.parse('$baseUrl/eventos/search').replace(
      queryParameters: {'q': query, 'limit': '10'},
    );
    final respuesta = await _getUri(uri);

    if (respuesta!.statusCode == 200) {
      try {
        final lista = jsonDecode(respuesta.body) as List<dynamic>;
        final eventos = lista
            .map((item) => Evento.fromJson(item as Map<String, dynamic>))
            .toList();

        return ApiResponse<List<Evento>>.exito(
          datos: eventos,
          mensaje: 'Eventos encontrados cargados correctamente',
          codigoEstado: 200,
        );
      } catch (_) {
        return ApiResponse<List<Evento>>.error(
          mensaje: 'No se pudieron leer los eventos',
          codigoEstado: 200,
        );
      }
    }

    return _manejarError<List<Evento>>(respuesta!);
  }

  /// GET /api/eventos/filter-by-categories?categorias=1&categorias=2...
  static Future<ApiResponse<List<Evento>>> obtenerEventosFiltradosPorCategorias(List<int> categorias) async {
    final queryString = categorias.map((c) => 'categorias=$c').join('&');
    final uri = Uri.parse('$baseUrl/eventos/filter-by-categories?$queryString');

    final respuesta = await _getUri(uri);

    if (respuesta == null) {
      return ApiResponse<List<Evento>>.sinConexion(
        mensaje: _mensajeSinConexion,
      );
    }

    if (respuesta.statusCode == 200) {
      try {
        final lista = jsonDecode(respuesta.body) as List<dynamic>;
        final eventos = lista
            .map((item) => Evento.fromJson(item as Map<String, dynamic>))
            .toList();

        return ApiResponse<List<Evento>>.exito(
          datos: eventos,
          mensaje: 'Eventos filtrados cargados correctamente',
          codigoEstado: 200,
        );
      } catch (e) {
        return ApiResponse<List<Evento>>.error(
          mensaje: 'No se pudieron leer los eventos filtrados: ${e.toString()}',
          codigoEstado: 200,
        );
      }
    }

    return _manejarError<List<Evento>>(respuesta);
  }

  // ============================================================================
  // USUARIO-EVENTOS
  // ============================================================================

  /// GET /api/usuario-eventos/guardados?emailUsuario=
  static Future<ApiResponse<List<Evento>>> obtenerEventosGuardados(String emailUsuario,) async {
    final uri = Uri.parse('$baseUrl/usuario-eventos/guardados').replace(
      queryParameters: {'emailUsuario': emailUsuario},
    );

    final respuesta = await _getUri(uri);

    if (respuesta == null) {
      return ApiResponse<List<Evento>>.sinConexion(
        mensaje: _mensajeSinConexion,
      );
    }

    if (respuesta.statusCode == 200) {
      try {
        final lista = jsonDecode(respuesta.body) as List<dynamic>;
        final eventos = lista
            .map((item) => Evento.fromJson(item as Map<String, dynamic>))
            .toList();

        return ApiResponse<List<Evento>>.exito(
          datos: eventos,
          mensaje: 'Eventos guardados cargados correctamente',
          codigoEstado: 200,
        );
      } catch (_) {
        return ApiResponse<List<Evento>>.error(
          mensaje: 'No se pudieron leer los eventos guardados',
          codigoEstado: 200,
        );
      }
    }

    return _manejarError<List<Evento>>(respuesta);
  }

  /// POST /api/usuario-eventos/guardar
  static Future<ApiResponse<void>> guardarEventoUsuario(String emailUsuario, String tituloEvento, DateTime fechaInicio, DateTime fechaFin) async {
    final respuesta = await _post('/usuario-eventos/guardar', {
      'emailUsuario': emailUsuario,
      'tituloEvento': tituloEvento,
      'fechaInicioEvento': fechaInicio.toIso8601String(),
      'fechaFinEvento': fechaFin.toIso8601String(),
    });

    if (respuesta == null) {
      return ApiResponse<void>.sinConexion(
        mensaje: _mensajeSinConexion,
      );
    }

    if (respuesta.statusCode == 201) {
      return ApiResponse<void>.exito(
        datos: null,
        mensaje: 'Evento guardado correctamente',
        codigoEstado: 201,
      );
    }

    return _manejarError<void>(respuesta);
  }

  /// DELETE /api/usuario-eventos/eliminar
  static Future<ApiResponse<void>> eliminarEventoUsuario(String emailUsuario, String tituloEvento, DateTime fechaInicio, DateTime fechaFin) async {
    final respuesta = await _delete('/usuario-eventos/eliminar', {
      'emailUsuario': emailUsuario,
      'tituloEvento': tituloEvento,
      'fechaInicioEvento': fechaInicio.toIso8601String(),
      'fechaFinEvento': fechaFin.toIso8601String(),
    });

    if (respuesta == null) {
      return ApiResponse<void>.sinConexion(
        mensaje: _mensajeSinConexion,
      );
    }

    if (respuesta.statusCode == 204) {
      return ApiResponse<void>.exito(
        datos: null,
        mensaje: 'Evento eliminado correctamente',
        codigoEstado: 204,
      );
    }

    return _manejarError<void>(respuesta);
  }

  // ============================================================================
  // CATEGORÍAS
  // ============================================================================

  /// GET /api/categorias/all
  static Future<ApiResponse<List<Categoria>>> obtenerCategorias() async {
    final respuesta = await _get('/categorias/all');

    if (respuesta == null) {
      return ApiResponse<List<Categoria>>.sinConexion(
        mensaje: _mensajeSinConexion,
      );
    }

    if (respuesta.statusCode == 200) {
      try {
        final lista = jsonDecode(respuesta.body) as List<dynamic>;
        final categorias = lista
            .map((item) => Categoria.fromJson(item as Map<String, dynamic>))
            .toList();

        return ApiResponse<List<Categoria>>.exito(
          datos: categorias,
          mensaje: 'Categorías cargadas correctamente',
          codigoEstado: 200,
        );
      } catch (e) {
        return ApiResponse<List<Categoria>>.error(
          mensaje: 'No se pudieron leer las categorías: ${e.toString()}',
          codigoEstado: 200,
        );
      }
    }

    return _manejarError<List<Categoria>>(respuesta);
  }

  // ============================================================================
  // PETICIONES HTTP
  // ============================================================================

  static Future<http.Response?> _get(String ruta) {
    return _solicitud(() => http.get(Uri.parse('$baseUrl$ruta')));
  }

  static Future<http.Response?> _getUri(Uri uri) {
    return _solicitud(() => http.get(uri));
  }

  static Future<http.Response?> _post(String ruta, Object cuerpo) {
    return _solicitud(() {
      return http.post(
        Uri.parse('$baseUrl$ruta'),
        headers: _cabecerasJson,
        body: jsonEncode(cuerpo),
      );
    });
  }

  static Future<http.Response?> _delete(String ruta, Object cuerpo) {
    return _solicitud(() {
      return http.delete(
        Uri.parse('$baseUrl$ruta'),
        headers: _cabecerasJson,
        body: jsonEncode(cuerpo),
      );
    });
  }

  static Future<http.Response?> _solicitud(Future<http.Response> Function() accion,) async {
    try {
      return await accion().timeout(_tiempoLimite);
    } on TimeoutException {
      return null;
    } on SocketException {
      return null;
    } catch (_) {
      return null;
    }
  }

  // ============================================================================
  // ERRORES
  // ============================================================================

  static ApiResponse<T> _manejarError<T>(http.Response respuesta) {
    final mensaje = _leerMensajeError(respuesta.body);

    switch (respuesta.statusCode) {
      case 400:
        return ApiResponse<T>.error(
          mensaje: mensaje.isEmpty ? 'Datos inválidos. Revisa los campos.' : mensaje,
          codigoEstado: 400,
        );

      case 401:
        return ApiResponse<T>.error(
          mensaje: mensaje.isEmpty ? 'Credenciales inválidas.' : mensaje,
          codigoEstado: 401,
        );

      case 403:
        return ApiResponse<T>.error(
          mensaje: mensaje.isEmpty ? 'No tienes permisos para realizar esta acción.' : mensaje,
          codigoEstado: 403,
        );

      case 404:
        return ApiResponse<T>.error(
          mensaje: mensaje.isEmpty ? 'Recurso no encontrado.' : mensaje,
          codigoEstado: 404,
        );

      case 409:
        return ApiResponse<T>.error(
          mensaje: mensaje.isEmpty ? 'Ya existe un conflicto con los datos enviados.' : mensaje,
          codigoEstado: 409,
        );

      case 500:
        return ApiResponse<T>.error(
          mensaje: 'Error interno del servidor. Intenta más tarde.',
          codigoEstado: 500,
        );

      default:
        return ApiResponse<T>.error(
          mensaje: mensaje.isEmpty ? 'Error desconocido (${respuesta.statusCode}).' : mensaje,
          codigoEstado: respuesta.statusCode,
        );
    }
  }

  static String _leerMensajeError(String cuerpo) {
    if (cuerpo.trim().isEmpty) return '';

    try {
      final decodificado = jsonDecode(cuerpo);

      if (decodificado is Map<String, dynamic>) {
        final mensaje = decodificado['mensaje'] ?? decodificado['message'] ?? decodificado['error'];
        return mensaje?.toString() ?? '';
      }
    } catch (_) {
      // Si no se puede leer el JSON del error, usamos el mensaje genérico.
    }

    return '';
  }
}