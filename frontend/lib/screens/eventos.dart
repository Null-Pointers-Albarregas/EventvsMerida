import 'package:eventvsmerida/models/evento.dart';
import 'package:eventvsmerida/widgets/componentes_compartidos.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/api_response.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import '../services/eventos_guardados_service.dart';

class Eventos extends StatefulWidget {
  const Eventos({super.key});

  @override
  State<Eventos> createState() => _EventosState();
}

class _EventosState extends State<Eventos> {
  // ===========================================================================
  // VARIABLES
  // ===========================================================================

  late Future<ApiResponse<List<Evento>>> _eventos;
  Usuario? _usuario;
  List<Evento> _eventosGuardados = [];

  ColorScheme get _cs => Theme.of(context).colorScheme;

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _eventos = ApiService.obtenerEventos();
    _cargarDatosUsuarioYGuardados();
  }

  // ===========================================================================
  // CARGA DE DATOS
  // ===========================================================================

  Future<void> _cargarDatosUsuarioYGuardados() async {
    final (usuario, guardados) =
    await EventosGuardadosService.cargarUsuarioYEventosGuardados();

    if (!mounted) return;

    setState(() {
      _usuario = usuario;
      _eventosGuardados = guardados;
    });
  }

  // ===========================================================================
  // FUNCIONES AUXILIARES
  // ===========================================================================

  bool _esMismoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _esHoraCero(DateTime fecha) {
    return fecha.hour == 0 && fecha.minute == 0;
  }

  String _formatearFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  String _formatearHora(DateTime fecha) {
    return DateFormat('HH:mm').format(fecha);
  }

  String _textoFechaHoraCard(Evento evento) {
    final esMismoDia = _esMismoDia(evento.fechaInicio, evento.fechaFin);
    final inicioFecha = _formatearFecha(evento.fechaInicio);
    final finFecha = _formatearFecha(evento.fechaFin);
    final inicioHora = _formatearHora(evento.fechaInicio);
    final finHora = _formatearHora(evento.fechaFin);
    final horasIguales = inicioHora == finHora;
    final ambasHorasCero = _esHoraCero(evento.fechaInicio) && _esHoraCero(evento.fechaFin);

    if (esMismoDia) {
      if (horasIguales && ambasHorasCero) {
        return 'Fecha: $inicioFecha';
      }
      if (horasIguales) {
        return 'Fecha: $inicioFecha · $inicioHora';
      }
      return 'Fecha: $inicioFecha · $inicioHora - $finHora';
    }

    if (horasIguales && ambasHorasCero) {
      return 'Fecha: $inicioFecha - $finFecha';
    }
    if (horasIguales) {
      return 'Fecha: $inicioFecha - $finFecha · $inicioHora';
    }
    return 'Fecha: $inicioFecha - $finFecha · $inicioHora - $finHora';
  }
/*
  String _textoFechaHoraDetalle(Evento evento) {
    final esMismoDia = _esMismoDia(evento.fechaInicio, evento.fechaFin);
    final inicioFecha = _formatearFecha(evento.fechaInicio);
    final finFecha = _formatearFecha(evento.fechaFin);
    final inicioHora = _formatearHora(evento.fechaInicio);
    final finHora = _formatearHora(evento.fechaFin);
    final horasIguales = inicioHora == finHora;
    final ambasHorasCero = _esHoraCero(evento.fechaInicio) && _esHoraCero(evento.fechaFin);

    if (esMismoDia) {
      if (horasIguales && ambasHorasCero) {
        return 'Fecha: $inicioFecha';
      }
      if (horasIguales) {
        return 'Fecha: $inicioFecha\nHora: $inicioHora';
      }
      return 'Fecha: $inicioFecha\nHora: $inicioHora - $finHora';
    }

    if (horasIguales && ambasHorasCero) {
      return 'Desde: $inicioFecha\nHasta: $finFecha';
    }

    return 'Desde: $inicioFecha $inicioHora\nHasta: $finFecha $finHora';
  }
*/

  // ===========================================================================
  // MODAL
  // ===========================================================================
  void _abrirModalEvento(Evento evento) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: ModalEvento(
          eventos: [evento],
          usuario: _usuario,
          eventosGuardados: _eventosGuardados,
          onEventosGuardadosActualizados: (nuevaLista) {
            setState(() {
              _eventosGuardados = nuevaLista;
            });
          },
        ),
      ),
    );
  }
