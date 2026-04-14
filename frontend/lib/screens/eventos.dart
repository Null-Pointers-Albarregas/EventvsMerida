import 'dart:ui';

import 'package:eventvsmerida/models/evento.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/usuario.dart';
import '../services/api_service.dart';
import '../services/shared_preferences_service.dart';

class Eventos extends StatefulWidget {
  const Eventos({super.key});

  @override
  State<Eventos> createState() => _EventosState();
}

class _EventosState extends State<Eventos> {
  late Future<List<Evento>> _eventos;
  Usuario? _usuario;
  List<Evento> _eventosGuardados = [];

  @override
  void initState() {
    super.initState();
    _eventos = ApiService.obtenerEventos();
    _cargarDatos();
  }

  Future<void> _cargarEventosGuardados(Usuario usuario) async {
    final eventos = await ApiService.obtenerEventosGuardados(usuario.email);
    _eventosGuardados = eventos;
  }

  Future<void> _cargarDatos() async {
    final usuario = await SharedPreferencesService.cargarUsuario();
    if (!mounted) return;

    setState(() {
      _usuario = usuario;
    });

    if (_usuario != null) {
      await _cargarEventosGuardados(_usuario!);
      if (!mounted) return;
      setState(() {});
    }
  }

  bool _esMismoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _esMismoEvento(Evento a, Evento b) {
    return a.titulo == b.titulo &&
        a.fechaInicio == b.fechaInicio &&
        a.fechaFin == b.fechaFin;
  }

  String _formatearFecha(DateTime fecha) => DateFormat('dd/MM/yyyy').format(fecha);
  String _formatearHora(DateTime fecha) => DateFormat('HH:mm').format(fecha);

  String _textoFechaHoraCard(Evento evento) {
    final esMismoDia = _esMismoDia(evento.fechaInicio, evento.fechaFin);
    final inicioFecha = _formatearFecha(evento.fechaInicio);
    final finFecha = _formatearFecha(evento.fechaFin);
    final inicioHora = _formatearHora(evento.fechaInicio);
    final finHora = _formatearHora(evento.fechaFin);

    if (esMismoDia) {
      if (inicioHora == finHora && inicioHora == '00:00') {
        return 'Fecha: $inicioFecha';
      }
      if (inicioHora == finHora) {
        return 'Fecha: $inicioFecha · $inicioHora';
      }
      return 'Fecha: $inicioFecha · $inicioHora - $finHora';
    } else {
      if (inicioHora == finHora && inicioHora == '00:00') {
        return 'Fecha: $inicioFecha - $finFecha';
      }
      if (inicioHora == finHora) {
        return 'Fecha: $inicioFecha - $finFecha · $inicioHora';
      }
      return 'Fecha: $inicioFecha - $finFecha · $inicioHora - $finHora';
    }
  }

