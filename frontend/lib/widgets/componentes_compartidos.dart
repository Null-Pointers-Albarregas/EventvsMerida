import 'package:flutter/material.dart';

import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/router/app_routes.dart';
import '../models/evento.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';

// ===========================================================================
// 1. BARRA SUPERIOR (CustomAppBar)
// ===========================================================================
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  // Parámetro opcional por si en alguna pantalla quieres poner botones (como la lupa de buscar)
  final List<Widget>? actions;

  const CustomAppBar({super.key, this.actions});

  @override
  Widget build(BuildContext context) {
    final _cs = Theme.of(context).colorScheme;

    return AppBar(
      centerTitle: true,
      backgroundColor: _cs.surface,
      foregroundColor: _cs.onPrimary,
      title: SizedBox(
        height: 40,
        child: Image.asset(
          'assets/images/logo-eventvs-merida-no-bg.png',
          fit: BoxFit.contain,
        ),
      ),
      // Si la pantalla que llama a este AppBar le pasa botones, los dibuja. Si no, no pone nada.
      actions: actions,
    );
  }

  // Flutter necesita saber la altura estándar de un AppBar (que es 56.0)
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ===========================================================================
// 2. MODAL DE DETALLE DEL EVENTO
// ===========================================================================
class ModalEvento extends StatefulWidget {
  final List<Evento> eventos;
  final Usuario? usuario;
  final List<Evento> eventosGuardados;
  final ValueChanged<List<Evento>> onEventosGuardadosActualizados;
  //final bool isGuardadoInicial;
  //final Function(bool) onCambioGuardado;

  const ModalEvento({
    super.key,
    required this.eventos,
    required this.usuario,
    required this.eventosGuardados,
    required this.onEventosGuardadosActualizados,
  });

  @override
  State<ModalEvento> createState() => _ModalEventoState();
}

class _ModalEventoState extends State<ModalEvento> {
  late final PageController _pageController;
  int _indiceActual = 0;
  late List<Evento> _eventosGuardados;
  //late bool _estaGuardado;

  ColorScheme get _cs => Theme.of(context).colorScheme;
  TextTheme get _tt => Theme.of(context).textTheme;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _eventosGuardados = List.from(widget.eventosGuardados);
  }

  Evento get _eventoActual => widget.eventos[_indiceActual];

  bool _esMismoEvento(Evento a, Evento b) {
    return a.titulo == b.titulo &&
        a.fechaInicio == b.fechaInicio &&
        a.fechaFin == b.fechaFin;
  }

  bool _estaGuardado(Evento evento) {
    return _eventosGuardados.any((e) => _esMismoEvento(e, evento));
  }

  // --- Funciones auxiliares de formato de fecha ---
  bool _esMismoDia(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  bool _esHoraCero(DateTime fecha) => fecha.hour == 0 && fecha.minute == 0;
  String _formatearFecha(DateTime fecha) => DateFormat('dd/MM/yyyy').format(fecha);
  String _formatearHora(DateTime fecha) => DateFormat('HH:mm').format(fecha);

  String _textoFechaHoraDetalle(Evento evento) {
    final esMismoDia = _esMismoDia(evento.fechaInicio, evento.fechaFin);
    final inicioFecha = _formatearFecha(evento.fechaInicio);
    final finFecha = _formatearFecha(evento.fechaFin);
    final inicioHora = _formatearHora(evento.fechaInicio);
    final finHora = _formatearHora(evento.fechaFin);
    final horasIguales = inicioHora == finHora;
    final ambasHorasCero = _esHoraCero(evento.fechaInicio) && _esHoraCero(evento.fechaFin);

    if (esMismoDia) {
      if (horasIguales && ambasHorasCero) return 'Fecha: $inicioFecha';
      if (horasIguales) return 'Fecha: $inicioFecha\nHora: $inicioHora';
      return 'Fecha: $inicioFecha\nHora: $inicioHora - $finHora';
    }
    if (horasIguales && ambasHorasCero) return 'Desde: $inicioFecha\nHasta: $finFecha';
    return 'Desde: $inicioFecha $inicioHora\nHasta: $finFecha $finHora';
  }

  // --- Acciones ---
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

  void _mostrarSnackBarResultado({required String mensaje, required bool guardado}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(guardado ? Icons.check : Icons.delete, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(child: Text(mensaje, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: guardado ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _gestionarGuardado() async {
    final usuario = widget.usuario;
    final evento = _eventoActual;

    if (usuario == null) {
      _mostrarModalNoLogeado();
      return;
    }

    final yaGuardado = _estaGuardado(evento);

    final respuesta = yaGuardado
        ? await ApiService.eliminarEventoUsuario(
      usuario.email,
      evento.titulo,
      evento.fechaInicio,
      evento.fechaFin,
    )
        : await ApiService.guardarEventoUsuario(
      usuario.email,
      evento.titulo,
      evento.fechaInicio,
      evento.fechaFin,
    );

    if (!mounted) return;

    if (respuesta.exito) {
      setState(() {
        if (yaGuardado) {
          _eventosGuardados.removeWhere((e) => _esMismoEvento(e, evento));
        } else {
          _eventosGuardados.add(evento);
        }
      });

      widget.onEventosGuardadosActualizados(_eventosGuardados);
    }

    _mostrarSnackBarResultado(
      mensaje: respuesta.mensaje,
      guardado: respuesta.exito ? !yaGuardado : yaGuardado,
    );
  }

  // --- Modal para usuarios no registrados ---
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: _cs.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Inicia sesión o regístrate',
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
                    Text(
                      'Para poder guardar un evento, tienes que iniciar sesión o registrarte.',
                        style: _tt.bodyMedium
                    ),
                  ],
                ),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
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
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            context.go(AppRoutes.login);
                          },
                          child: const Text(
                            'Iniciar sesión',
                            overflow: TextOverflow.ellipsis
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

  Widget _buildContenidoEvento(Evento evento) {
    final estaGuardado = _estaGuardado(evento);

    return Column(
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
                  style: _tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Cerrar',
              ),
            ],
          ),
        ),
        if (widget.eventos.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${_indiceActual + 1} de ${widget.eventos.length} eventos en esta ubicación',
              style: _tt.bodySmall?.copyWith(
                color: _cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
                    child: Image.network(
                      evento.foto,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        height: 180,
                        child: Center(
                          child: Icon(Icons.broken_image, size: 40),
                        ),
                      ),
                    ),
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
                  icon: const Icon(Icons.place_outlined, size: 18),
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
                Text(
                  'Descripción',
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _gestionarGuardado,
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
    );
  }

  // --- Diseño del Modal Principal ---
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Stack(
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
                  color: _cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 12,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.eventos.length,
                    onPageChanged: (index) {
                      setState(() {
                        _indiceActual = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _buildContenidoEvento(widget.eventos[index]);
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
