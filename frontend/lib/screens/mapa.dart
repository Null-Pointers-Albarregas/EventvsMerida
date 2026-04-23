import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/evento.dart';
import '../services/api_service.dart';
import '../widgets/componentes_compartidos.dart';

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

  Map<String, List<Evento>> _eventosAgrupados = {};
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

      // 1. Filtramos: Solo eventos con coordenadas y que AÚN NO han terminado
      final eventosValidos = respuesta.datos!.where((evento) {
        final tieneCoordenadas = evento.latitud != null && evento.longitud != null;
        final noHaTerminado = evento.fechaFin.isAfter(ahora);
        return tieneCoordenadas && noHaTerminado;
      }).toList();

      // 2. Ordenamos: Comparamos las fechas de inicio para que el más cercano esté el primero
      eventosValidos.sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));

      // 3. Recortamos: Nos quedamos estrictamente con los 10 primeros de la lista ordenada
      final losDiezProximos = eventosValidos.take(10).toList();

      // 4. AGRUPAMOS POR COORDENADAS
      Map<String, List<Evento>> agrupados = {};
      for (var evento in losDiezProximos) {
        // Creamos una llave única con la latitud y longitud
        String claveUbicacion = '${evento.latitud},${evento.longitud}';

        // Si la llave no existe, crea una lista vacía. Luego añade el evento.
        agrupados.putIfAbsent(claveUbicacion, () => []).add(evento);
      }

      setState(() {
        _eventosAgrupados = agrupados;
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
  void _mostrarDetalleEvento(List<Evento> eventosEnLugar) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cs.surface,
      isScrollControlled: true, // Permite que el modal sea un poco más grande
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eventosEnLugar.length > 1)
                  Text(
                    '📍 ${eventosEnLugar.length} eventos en esta ubicación',
                    style: TextStyle(color: _cs.primary, fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 8),
                // Carrusel de eventos
                SizedBox(
                  height: 200, // Altura fija para la tarjeta del evento
                  child: PageView.builder(
                    itemCount: eventosEnLugar.length,
                    controller: PageController(viewportFraction: 0.9), // Muestra un trocito del siguiente evento
                    itemBuilder: (context, index) {
                      final evento = eventosEnLugar[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        color: _cs.secondary.withValues(alpha: 0.3), // Un fondo sutil
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                evento.titulo,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _cs.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                evento.localizacion,
                                style: TextStyle(color: _cs.primary, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Text(
                                  evento.descripcion,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: _cs.onSurface.withValues(alpha: 0.7)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ),
                ),
              ],
            ),
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
          markers: _eventosAgrupados.values.map((listaEventosEnEsteLugar) {
            // Cogemos el primer evento solo para saber dónde poner el pin
            final primerEvento = listaEventosEnEsteLugar.first;
            return Marker(
              point: LatLng(primerEvento.latitud!, primerEvento.longitud!),
              width: 55,
              height: 65,
              alignment: Alignment.topCenter,
              child: GestureDetector(
                // Pasamos LA LISTA ENTERA al BottomSheet
              onTap: () => _mostrarDetalleEvento(listaEventosEnEsteLugar),
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
    final ColorScheme _cs = Theme.of(context).colorScheme;

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
            color: _cs.primary,
          ),

          // 2. La foto posicionada en el centro de la "cabeza" del pin
          Positioned(
            top: 8, // Bajamos la foto un poquito para que encaje en el círculo del icono
            right: 6,
            child: CircleAvatar(
              radius: 17,
              child: CircleAvatar(
                radius: 16, // La imagen real un poquito más pequeña
                backgroundImage: AssetImage(imagePath),
              ),
            ),
          ),
        ],
      ),
    );
  }
}