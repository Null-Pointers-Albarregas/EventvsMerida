import 'package:eventvsmerida/widgets/componentes_compartidos.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../models/evento.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import '../services/eventos_guardados_service.dart';

class Calendario extends StatefulWidget {
  const Calendario({super.key});

  @override
  State<Calendario> createState() => _CalendarioState();
}

class _CalendarioState extends State<Calendario> {
  // ===========================================================================
  // VARIABLES
  // ===========================================================================

  late final DateTime _primerMesPermitido;
  late final DateTime _ultimoMesPermitido;
  late final List<int> _years;

  late DateTime _focusedDay;
  DateTime? _selectedDay;

  bool _cargandoEventos = true;
  String? _mensajeError;
  Map<DateTime, List<Evento>> _eventosMap = {};

  Usuario? _usuario;
  List<Evento> _eventosGuardados = [];

  static const List<String> _months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  ColorScheme get _cs => Theme.of(context).colorScheme;

  GlobalKey keyCalendario = GlobalKey();
  GlobalKey keyListadoEventos = GlobalKey();

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    final ahora = DateTime.now();

    _primerMesPermitido = DateTime(ahora.year, ahora.month, 1);
    _ultimoMesPermitido = DateTime(2030, 12, 1);

    _focusedDay = DateTime(ahora.year, ahora.month, ahora.day);
    _selectedDay = DateTime(ahora.year, ahora.month, ahora.day);

    _years = List.generate(
      _ultimoMesPermitido.year - _primerMesPermitido.year + 1,
      (index) => _primerMesPermitido.year + index,
    );
    _cargarUsuarioYGuardados();
    _cargarEventos();
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

  Future<void> _cargarEventos() async {
    setState(() {
      _cargandoEventos = true;
      _mensajeError = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _comprobarInicializacionTutorial();
    });

    final respuesta = await ApiService.obtenerEventos();

    if (!mounted) return;

    if (!respuesta.exito) {
      setState(() {
        _cargandoEventos = false;
        _mensajeError = respuesta.mensaje;
      });

      _mostrarMensaje(respuesta.mensaje);
      return;
    }

    final eventos = respuesta.datos ?? const <Evento>[];

    setState(() {
      _eventosMap = _crearMapaPorDia(eventos);
      _cargandoEventos = false;
      _mensajeError = null;
    });
  }

  Map<DateTime, List<Evento>> _crearMapaPorDia(List<Evento> eventos) {
    final mapa = <DateTime, List<Evento>>{};

    for (final evento in eventos) {
      final inicio = _normalizarFecha(evento.fechaInicio);
      final fin = _normalizarFecha(evento.fechaFin);
      final totalDias = fin.difference(inicio).inDays;

      for (var i = 0; i <= totalDias; i++) {
        final dia = _normalizarFecha(inicio.add(Duration(days: i)));
        mapa.putIfAbsent(dia, () => []);
        mapa[dia]!.add(evento);
      }
    }

    return mapa;
  }

  // ===========================================================================
  // FUNCIONES AUXILIARES
  // ===========================================================================

  DateTime _normalizarFecha(DateTime fecha) {
    final f = fecha.toLocal();
    return DateTime(f.year, f.month, f.day);
  }

  bool _esMismoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _esHoraCero(DateTime fecha) {
    return fecha.hour == 0 && fecha.minute == 0;
  }

  String _formatearHora(DateTime fecha) {
    return DateFormat('HH:mm').format(fecha);
  }

  String _formatearFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  bool _esAntesDelPrimerMes(DateTime fecha) {
    final mes = DateTime(fecha.year, fecha.month, 1);
    return mes.isBefore(_primerMesPermitido);
  }

  bool _esDespuesDelUltimoMes(DateTime fecha) {
    final mes = DateTime(fecha.year, fecha.month, 1);
    return mes.isAfter(_ultimoMesPermitido);
  }

  bool _esEventoDeUnSoloDia(Evento evento) {
    return _esMismoDia(evento.fechaInicio, evento.fechaFin);
  }

  int _prioridadEvento(Evento evento, DateTime diaSeleccionado) {
    final finalizaHoy = _esMismoDia(evento.fechaFin, diaSeleccionado);
    final iniciaHoy = _esMismoDia(evento.fechaInicio, diaSeleccionado);

    if (finalizaHoy) return 0;
    if (iniciaHoy) return 1;
    return 2;
  }

