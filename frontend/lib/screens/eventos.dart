import 'dart:async';
import 'dart:ui';

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

  String _textoBusqueda = '';
  late Future<ApiResponse<List<Evento>>> _eventos;
  late Future<ApiResponse<List<Evento>>> _eventosEncontrados;
  Usuario? _usuario;
  List<Evento> _eventosGuardados = [];
  Timer? _debounce;
  final _inputBusquedaController = TextEditingController();
  bool _modalBusquedaAbierto = false;

  ColorScheme get _cs => Theme.of(context).colorScheme;

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _eventos = ApiService.obtenerEventos();
    _eventosEncontrados = ApiService.buscarEventos(_textoBusqueda);
    _cargarDatosUsuarioYGuardados();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _inputBusquedaController.dispose();
    super.dispose();
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

  void _buscarEventos(
    String text,
    void Function(void Function()) setStateModal,
  ) {
    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || !_modalBusquedaAbierto) {
        return;
      }
      _textoBusqueda = text;
      _eventosEncontrados = ApiService.buscarEventos(_textoBusqueda);
      setStateModal(() {});
    });
  }

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
    final ambasHorasCero =
        _esHoraCero(evento.fechaInicio) && _esHoraCero(evento.fechaFin);

    if (esMismoDia) {
      if (horasIguales && ambasHorasCero) return 'Fecha: $inicioFecha';
      if (horasIguales) return 'Fecha: $inicioFecha · $inicioHora';
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

  // ===========================================================================
  // MODALES
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
            setState(() => _eventosGuardados = nuevaLista);
          },
          mostrarBotonGuardado: true,
        ),
      ),
    );
  }

  Widget _buildModalBusqueda(void Function(void Function()) setStateModal) {
    return Dialog(
      backgroundColor: Colors.transparent,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cs.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _inputBusquedaController,
              decoration: InputDecoration(
                hintText: 'Buscar eventos...',
                prefixIcon: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    _modalBusquedaAbierto = false;
                    _debounce?.cancel();
                    Navigator.of(context, rootNavigator: true).maybePop();
                  },
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    if (!_modalBusquedaAbierto) {
                      return;
                    }
                    _inputBusquedaController.clear();
                    _textoBusqueda = '';
                    _eventosEncontrados = ApiService.buscarEventos(
                      _textoBusqueda,
                    );
                    setStateModal(() {});
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (text) => _buscarEventos(text, setStateModal),
            ),
            const SizedBox(height: 12),
            _buildBody(_eventosEncontrados, 'busqueda'),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // INTERFAZ
  // ===========================================================================

  Widget _buildAppBarAction({
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: _cs.primary),
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
            Text(mensaje, textAlign: TextAlign.center),
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
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
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    evento.localizacion,
                    style: const TextStyle(color: Colors.black, fontSize: 14),
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

  Widget _imagenEvento(String foto) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(18),
        bottomLeft: Radius.circular(18),
      ),
      child: Image.network(
        foto,
        width: 100,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 100,
          height: 110,
          color: _cs.secondary.withAlpha(51),
          child: Icon(Icons.image, color: _cs.primary),
        ),
      ),
    );
  }

  Widget _buildEventoBusquedaCard(Evento evento) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _abrirModalEvento(evento),
          child: Container(
            decoration: BoxDecoration(
              color: _cs.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _cs.primary, width: 1),
              boxShadow: [
                BoxShadow(
                  color: _cs.onPrimary.withAlpha(64),
                  blurRadius: 5,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                _imagenEvento(evento.foto),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          evento.titulo,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _cs.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          evento.localizacion,
                          style: TextStyle(
                            color: _cs.onSurface.withAlpha(178),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_formatearFecha(evento.fechaInicio)} · ${_formatearHora(evento.fechaInicio)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: _cs.onSurface,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    Future<ApiResponse<List<Evento>>> listadoEventos,
    String tipo,
  ) {
    return Center(
      child: FutureBuilder<ApiResponse<List<Evento>>>(
        future: listadoEventos,
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
          if (respuesta == null || !respuesta.exito) {
            return _buildEstadoCentro(
              icono: Icons.error_outline,
              mensaje:
                  respuesta?.mensaje ?? 'No se han podido cargar los eventos',
            );
          }

          final eventos = List<Evento>.from(respuesta.datos ?? const []);
          if (tipo.isEmpty) {
            eventos.sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));
          }

          if (tipo == 'busqueda' && _textoBusqueda.isEmpty) {
            return _buildEstadoCentro(
              icono: Icons.search,
              mensaje: 'Ingresa un término de búsqueda para encontrar eventos',
            );
          }

          if (eventos.isEmpty) {
            return _buildEstadoCentro(
              icono: tipo == 'busqueda' ? Icons.search_off : Icons.event_busy,
              mensaje: tipo == 'busqueda'
                  ? 'No se han encontrado eventos para "$_textoBusqueda"'
                  : 'No hay eventos disponibles',
            );
          }

          if (tipo == 'busqueda') {
            const double itemHeight = 140;
            final int visibleCount = eventos.length < 3 ? eventos.length : 3;
            final double maxHeight = itemHeight * visibleCount;

            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: eventos.length,
                itemBuilder: (context, index) {
                  return _buildEventoBusquedaCard(eventos[index]);
                },
              ),
            );
          }

          return ListView.builder(
            itemCount: eventos.length,
            itemBuilder: (context, index) {
              return tipo == 'busqueda'
                  ? _buildEventoBusquedaCard(eventos[index])
                  : _buildEventoCard(eventos[index]);
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
                  tooltip: 'Buscar',
                  onPressed: () {
                    _modalBusquedaAbierto = true;
                    showDialog(
                      context: context,
                      useRootNavigator: true,
                      barrierDismissible: true,
                      barrierColor: Colors.black.withValues(alpha: 0.15),
                      builder: (ctx) {
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: IgnorePointer(
                                ignoring: true,
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                                  child: Container(color: Colors.transparent),
                                ),
                              ),
                            ),
                            StatefulBuilder(
                              builder: (context, setStateModal) {
                                return _buildModalBusqueda(setStateModal);
                              },
                            ),
                          ],
                        );
                      },
                    ).then((_) {
                      _modalBusquedaAbierto = false;
                      _debounce?.cancel();
                      if (!mounted) {
                        return;
                      }
                      _inputBusquedaController.clear();
                      _textoBusqueda = '';
                      _eventosEncontrados = ApiService.buscarEventos(
                        _textoBusqueda,
                      );
                      setState(() {});
                    });
                  },
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
      body: _buildBody(_eventos, ''),
    );
  }
}