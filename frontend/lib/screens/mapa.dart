import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
  static const double _altoOverlay = 350;

  ColorScheme get _cs => Theme.of(context).colorScheme;

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================

  // ===========================================================================
  // CARGA DE DATOS
  // ===========================================================================

  // ===========================================================================
  // FUNCIONES AUXILIARES
  // ===========================================================================

  // ===========================================================================
  // MENSAJES
  // ===========================================================================

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
          userAgentPackageName: 'com.tuapp.merida',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _merida,
              width: 80,
              height: 80,
              child: GestureDetector(
                onTap: () {
                  print("Tocado");
                },
                // AQUÍ ES DONDE LE PASAS LA RUTA REAL A TU WIDGET
                child: const PinConFoto(
                  imagePath: 'assets/images/logo-eventvs-merida.png',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverlayOscuro() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black.withValues(alpha: 0.15),
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
      body: Stack(
        children: [
          _buildMapa(),
          _buildOverlayOscuro(),
        ],
      ),
    );
  }
}

// Widget personalizado para el pin con forma clásica y foto
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