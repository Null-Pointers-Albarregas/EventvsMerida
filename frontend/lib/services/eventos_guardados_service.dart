import '../models/evento.dart';
import '../models/usuario.dart';
import 'api_service.dart';
import 'package:eventvsmerida/services/shared_preferences_service.dart';

class EventosGuardadosService {
  static Future<(Usuario?, List<Evento>)> cargarUsuarioYEventosGuardados() async {
    final usuario = await SharedPreferencesService.cargarUsuario();

    List<Evento> guardados = [];

    if (usuario != null) {
      final respuestaGuardados = await ApiService.obtenerEventosGuardados(usuario.email);
      if (respuestaGuardados.exito) {
        guardados = respuestaGuardados.datos ?? [];
      }
    }

    return (usuario, guardados);
  }

  static bool estaGuardado(List<Evento> guardados, Evento evento) {
    return guardados.any((e) =>
    e.titulo == evento.titulo &&
        e.fechaInicio == evento.fechaInicio &&
        e.fechaFin == evento.fechaFin);
  }
}