  int _horaReferencia(Evento evento, DateTime diaSeleccionado) {
    final finalizaHoy = _esMismoDia(evento.fechaFin, diaSeleccionado);
    final iniciaHoy = _esMismoDia(evento.fechaInicio, diaSeleccionado);

    if (finalizaHoy) return evento.fechaFin.hour * 60 + evento.fechaFin.minute;
    if (iniciaHoy)
      return evento.fechaInicio.hour * 60 + evento.fechaInicio.minute;

    return evento.fechaInicio.hour * 60 + evento.fechaInicio.minute;
  }

  List<Evento> _eventosDelDiaSeleccionado() {
    final fechaSeleccionada = _selectedDay ?? _focusedDay;
    final fechaNormalizada = _normalizarFecha(fechaSeleccionada);
    final hoy = _normalizarFecha(DateTime.now());

    final esMesVisible =
        fechaNormalizada.month == _focusedDay.month &&
        fechaNormalizada.year == _focusedDay.year;

    if (!esMesVisible || fechaNormalizada.isBefore(hoy)) {
      return [];
    }

    final lista = List<Evento>.from(_eventosMap[fechaNormalizada] ?? []);

    lista.sort((a, b) {
      final prioridadA = _prioridadEvento(a, fechaNormalizada);
      final prioridadB = _prioridadEvento(b, fechaNormalizada);

      if (prioridadA != prioridadB) {
        return prioridadA.compareTo(prioridadB);
      }

      final horaA = _horaReferencia(a, fechaNormalizada);
      final horaB = _horaReferencia(b, fechaNormalizada);

      if (horaA != horaB) {
        return horaA.compareTo(horaB);
      }

      return a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase());
    });

