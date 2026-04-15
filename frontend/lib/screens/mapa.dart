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
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.none,
        ),
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
              child: Icon(
                Icons.location_on,
                color: _cs.primary,
                size: 40,
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

  Widget _buildAvisoProximamente() {
    return Positioned(
      top: _altoOverlay,
      left: 8,
      right: 8,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        color: _cs.surface.withValues(alpha: 0.95),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: _cs.primary,
                size: 30,
              ),
              const SizedBox(width: 30),
              Expanded(
                child: Text(
                  'Proximamente...',
                  style: TextStyle(
                    color: _cs.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
      body: Stack(
        children: [
          _buildMapa(),
          _buildOverlayOscuro(),
          _buildAvisoProximamente(),
        ],
      ),
    );
  }
}