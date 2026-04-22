import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/evento.dart';
import '../services/api_service.dart';
import '../widgets/customizar_app_bar.dart';

class Mapa extends StatefulWidget {
  const Mapa({super.key});

  @override
  State<Mapa> createState() => _MapaState();
}

class _MapaState extends State<Mapa> {
  // ===========================================================================
  // VARIABLES
  // ===========================================================================

  static const LatLng _merida = LatLng(38.9161, -6.3437);
  static const double _zoomInicial = 14.0;

  List<Evento> _eventosMapa = [];
  bool _cargando = true;

  ColorScheme get _cs => Theme.of(context).colorScheme;

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================
  @override
  void initState() {
    super.initState();
    _cargarEventosParaMapa();
  }
  // ===========================================================================
  // CARGA DE DATOS
  // ===========================================================================
  Future<void> _cargarEventosParaMapa() async {
    setState(() => _cargando = true);

    final respuesta = await ApiService.obtenerEventos();

    if (!mounted) return;

    if (respuesta.exito && respuesta.datos != null) {
      final ahora = DateTime.now();
      final limite7Dias = ahora.add(const Duration(days: 7));

      // Filtramos la lista
      final filtrados = respuesta.datos!.where((evento) {
        // 1. Verificamos que tenga coordenadas (ahora que las has añadido a la BD)
        final tieneCoordenadas = evento.latitud != null && evento.longitud != null;

        // 2. Verificamos que esté en el rango de los próximos 7 días
        final enRangoFecha = evento.fechaFin.isAfter(ahora) &&
            evento.fechaInicio.isBefore(limite7Dias);

        return tieneCoordenadas && enRangoFecha;
      }).toList();

      setState(() {
        _eventosMapa = filtrados;
        _cargando = false;
      });
    } else {
      setState(() => _cargando = false);
      _mostrarMensaje(respuesta.mensaje);
    }
  }
  // ===========================================================================
  // FUNCIONES AUXILIARES
  // ===========================================================================
  void _mostrarDetalleEvento(Evento evento) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                evento.titulo,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "📍 ${evento.localizacion}",
                style: TextStyle(color: _cs.primary, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Text(
                evento.descripcion,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _cs.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  // ===========================================================================
  // MENSAJES
  // ===========================================================================
  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }
  // ===========================================================================
  // INTERFAZ
  // ===========================================================================

  Widget _buildMapa() {
    return FlutterMap(
      options: const MapOptions(
        initialCenter: _merida,
        initialZoom: _zoomInicial,

      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'es.nullpointers.eventvsmerida',
        ),
        MarkerLayer(
          markers: _eventosMapa.map((evento) {
            return Marker(
              point: LatLng(evento.latitud!, evento.longitud!),
              width: 55,
              height: 65,
              alignment: Alignment.topCenter,
              child: GestureDetector(
              onTap: () => _mostrarDetalleEvento(evento),
                child: const PinConFoto(
                 imagePath: 'assets/images/logo-eventvs-merida.png',
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }


  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Stack(
        children: [
          _buildMapa(),
          if(_cargando)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

// ===========================================================================
// WIDGET DEL PIN
// ===========================================================================

class PinConFoto extends StatelessWidget {
  final String imagePath; // Ruta a la foto (asset o URL)

  const PinConFoto({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    // Obtenemos los colores dinámicos del tema
    final ColorScheme cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: 55, // Ancho total del área
      height: 65, // Alto total del área
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // 1. El icono del pin clásico de fondo (Se pone azul o naranja automático)
          Icon(
            Icons.location_on,
            size: 65,
            color: cs.primary,
          ),

          // 2. La foto posicionada en el centro de la "cabeza" del pin
          Positioned(
            top: 7, // Bajamos la foto un poquito para que encaje en el círculo del icono
            child: CircleAvatar(
              radius: 17,
              backgroundColor: cs.surface, // Borde blanco (claro) o negro (oscuro)
              child: CircleAvatar(
                radius: 15, // La imagen real un poquito más pequeña
                backgroundImage: AssetImage(imagePath),
              ),
            ),
          ),
        ],
      ),
    );
  }
}