/*
  Future<void> _abrirEnGoogleMaps(String direccion) async {
    final limpia = direccion.trim();
    final query = Uri.encodeComponent(limpia);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query',);

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

  Future<String> _guardarEvento(Evento evento, Usuario usuario) async {
    final respuesta = await ApiService.guardarEventoUsuario(usuario.email, evento.titulo, evento.fechaInicio, evento.fechaFin,);

    if (respuesta.exito) {
      setState(() {
        final yaEsta = _eventosGuardados.any((e) => _esMismoEvento(e, evento));
        if (!yaEsta) {
          _eventosGuardados.add(evento);
        }
      });
    }

    return respuesta.mensaje;
  }

  Future<String> _eliminarEvento(Evento evento, Usuario usuario) async {
    final respuesta = await ApiService.eliminarEventoUsuario(usuario.email, evento.titulo, evento.fechaInicio, evento.fechaFin,);

    if (respuesta.exito) {
      setState(() {
        _eventosGuardados.removeWhere((e) => _esMismoEvento(e, evento));
      });
    }

    return respuesta.mensaje;
  }

  // ===========================================================================
  // MENSAJES
  // ===========================================================================

  void _mostrarSnackBarResultado(BuildContext context, {required String mensaje, required bool guardado,}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              guardado ? Icons.check : Icons.delete,
              size: 20,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                mensaje,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: guardado ? Colors.green : Colors.red,
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

  // ===========================================================================
  // INTERFAZ
  // ===========================================================================

  void _abrirModalEvento(Evento evento, Usuario? usuario) {
    bool estaGuardado = _estaGuardado(evento);

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
                  // === FONDO DIFUMINADO DEL MODAL ===
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
                          color: _cs.surface,
                          borderRadius: BorderRadius.circular(16),
                          elevation: 12,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [

                              // === CABECERA DEL MODAL: TÍTULO Y BOTÓN CERRAR ===
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 10, 4, 0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        evento.titulo,
                                        style: _tt.titleMedium?.copyWith(
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

                              // === IMAGEN PRINCIPAL DEL EVENTO EN EL MODAL ===
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

                              // === INFORMACIÓN DETALLADA DEL EVENTO (LOCALIZACIÓN, FECHA, DESCRIPCIÓN) ===
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // --- Localización con botón Google Maps ---
                                      TextButton.icon(
                                        onPressed: () => _abrirEnGoogleMaps(evento.localizacion),
                                        icon: const Icon(
                                          Icons.place_outlined,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                        label: Text(
                                          evento.localizacion,
                                          style: _tt.bodyMedium?.copyWith(
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          alignment: Alignment.centerLeft,
                                          padding: EdgeInsets.zero,
                                        ),
                                      ),
                                      const SizedBox(height: 10),

                                      // --- Fecha y hora detallada ---
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.event_note, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _textoFechaHoraDetalle(evento),
                                              style: _tt.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                height: 1.35,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      // --- Descripción del evento ---
                                      Text(
                                        'Descripcion',
                                        style: _tt.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        evento.descripcion,
                                        style: _tt.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // === BOTÓN DE GUARDAR/ELIMINAR EVENTO ===
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: () async {
                                          if (usuario == null) {
                                            _mostrarModalNoLogeado();
                                            return;
                                          }

                                          setStateDialog(() {
                                            estaGuardado = !estaGuardado;
                                          });

                                          final mensaje = estaGuardado
                                              ? await _guardarEvento(evento, usuario)
                                              : await _eliminarEvento(evento, usuario);

                                          if (!mounted) return;

                                          _mostrarSnackBarResultado(
                                            context,
                                            mensaje: mensaje,
                                            guardado: estaGuardado,
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


  void _mostrarModalNoLogeado() {
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
                backgroundColor: _cs.surface.withValues(alpha: 0.98),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Título y botón cerrar ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: _cs.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Inicia sesion o registrate',
                            style: _tt.titleMedium?.copyWith(
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

                    // --- Mensaje informativo ---
                    Text(
                      'Para poder guardar un evento, tienes que iniciar sesion o registrarte.',
                      style: _tt.bodyMedium,
                    ),
                  ],
                ),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _cs.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            context.go(AppRoutes.registro);
                          },
                          child: const Text('Registrarse'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _cs.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            context.go(AppRoutes.login);
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
*/

  Widget _buildAppBarAction({
    required IconData icon,
    required String tooltip,
  }) {
    return IconButton(
      onPressed: null,
      icon: Icon(
        icon,
        color: _cs.primary.withValues(alpha: 0.5),
      ),
      tooltip: tooltip,
    );
  }

  Widget _buildEstadoCentro({
    required IconData icono,
    required String mensaje,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 42),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventoCard(Evento evento) {
    return Card(
      elevation: 6,
      shadowColor: _cs.onSurface,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _cs.onPrimary, width: 2),
      ),
      color: _cs.secondary,
      child: InkWell(
        onTap: () => _abrirModalEvento(evento),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === IMAGEN DEL EVENTO ===
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  evento.foto,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),

            // === INFORMACIÓN PRINCIPAL DEL EVENTO (TÍTULO, CATEGORÍA, LOCALIZACIÓN, FECHA) ===
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
  }

  Widget _buildBody() {
    return Center(
      child: FutureBuilder<ApiResponse<List<Evento>>>(
        future: _eventos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          if (snapshot.hasError) {
            return _buildEstadoCentro(
              icono: Icons.error_outline,
              mensaje: 'Error: ${snapshot.error}',
            );
          }

          final respuesta = snapshot.data;
          if (respuesta == null) {
            return _buildEstadoCentro(
              icono: Icons.error_outline,
              mensaje: 'No se han podido cargar los eventos',
            );
          }

          if (!respuesta.exito) {
            return _buildEstadoCentro(
              icono: Icons.error_outline,
              mensaje: respuesta.mensaje,
            );
          }

          final eventos = respuesta.datos ?? [];
          eventos.sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));
          if (eventos.isEmpty) {
            return _buildEstadoCentro(
              icono: Icons.event_busy,
              mensaje: 'No hay eventos disponibles',
            );
          }

          return ListView.builder(
            itemCount: eventos.length,
            itemBuilder: (context, indice) {
              return _buildEventoCard(eventos[indice]);
            },
          );
        },
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _buildAppBarAction(
                  icon: Icons.search,
                  tooltip: 'Buscar - Proximamente',
                ),
                _buildAppBarAction(
                  icon: Icons.filter_alt_rounded,
                  tooltip: 'Filtrar - Proximamente',
                ),
              ],
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}