    return lista;
  }

  String _textoEtiquetaTiempo(Evento evento, DateTime diaSeleccionado) {
    final iniciaHoy = _esMismoDia(evento.fechaInicio, diaSeleccionado);
    final finalizaHoy = _esMismoDia(evento.fechaFin, diaSeleccionado);

    final inicioHora = _formatearHora(evento.fechaInicio);
    final finHora = _formatearHora(evento.fechaFin);

    final inicioCero = _esHoraCero(evento.fechaInicio);
    final finCero = _esHoraCero(evento.fechaFin);

    if (_esEventoDeUnSoloDia(evento)) {
      if (inicioCero && finCero) return 'Todo el día';
      if (inicioHora == finHora) return inicioHora;
      if (inicioCero) return finHora;
      if (finCero) return inicioHora;
      return '$inicioHora - $finHora';
    }

    if (finalizaHoy) {
      if (finCero) return 'Finaliza';
      return 'Finaliza $finHora';
    }

    if (iniciaHoy) {
      if (inicioCero) return 'Inicia';
      return 'Inicia $inicioHora';
    }

    return 'En curso';
  }

  String _textoFechaCard(Evento evento) {
    final inicio = _formatearFecha(evento.fechaInicio);
    final fin = _formatearFecha(evento.fechaFin);

    if (_esEventoDeUnSoloDia(evento)) {
      return 'Fecha: $inicio';
    }

    return 'Fecha: $inicio - $fin';
  }

  List<DropdownMenuItem<int>> _buildMonthItems() {
    var mesInicio = 1;
    var mesFin = 12;

    if (_focusedDay.year == _primerMesPermitido.year) {
      mesInicio = _primerMesPermitido.month;
    }

    if (_focusedDay.year == _ultimoMesPermitido.year) {
      mesFin = _ultimoMesPermitido.month;
    }

    return List.generate(mesFin - mesInicio + 1, (index) {
      final mes = mesInicio + index;
      return DropdownMenuItem<int>(value: mes, child: Text(_months[mes - 1]));
    });
  }

  void _actualizarFechaVisible(DateTime nuevaFecha) {
    if (_esAntesDelPrimerMes(nuevaFecha)) {
      _mostrarMensaje('No puedes ir a meses anteriores al actual');
      return;
    }

    if (_esDespuesDelUltimoMes(nuevaFecha)) {
      _mostrarMensaje('No puedes avanzar más allá de diciembre de 2030');
      return;
    }

    final hoy = _normalizarFecha(DateTime.now());
    final nuevoMes = DateTime(nuevaFecha.year, nuevaFecha.month, 1);

    setState(() {
      _focusedDay = nuevaFecha;

      if (nuevaFecha.year == hoy.year && nuevoMes.month == hoy.month) {
        _selectedDay = hoy;
      } else {
        _selectedDay = nuevoMes;
      }
    });
  }

  void _comprobarInicializacionTutorial() {
    if (!mounted) return;
    if (Tutorial.numPantalla != 3) return;
    if (Tutorial.tutorialInicializado) return;
    if (!_targetEstaListo(keyCalendario) &&
        !_targetEstaListo(keyListadoEventos))
      return;

    Tutorial.tutorialInicializado = true;
    _configurarTutorial();
  }

  // ===========================================================================
  // MODALES
  // ===========================================================================

  void _abrirModalEvento(Evento evento) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (ctx) => ModalEvento(
        eventos: [evento],
        usuario: _usuario,
        eventosGuardados: _eventosGuardados,
        onEventosGuardadosActualizados: (nuevaLista) {
          setState(() {
            _eventosGuardados = nuevaLista;
          });
        },
        mostrarBotonGuardado: true,
      ),
    );
  }

  // ===========================================================================
  // MENSAJES
  // ===========================================================================

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  // ===========================================================================
  // INTERFAZ
  // ===========================================================================

  Widget _buildDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _cs.primary.withValues(alpha: 128)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          style: TextStyle(color: _cs.onSurface, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSelectoresFecha() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDropdown<int>(
          value: _focusedDay.month,
          items: _buildMonthItems(),
          onChanged: (val) {
            if (val == null) return;
            _actualizarFechaVisible(DateTime(_focusedDay.year, val, 1));
          },
        ),
        const SizedBox(width: 15),
        _buildDropdown<int>(
          value: _focusedDay.year,
          items: _years
              .map(
                (anio) => DropdownMenuItem<int>(
                  value: anio,
                  child: Text(anio.toString()),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val == null) return;
            _actualizarFechaVisible(DateTime(val, _focusedDay.month, 1));
          },
        ),
      ],
    );
  }

  Widget _buildCalendario() {
    return TableCalendar(
      locale: 'es',
      firstDay: _primerMesPermitido,
      key: keyCalendario,
      lastDay: _ultimoMesPermitido,
      focusedDay: _focusedDay,
      headerVisible: false,
      availableGestures: AvailableGestures.none,
      startingDayOfWeek: StartingDayOfWeek.monday,
      eventLoader: (day) {
        final fechaNormalizada = _normalizarFecha(day);
        final hoy = _normalizarFecha(DateTime.now());

        final esMesVisible =
            fechaNormalizada.month == _focusedDay.month &&
            fechaNormalizada.year == _focusedDay.year;

        if (!esMesVisible) {
          return const [];
        }

        if (fechaNormalizada.isBefore(hoy)) {
          return const [];
        }

        return _eventosMap[fechaNormalizada] ?? const [];
      },
      enabledDayPredicate: (day) {
        final fechaNormalizada = _normalizarFecha(day);

        return fechaNormalizada.month == _focusedDay.month &&
            fechaNormalizada.year == _focusedDay.year;
      },
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        final hoy = _normalizarFecha(DateTime.now());
        final fechaSeleccionada = _normalizarFecha(selectedDay);

        if (fechaSeleccionada.isBefore(hoy)) return;

        setState(() {
          _selectedDay = _normalizarFecha(selectedDay);
          _focusedDay = _normalizarFecha(focusedDay);
        });
      },
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(color: _cs.onSurface.withValues(alpha: 128)),
        weekendStyle: TextStyle(color: _cs.onSurface.withValues(alpha: 128)),
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: true,

        // Días normales del mes visible
        defaultTextStyle: TextStyle(color: _cs.onSurface),

        // Fines de semana del mes visible
        weekendTextStyle: TextStyle(color: _cs.onSurface),

        // Días de otros meses
        outsideTextStyle: TextStyle(
          color: _cs.onSurface.withValues(alpha: 0.35),
        ),

        todayDecoration: BoxDecoration(
          color: _cs.secondary,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: _cs.primary,
          shape: BoxShape.circle,
        ),
        markerDecoration: BoxDecoration(
          color: _cs.primary,
          shape: BoxShape.circle,
        ),
        markerMargin: const EdgeInsets.only(top: 3.8),
        markersAlignment: Alignment.bottomCenter,
        markersMaxCount: 1,
        selectedTextStyle: TextStyle(color: _cs.surface),
        todayTextStyle: TextStyle(color: _cs.surface),
      ),
    );
  }

  Widget _buildEventoBadge(String texto) {
    return Container(
      width: 100,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _cs.primary.withValues(alpha: 20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _cs.primary.withValues(alpha: 64)),
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: _cs.surface,
        ),
      ),
    );
  }

  Widget _buildEventoCard(Evento evento) {
    final fechaSeleccionada = _normalizarFecha(_selectedDay ?? _focusedDay);
    final etiquetaTiempo = _textoEtiquetaTiempo(evento, fechaSeleccionada);
    final textoFecha = _textoFechaCard(evento);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: () => _abrirModalEvento(evento),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minLeadingWidth: 96,
        leading: _buildEventoBadge(etiquetaTiempo),
        title: Text(
          evento.titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (evento.localizacion.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                evento.localizacion,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 2),
            Text(textoFecha, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoCentro({
    required IconData icono,
    required String mensaje,
    Widget? accion,
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
            if (accion != null) ...[const SizedBox(height: 12), accion],
          ],
        ),
      ),
    );
  }

  Widget _buildEventoLista() {
    if (_cargandoEventos) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_mensajeError != null) {
      return _buildEstadoCentro(
        icono: Icons.error_outline,
        mensaje: _mensajeError!,
        accion: TextButton(
          onPressed: _cargarEventos,
          child: const Text('Reintentar'),
        ),
      );
    }

    final lista = _eventosDelDiaSeleccionado();

    if (lista.isEmpty) {
      return _buildEstadoCentro(
        icono: Icons.event_busy,
        mensaje: 'No hay eventos para este día',
      );
    }

    return ListView.separated(
      key: keyListadoEventos,
      itemCount: lista.length,
      padding: const EdgeInsets.only(bottom: 12),
      itemBuilder: (context, index) {
        final evento = lista[index];
        return _buildEventoCard(evento);
      },
      separatorBuilder: (context, index) => const SizedBox(height: 0),
    );
  }

  // ===========================================================================
  // TUTORIAL
  // ===========================================================================

  void _configurarTutorial() {
    Tutorial.pasosTutorial.clear();
    cargarPasosTutorial();
    Tutorial.tutorial = Tutorial.crearTutorial(
      context: context,
      pasosTutorial: Tutorial.pasosTutorial,
      color: Theme.of(context).colorScheme.primary,
    );
    Tutorial.tutorial.show(context: context);
  }

  void cargarPasosTutorial() {
    Tutorial.pasosTutorial.add(
      Tutorial.crearPaso(
        context: context,
        key: keyCalendario,
        titulo: 'Calendario de eventos',
        descripcion:
            'Aquí puedes ver los eventos organizados por fecha. Los días con eventos disponibles se marcarán en el calendario.',
        icon: Icons.calendar_month,
        siguiente: true,
        onNext: () => Tutorial.tutorial.next(),
        forma: ShapeLightFocus.RRect,
      ),
    );
    Tutorial.pasosTutorial.add(
      Tutorial.crearPaso(
        context: context,
        key: keyListadoEventos,
        titulo: 'Eventos del día seleccionado',
        descripcion:
            'En esta sección se muestra un listado de los eventos correspondientes al día que selecciones en el calendario. Puedes tocar cualquier evento para ver más detalles.',
        icon: Icons.list_alt,
        siguiente: true,
        onNext: () => Tutorial.tutorial.next(),
        forma: ShapeLightFocus.RRect,
        alineamientoTarjeta: ContentAlign.top,
      ),
    );
    Tutorial.pasosTutorial.add(
      Tutorial.crearPaso(
        context: context,
        key: keyListadoEventos,
        titulo: 'Perfil',
        descripcion: 'Vamos a por el perfil!',
        icon: Icons.person,
        siguiente: true,
        onNext: () async {
          print('ENTRA EN EL onNext DEL ULTIMO PASO');

          Tutorial.numPantalla = 4;
          Tutorial.tutorialInicializado = false;

          Tutorial.tutorial.finish();

          await Future.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;
          context.go('/perfil');
        },
        forma: ShapeLightFocus.RRect,
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
      body: Column(
        children: [
          const SizedBox(height: 12),

          // SELECTORES DE MES Y AÑO
          _buildSelectoresFecha(),
          const SizedBox(height: 12),

          // CALENDARIO
          _buildCalendario(),
          const SizedBox(height: 12),
          const Divider(),

          // LISTA DE EVENTOS
          Expanded(child: _buildEventoLista()),
        ],
      ),
    );
  }
}
