import 'package:flutter/material.dart';

import 'dart:ui';
import 'package:flutter/material.dart';
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
// 2. MODAL DE DETALLE DEL EVENTO (ModalEvento)
// ===========================================================================
class ModalEvento extends StatefulWidget {
  final Evento evento;
  final Usuario? usuario;
  final bool isGuardadoInicial;
  final Function(bool) onCambioGuardado;

  const ModalEvento({
    super.key,
    required this.evento,
    required this.usuario,
    required this.isGuardadoInicial,
    required this.onCambioGuardado,
  });

  @override
  State<ModalEvento> createState() => _ModalEventoState();
}

class _ModalEventoState extends State<ModalEvento> {
  late bool _estaGuardado;

  ColorScheme get _cs => Theme.of(context).colorScheme;
  TextTheme get _tt => Theme.of(context).textTheme;

  @override
  void initState() {
    super.initState();
    _estaGuardado = widget.isGuardadoInicial;
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir Google Maps')));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir Google Maps')));
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
    if (widget.usuario == null) {
      _mostrarModalNoLogeado();
      return;
    }

    setState(() => _estaGuardado = !_estaGuardado);
    widget.onCambioGuardado(_estaGuardado);

    final respuesta = _estaGuardado
        ? await ApiService.guardarEventoUsuario(widget.usuario!.email, widget.evento.titulo, widget.evento.fechaInicio, widget.evento.fechaFin)
        : await ApiService.eliminarEventoUsuario(widget.usuario!.email, widget.evento.titulo, widget.evento.fechaInicio, widget.evento.fechaFin);

    if (mounted) _mostrarSnackBarResultado(mensaje: respuesta.mensaje, guardado: _estaGuardado);
  }

  // --- Modal para usuarios no registrados ---
  void _mostrarModalNoLogeado() {
    showDialog<void>(
      context: context,
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
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: _cs.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Inicia sesión o regístrate', style: _tt.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Para poder guardar un evento, tienes que iniciar sesión o registrarte.', style: _tt.bodyMedium),
                  ],
                ),
                actions: [
                  Row(
                    children: [
                      Expanded(child: FilledButton(onPressed: () { Navigator.of(ctx).pop(); context.go(AppRoutes.registro); }, child: const Text('Registrarse'))),
                      const SizedBox(width: 8),
                      Expanded(child: FilledButton(onPressed: () { Navigator.of(ctx).pop(); context.go(AppRoutes.login); }, child: const Text('Iniciar sesión', overflow: TextOverflow.ellipsis))),
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

  // --- Diseño del Modal Principal ---
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: Container(color: Colors.transparent))),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
              child: Material(
                color: _cs.surface,
                borderRadius: BorderRadius.circular(16),
                elevation: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 4, 0),
                      child: Row(
                        children: [
                          Expanded(child: Text(widget.evento.titulo, style: _tt.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis)),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 320),
                          child: FittedBox(fit: BoxFit.contain, alignment: Alignment.topCenter, child: Image.network(widget.evento.foto)),
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
                              onPressed: () => _abrirEnGoogleMaps(widget.evento.localizacion),
                              icon: const Icon(Icons.place_outlined, size: 18, color: Colors.white),
                              label: Text(widget.evento.localizacion, style: _tt.bodyMedium?.copyWith(decoration: TextDecoration.underline)),
                              style: TextButton.styleFrom(alignment: Alignment.centerLeft, padding: EdgeInsets.zero),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.event_note, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_textoFechaHoraDetalle(widget.evento), style: _tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.35))),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text('Descripción', style: _tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(widget.evento.descripcion, style: _tt.bodyMedium),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _gestionarGuardado,
                          icon: Icon(_estaGuardado ? Icons.bookmark : Icons.bookmark_border_outlined),
                          label: Text(_estaGuardado ? 'Evento guardado' : 'Guardar evento'),
                        ),
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
  }
}