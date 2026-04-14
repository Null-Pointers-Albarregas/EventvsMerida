import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/evento.dart';
import '../models/usuario.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://eventvsmerida.onrender.com/api";

  static Future<Map<String, dynamic>> registrar(Map userData) async {
    try {
      final url = Uri.parse("$baseUrl/usuarios/add");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(userData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final usuario = Usuario.fromJson(data);
        return {'mensaje': "Registro exitoso", 'usuario': usuario};
      } else {
        String msg = "Error inesperado: ${response.statusCode}";
        if (response.statusCode == 400) msg = "Datos inválidos, revisa los campos";
        if (response.statusCode == 409) msg = "El correo ya está registrado";
        if (response.statusCode == 500) msg = "Error interno del servidor";
        return {'mensaje': msg, 'usuario': null};
      }
    } on TimeoutException {
      return {'mensaje': "El servidor tarda demasiado en responder", 'usuario': null};
    } on SocketException {
      return {'mensaje': "No hay conexión a internet", 'usuario': null};
    } catch (e) {
      return {'mensaje': "Error desconocido", 'usuario': null};
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/usuarios/login");

    try {
      final respuesta = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (respuesta.statusCode == 200) {
        final data = jsonDecode(respuesta.body);
        final usuario = Usuario.fromJson(data);
        return {'mensaje': "Login exitoso", 'usuario': usuario};
      } else {
        String msg = "Error en el servidor: ${respuesta.statusCode}";
        if (respuesta.statusCode == 404 || respuesta.statusCode == 400) msg = "Credenciales inválidas";
        return {'mensaje': msg, 'usuario': null};
      }
    } catch (e) {
      return {'mensaje': "Error desconocido", 'usuario': null};
    }
  }

  static Future<List<Evento>> obtenerEventos() async {
    final respuesta = await http.get(Uri.parse("$baseUrl/eventos/all"));

    if (respuesta.statusCode == 200) {
      final List<dynamic> eventos = jsonDecode(respuesta.body);
      return eventos.map((json) => Evento.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar los eventos');
    }
  }

  static Future<Map<DateTime, List<Evento>>> obtenerEventosParaCalendario() async {
    final datos = await obtenerEventos();
    final Map<DateTime, List<Evento>> mapa = {};

    for (final evento in datos) {
      final inicio = DateTime(
        evento.fechaInicio.year,
        evento.fechaInicio.month,
        evento.fechaInicio.day,
      );

      final fin = DateTime(
        evento.fechaFin.year,
        evento.fechaFin.month,
        evento.fechaFin.day,
      );

      var dia = inicio;
      while (!dia.isAfter(fin)) {
        mapa.putIfAbsent(dia, () => []);
        mapa[dia]!.add(evento);

        dia = dia.add(const Duration(days: 1));
        dia = DateTime(dia.year, dia.month, dia.day);
      }
    }

    return mapa;
  }

  static Future<String> guardarEventoUsuario(String emailUsuario, String tituloEvento, DateTime fechaInicio, DateTime fechaFin) async {
    final url = Uri.parse("$baseUrl/usuario-eventos/guardar");

    try {
      final respuesta = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'emailUsuario': emailUsuario, 'tituloEvento': tituloEvento, 'fechaInicioEvento': fechaInicio.toIso8601String(), 'fechaFinEvento': fechaFin.toIso8601String()}),
      );

      if (respuesta.statusCode == 200) {
        return "Evento guardado correctamente";
      } else {
        return "Error en el servidor: ${respuesta.statusCode}";
      }
    } catch (e) {
      return "Error desconocido";
    }
  }

  static Future<String> eliminarEventoUsuario(String emailUsuario, String tituloEvento, DateTime fechaInicio, DateTime fechaFin) async {
    final url = Uri.parse("$baseUrl/usuario-eventos/eliminar");

    try {
      final respuesta = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'emailUsuario': emailUsuario, 'tituloEvento': tituloEvento, 'fechaHoraEvento': fechaInicio.toIso8601String(), 'fechaFinEvento': fechaFin.toIso8601String()}),
      );

      if (respuesta.statusCode == 204) {
        return "Evento eliminado correctamente";
      } else {
        return "Error en el servidor: ${respuesta.statusCode}";
      }
    } catch (e) {
      return "Error desconocido" + e.toString();
    }
  }

  static Future<List<Evento>> obtenerEventosGuardados(String emailUsuario) async {
    final url = Uri.parse("$baseUrl/usuario-eventos/guardados?emailUsuario=$emailUsuario");

    try {
      final respuesta = await http.get(url);

      if (respuesta.statusCode == 200) {
        List<dynamic> datos = jsonDecode(respuesta.body);
        return datos.map((item) => Evento.fromJson(item)).toList();
      } else if (respuesta.statusCode == 404) {
        return [];
      } else {
        throw Exception("Error en el servidor: ${respuesta.statusCode}");
      }
    } catch (e) {
      throw Exception("Error desconocido");
    }
  }
}