  String _textoFechaHoraDetalle(Evento evento) {
    final esMismoDia = _esMismoDia(evento.fechaInicio, evento.fechaFin);
    final inicioFecha = _formatearFecha(evento.fechaInicio);
    final finFecha = _formatearFecha(evento.fechaFin);
    final inicioHora = _formatearHora(evento.fechaInicio);
    final finHora = _formatearHora(evento.fechaFin);

    if (esMismoDia) {
      if (inicioHora == finHora && inicioHora == '00:00') {
        return 'Fecha: $inicioFecha';
      }
      if (inicioHora == finHora) {
        return 'Fecha: $inicioFecha\nHora: $inicioHora';
      }
      return 'Fecha: $inicioFecha\nHora: $inicioHora - $finHora';
    } else {
      if (inicioHora == finHora && inicioHora == '00:00') {
        return 'Desde: $inicioFecha\nHasta: $finFecha';
      }
      if (inicioHora == finHora) {
        return 'Desde: $inicioFecha $inicioHora\nHasta: $finFecha $finHora';
      }
      return 'Desde: $inicioFecha $inicioHora\nHasta: $finFecha $finHora';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onPrimary,
        title: SizedBox(
          height: 40,
          child: Image.asset(
            'assets/images/logo-eventvs-merida-no-bg.png',
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  onPressed: null,
                  icon: Icon(
                    Icons.search,
                    color: colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  tooltip: 'Buscar - Proximamente',
                ),
                IconButton(
                  onPressed: null,
                  icon: Icon(
                    Icons.filter_alt_rounded,
                    color: colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  tooltip: 'Filtrar - Proximamente',
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<List<Evento>>(
          future: _eventos,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            final eventos = snapshot.data ?? [];

            return ListView.builder(
              itemCount: eventos.length,
              itemBuilder: (context, indice) {
                final evento = eventos[indice];

                return Card(
                  elevation: 6,
                  shadowColor: colorScheme.onSurface,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colorScheme.onPrimary, width: 2),
                  ),
                  color: colorScheme.secondary,
                  child: InkWell(
                    onTap: () => _abrirModal(context, evento, _usuario),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              evento.foto,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                evento.titulo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                evento.nombreCategoria,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                evento.localizacion,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _textoFechaHoraCard(evento),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _abrirModal(BuildContext context, Evento evento, Usuario? usuario) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    bool estaGuardado = comprobarEstadoEvento(evento);

    showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: StatefulBuilder(
            builder: (dialogContext, setStateDialog) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  Scaffold(
                    backgroundColor: Colors.transparent,
                    body: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 500,
                          maxHeight: 700,
                        ),
                        child: Material(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          elevation: 12,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 10, 4, 0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        evento.titulo,
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      tooltip: 'Cerrar',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxHeight: 320,
                                          maxWidth: constraints.maxWidth,
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.contain,
                                          alignment: Alignment.topCenter,
                                          child: Image.network(evento.foto),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _abrirEnGoogleMaps(evento.localizacion),
                                        icon: const Icon(
                                          Icons.place_outlined,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                        label: Text(
                                          evento.localizacion,
                                          style: textTheme.bodyMedium?.copyWith(
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          alignment: Alignment.centerLeft,
                                          padding: EdgeInsets.zero,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.event_note, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _textoFechaHoraDetalle(evento),
                                              style: textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                height: 1.35,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Descripcion',
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        evento.descripcion,
                                        style: textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: () async {
                                          if (usuario == null) {
                                            _mostrarModalNoLogeado(context);
                                            return;
                                          }

                                          setStateDialog(() {
                                            estaGuardado = !estaGuardado;
                                          });

                                          String respuesta;
                                          if (estaGuardado) {
                                            respuesta = await _guardarEvento(evento, usuario);
                                          } else {
                                            respuesta = await _eliminarEvento(evento, usuario);
                                          }

                                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    estaGuardado ? Icons.check : Icons.delete,
                                                    size: 20,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    respuesta,
                                                    style: const TextStyle(color: Colors.white),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: estaGuardado ? Colors.green : Colors.red,
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
                                        },
                                        icon: Icon(
                                          estaGuardado
                                              ? Icons.bookmark
                                              : Icons.bookmark_border_outlined,
                                        ),
                                        label: Text(
                                          estaGuardado ? 'Evento guardado' : 'Guardar evento',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _abrirEnGoogleMaps(String direccion) async {
    final limpia = direccion.trim();
    final query = Uri.encodeComponent(limpia);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    try {
      final ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir Google Maps')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir Google Maps')),
      );
    }
  }

  bool comprobarEstadoEvento(Evento evento) {
    return _eventosGuardados.any((e) => _esMismoEvento(e, evento));
  }

  Future<String> _guardarEvento(Evento evento, Usuario usuario) async {
    final respuesta = await ApiService.guardarEventoUsuario(
      usuario.email,
      evento.titulo,
      evento.fechaInicio,
      evento.fechaFin,
    );

    if (respuesta == 'Evento guardado correctamente') {
      setState(() {
        final yaEsta = _eventosGuardados.any((e) => _esMismoEvento(e, evento));
        if (!yaEsta) {
          _eventosGuardados.add(evento);
        }
      });
      return respuesta;
    }

    return 'Ha ocurrido un problema al guardar el evento';
  }

  Future<String> _eliminarEvento(Evento evento, Usuario usuario) async {
    final respuesta = await ApiService.eliminarEventoUsuario(
      usuario.email,
      evento.titulo,
      evento.fechaInicio,
      evento.fechaFin,
    );

    if (respuesta == 'Evento eliminado correctamente') {
      setState(() {
        _eventosGuardados.removeWhere((e) => _esMismoEvento(e, evento));
      });
      return respuesta;
    }

    return 'Ha ocurrido un problema al eliminar el evento';
  }

  void _mostrarModalNoLogeado(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AlertDialog(
                backgroundColor: colorScheme.surface.withValues(alpha: 0.98),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Inicia sesion o registrate',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Para poder guardar un evento, tienes que iniciar sesion o registrarte.',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            context.go('/registro');
                            Navigator.of(ctx).pop();
                          },
                          child: const Text('Registrarse'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            context.go('/login');
                            Navigator.of(ctx).pop();
                          },
                          child: const Text(
                            'Iniciar sesion',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}