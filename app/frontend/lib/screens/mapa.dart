import 'package:eventvsmerida/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../models/evento.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import '../services/eventos_guardados_service.dart';
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

  // Variables para gestionar el guardado y el usuario (igual que en eventos.dart)
  Usuario? _usuario;
  List<Evento> _eventosGuardados = [];
  GlobalKey keyPinLocalizacion = GlobalKey();

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================
  @override
  void initState() {
    super.initState();
    _cargarUsuarioYGuardados(); // Cargamos la sesión primero
    _cargarEventosParaMapa();
  }

  bool _targetEstaListo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return false;

    final renderObject = ctx.findRenderObject();
    return renderObject is RenderBox &&
        renderObject.attached &&
        renderObject.hasSize;
  }

  // ===========================================================================
  // CARGA DE DATOS
  // ===========================================================================
  Future<void> _cargarUsuarioYGuardados() async {
    final (usuario, guardados) =
    await EventosGuardadosService.cargarUsuarioYEventosGuardados();

    if (!mounted) return;

    setState(() {
      _usuario = usuario;
      _eventosGuardados = guardados;
    });
  }

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
      final losVeinteProximos = eventosValidos.take(20).toList();

      // 4. AGRUPAMOS POR COORDENADAS
      final Map<String, List<Evento>> agrupados = {};
      for (final evento in losVeinteProximos) {
        // Creamos una llave única con la latitud y longitud
        final claveUbicacion = '${evento.latitud},${evento.longitud}';

        // Si la llave no existe, crea una lista vacía. Luego añade el evento.
        agrupados.putIfAbsent(claveUbicacion, () => []).add(evento);
      }

      setState(() {
        _eventosAgrupados = agrupados;
        _cargando = false;
      });

      if(await SharedPreferencesService.cargarTutorial()) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await Future.delayed(const Duration(milliseconds: 400));
          if (!mounted) return;
          _comprobarInicializacionTutorial();
        });
      }
    } else {
      setState(() => _cargando = false);
      _mostrarMensaje(respuesta.mensaje);
    }
  }

  void _comprobarInicializacionTutorial() {
    if (!mounted) return;
    if (Tutorial.numPantalla != 2) return;
    if (Tutorial.tutorialInicializado) return;
    if (_cargando) return;
    if (_eventosAgrupados.isEmpty) return;
    if (!_targetEstaListo(keyPinLocalizacion)) return;

    Tutorial.tutorialInicializado = true;
    _configurarTutorial();
  }
  // ===========================================================================
  // FUNCIONES AUXILIARES
  // ===========================================================================
  void _abrirModalEvento(List<Evento> eventoEnLugar) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (ctx) => ModalEvento(
        eventos: eventoEnLugar,
        usuario: _usuario,
        eventosGuardados: _eventosGuardados,
        onEventosGuardadosActualizados: (nuevaLista) {
          setState(() {
            _eventosGuardados = nuevaLista;
          });
        },
        mostrarBotonGuardado: true,
        mostrarFlechasDeslizamiento: true,
      ),
    );
  }

  // ===========================================================================
  // MENSAJES
  // ===========================================================================
  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
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
            final primerEvento = listaEventosEnEsteLugar.first;
            final esPrimerPin = listaEventosEnEsteLugar == _eventosAgrupados.values.first;

            return Marker(
              point: LatLng(primerEvento.latitud!, primerEvento.longitud!),
              width: 55,
              height: 65,
              alignment: Alignment.topCenter,
              child: GestureDetector(
                key: esPrimerPin ? keyPinLocalizacion : null,
                onTap: () => _abrirModalEvento(listaEventosEnEsteLugar),
                child: PinConFoto(
                  imagePath: 'assets/images/logo-eventvs-merida.png',
                  cantidadEventos: listaEventosEnEsteLugar.length,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ===========================================================================
  // TUTORIAL
  // ===========================================================================

  void _configurarTutorial() {
    Tutorial.navPasoActivo.value = false;
    Tutorial.pasosTutorial.clear();
    cargarPasosTutorial();
    Tutorial.tutorial = Tutorial.crearTutorial(
      context: context,
      pasosTutorial: Tutorial.pasosTutorial,
      color: Theme.of(context).colorScheme.primary,
    );
    Tutorial.mostrarTutorial(context);
  }

  void cargarPasosTutorial() {
    Tutorial.pasosTutorial.add(
      Tutorial.crearPaso(
          context: context,
          key: keyPinLocalizacion,
          titulo: 'Localización ',
          descripcion: 'En estos pines puedes visualizar y ubicar los eventos en el mapa de Mérida. Si pulsas en uno de ellos, podrás ver nuevamente en detalle este.',
          icon: Icons.event,
          siguiente: true,
          onNext: () => Tutorial.tutorial.next(),
      ),
    );
    Tutorial.pasosTutorial.add(
      Tutorial.crearPaso(
        context: context,
        key: Tutorial.keyNavCalendario,
        titulo: 'Calendario',
        descripcion: 'Ahora pasemos al calendario para ver sus funcionalidades.',
        icon: Icons.calendar_month,
        siguiente: true,
        onNext: () async {
          Tutorial.navPasoActivo.value = false;
          Tutorial.numPantalla = 3;
          Tutorial.tutorialInicializado = false;
          Tutorial.tutorial.finish();

          await Future.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;
          context.go('/calendario');
        },
        alineamientoTarjeta: ContentAlign.top,
      ),
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
  final String imagePath;
  final int cantidadEventos;

  const PinConFoto({super.key, required this.imagePath, required this.cantidadEventos});

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
          Icon(
            Icons.location_on,
            size: 65,
            color: _cs.primary,
          ),

          Positioned(
            top: 8,
            right: 6,
            child: CircleAvatar(
              radius: 17,
              child: CircleAvatar(
                radius: 16,
                backgroundImage: AssetImage(imagePath),
              ),
            ),
          ),
          if (cantidadEventos > 1)
            Positioned(
              top: 2,
              left: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$cantidadEventos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}