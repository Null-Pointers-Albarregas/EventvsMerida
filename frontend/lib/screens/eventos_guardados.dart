import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/evento.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import '../services/shared_preferences_service.dart';

class EventosGuardados extends StatefulWidget {
  const EventosGuardados({super.key});

  @override
  State<EventosGuardados> createState() => _EventosGuardadosState();
}

class _EventosGuardadosState extends State<EventosGuardados> {
  Usuario? _usuario;
  List<Evento> _eventos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  bool _esMismoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _fecha(DateTime fecha) => DateFormat('dd/MM/yyyy').format(fecha);
  String _hora(DateTime fecha) => DateFormat('HH:mm').format(fecha);

  String _textoFechaEvento(Evento evento) {
    if (_esMismoDia(evento.fechaInicio, evento.fechaFin)) {
      return 'Fecha: ${_fecha(evento.fechaInicio)} · ${_hora(evento.fechaInicio)} - ${_hora(evento.fechaFin)}';
    }

    return 'Desde: ${_fecha(evento.fechaInicio)} ${_hora(evento.fechaInicio)}\n'
        'Hasta: ${_fecha(evento.fechaFin)} ${_hora(evento.fechaFin)}';
  }

  Future<void> _cargarDatos() async {
    final usuario = await SharedPreferencesService.cargarUsuario();

    if (usuario == null) {
      if (!mounted) return;
      setState(() {
        _usuario = null;
        _eventos = [];
        _cargando = false;
      });
      return;
    }

    final respuesta = await ApiService.obtenerEventosGuardados(usuario.email);

    if (!mounted) return;
    setState(() {
      _usuario = usuario;
      _eventos = respuesta.exito ? (respuesta.datos ?? []) : [];
      _cargando = false;
    });

    if (!respuesta.exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(respuesta.mensaje)),
      );
    }
  }

  Future<void> _borrarEvento(Evento evento) async {
    if (_usuario == null) return;

    final respuesta = await ApiService.eliminarEventoUsuario(
      _usuario!.email,
      evento.titulo,
      evento.fechaInicio,
      evento.fechaFin,
    );

    if (respuesta.exito) {
      setState(() {
        _eventos.removeWhere((e) =>
        e.titulo == evento.titulo &&
            e.fechaInicio == evento.fechaInicio &&
            e.fechaFin == evento.fechaFin);
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                respuesta.mensaje,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: respuesta.exito ? Colors.red : Colors.orange,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _cabecera(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      color: colorScheme.primary,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.surface.withValues(alpha: 0.9),
            radius: 45,
            child: Icon(Icons.person, color: colorScheme.primary, size: 45),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.surface,
        centerTitle: true,
        title: const Text('Eventos guardados'),
        elevation: 2,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _eventos.isEmpty
          ? Column(
        children: [
          _cabecera(colorScheme),
          Expanded(
            child: Center(
              child: Text(
                'No tienes eventos guardados',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      )
          : ListView(
        padding: EdgeInsets.zero,
        children: [
          _cabecera(colorScheme),
          const SizedBox(height: 16),
          ..._eventos.map(
                (evento) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: colorScheme.primary,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.onPrimary.withAlpha(64),
                      blurRadius: 5,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                      ),
                      child: Image.network(
                        evento.foto,
                        width: 100,
                        height: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              width: 100,
                              height: 110,
                              color: colorScheme.secondary.withAlpha(51),
                              child: Icon(
                                Icons.image,
                                color: colorScheme.primary,
                              ),
                            ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              evento.titulo,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: colorScheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              evento.localizacion,
                              style: TextStyle(
                                color: colorScheme.onSurface
                                    .withAlpha(178),
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _textoFechaEvento(evento),
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurface,
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: colorScheme.error),
                      onPressed: () => _borrarEvento(evento),
                      tooltip: 'Eliminar evento',
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}