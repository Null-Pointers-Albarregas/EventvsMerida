import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/evento.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import '../services/shared_preferences_service.dart';
import '../widgets/componentes_compartidos.dart';

class EventosGuardados extends StatefulWidget {
  const EventosGuardados({super.key});

  @override
  State<EventosGuardados> createState() => _EventosGuardadosState();
}

class _EventosGuardadosState extends State<EventosGuardados> {
  // ===========================================================================
  // VARIABLES
  // ===========================================================================

  Usuario? _usuario;
  List<Evento> _eventos = [];
  bool _cargando = true;

  ColorScheme get _cs => Theme.of(context).colorScheme;

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // ===========================================================================
  // CARGA DE DATOS
  // ===========================================================================

  Future<void> _cargarDatos() async {
    final usuario = await SharedPreferencesService.cargarUsuario();
    final respuesta = await ApiService.obtenerEventosGuardados(usuario!.email);

    if (!mounted) return;

    setState(() {
      _usuario = usuario;
      _eventos = respuesta.exito ? (respuesta.datos ?? []) : [];
      _cargando = false;
    });

    if (!respuesta.exito) {
      _mostrarMensajeCarga(respuesta.mensaje);
    }
  }

  // ===========================================================================
  // FUNCIONES AUXILIARES
  // ===========================================================================

  bool _esMismoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _esMismoEvento(Evento a, Evento b) {
    return a.titulo == b.titulo &&
        a.fechaInicio == b.fechaInicio &&
        a.fechaFin == b.fechaFin;
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

  Future<void> _borrarEvento(Evento evento) async {
    final email = _usuario?.email;
    if (email == null) return;

    final respuesta = await ApiService.eliminarEventoUsuario(
      email,
      evento.titulo,
      evento.fechaInicio,
      evento.fechaFin,
    );

    if (respuesta.exito) {
      setState(() {
        _eventos.removeWhere((e) => _esMismoEvento(e, evento));
      });
    }

    _mostrarMensajeEliminacion(respuesta.mensaje, respuesta.exito);
  }

  void _abrirModalEvento(Evento evento) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (ctx) => ModalEvento(
        eventos: [evento],
        usuario: _usuario,
        eventosGuardados: _eventos,
        onEventosGuardadosActualizados: (nuevaLista) {
          setState(() {
            _eventos = nuevaLista;
          });
        },
        mostrarBotonGuardado: false,
      ),
    );
  }

  // ===========================================================================
  // MENSAJES
  // ===========================================================================

  void _mostrarMensajeCarga(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  void _mostrarMensajeEliminacion(String mensaje, bool exito) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: exito ? Colors.red : Colors.orange,
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

  Widget _buildHeader() {
    return SafeArea(
      top: true,
      left: false,
      right: false,
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
        color: _cs.primary,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: _cs.surface),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).maybePop();
                      }
                    },
                  ),
                ),
                Center(
                  child: Text(
                    'Eventos guardados',
                    style: TextStyle(
                      color: _cs.surface,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            CircleAvatar(
              backgroundColor: _cs.surface.withValues(alpha: 0.9),
              radius: 45,
              child: Icon(Icons.person, color: _cs.primary, size: 45),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _contenidoVacio() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: _cs.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes eventos guardados',
            style: TextStyle(
              color: _cs.onSurface,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
          child: Icon(
            Icons.image,
            color: _cs.primary,
          ),
        ),
      ),
    );
  }

  Widget _tarjetaEvento(Evento evento) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _abrirModalEvento(evento),
          child: Container(
            decoration: BoxDecoration(
              color: _cs.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _cs.primary,
                width: 1,
              ),
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
                          _textoFechaEvento(evento),
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
                IconButton(
                  icon: Icon(Icons.delete, color: _cs.error),
                  onPressed: () => _borrarEvento(evento),
                  tooltip: 'Eliminar evento',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cs.surface,
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _eventos.isEmpty
                ? _contenidoVacio()
                : ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              itemCount: _eventos.length,
              itemBuilder: (context, index) => _tarjetaEvento(_eventos[index]),
            ),
          ),
        ],
      ),
    );
  }
}