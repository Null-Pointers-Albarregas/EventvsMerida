import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/evento.dart';
import '../services/api_service.dart';

class Calendario extends StatefulWidget {
  const Calendario({super.key});

  @override
  State<Calendario> createState() => _CalendarioState();
}

class _CalendarioState extends State<Calendario> {
  late final DateTime _primerMesPermitido;
  late final DateTime _ultimoMesPermitido;
  late final List<int> _years;

  late DateTime _focusedDay;
  DateTime? _selectedDay;

  Map<DateTime, List<Evento>> _eventosMap = {};

  final List<String> _months = [
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
    'Diciembre'
  ];

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

    _cargarEventos();
  }

  Future<void> _cargarEventos() async {
    try {
      final mapa = await ApiService.obtenerEventosParaCalendario();
      setState(() {
        _eventosMap = mapa;
      });
    } catch (e, stack) {
      debugPrint("Error cargando eventos: $e");
      debugPrintStack(stackTrace: stack);
    }
  }

  bool _esAntesDelPrimerMes(DateTime fecha) {
    final mes = DateTime(fecha.year, fecha.month, 1);
    return mes.isBefore(_primerMesPermitido);
  }

  bool _esDespuesDelUltimoMes(DateTime fecha) {
    final mes = DateTime(fecha.year, fecha.month, 1);
    return mes.isAfter(_ultimoMesPermitido);
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  List<DropdownMenuItem<int>> _buildMonthItems() {
    int mesInicio = 1;
    int mesFin = 12;

    if (_focusedDay.year == _primerMesPermitido.year) {
      mesInicio = _primerMesPermitido.month;
    }

    if (_focusedDay.year == _ultimoMesPermitido.year) {
      mesFin = _ultimoMesPermitido.month;
    }

    return List.generate(
      mesFin - mesInicio + 1,
          (index) {
        final mes = mesInicio + index;
        return DropdownMenuItem<int>(
          value: mes,
          child: Text(_months[mes - 1]),
        );
      },
    );
  }

  DateTime _normalizar(DateTime fecha) => DateTime(fecha.year, fecha.month, fecha.day);

  bool _esMismoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _esHoraCero(DateTime fecha) => fecha.hour == 0 && fecha.minute == 0;

  int _minutosDelDia(DateTime fecha) => fecha.hour * 60 + fecha.minute;

  int _prioridadEstado(Evento evento, DateTime diaSeleccionado) {
    final iniciaHoy = _esMismoDia(evento.fechaInicio, diaSeleccionado);
    final finalizaHoy = _esMismoDia(evento.fechaFin, diaSeleccionado);

    if (finalizaHoy) return 0; // 1) finalizan
    if (iniciaHoy) return 1; // 2) inician
    return 2; // 3) en curso
  }

  int _horaOrden(Evento evento, DateTime diaSeleccionado) {
    final iniciaHoy = _esMismoDia(evento.fechaInicio, diaSeleccionado);
    final finalizaHoy = _esMismoDia(evento.fechaFin, diaSeleccionado);

    if (finalizaHoy) return _minutosDelDia(evento.fechaFin);
    if (iniciaHoy) return _minutosDelDia(evento.fechaInicio);
    return _minutosDelDia(evento.fechaInicio);
  }

  String _etiquetaTiempo(Evento evento, DateTime diaSeleccionado) {
    final iniciaHoy = _esMismoDia(evento.fechaInicio, diaSeleccionado);
    final finalizaHoy = _esMismoDia(evento.fechaFin, diaSeleccionado);

    final inicioHora = DateFormat('HH:mm').format(evento.fechaInicio);
    final finHora = DateFormat('HH:mm').format(evento.fechaFin);

    final inicioCero = _esHoraCero(evento.fechaInicio);
    final finCero = _esHoraCero(evento.fechaFin);

    if (iniciaHoy && finalizaHoy) {
      if (inicioCero && finCero) return 'Todo el dia';
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const SizedBox(height: 60),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDropdown(
              value: _focusedDay.month,
              items: _buildMonthItems(),
              onChanged: (val) {
                if (val == null) return;
                final nuevaFecha = DateTime(_focusedDay.year, val, 1);

                if (_esAntesDelPrimerMes(nuevaFecha)) {
                  _mostrarMensaje('No puedes ir a meses anteriores al actual');
                  return;
                }

                if (_esDespuesDelUltimoMes(nuevaFecha)) {
                  _mostrarMensaje('No puedes avanzar mas alla de diciembre de 2030');
                  return;
                }

                setState(() {
                  _focusedDay = nuevaFecha;
                  _selectedDay = nuevaFecha;
                });
              },
            ),
            const SizedBox(width: 15),
            _buildDropdown(
              value: _focusedDay.year,
              items: _years
                  .map(
                    (y) => DropdownMenuItem(
                  value: y,
                  child: Text(y.toString()),
                ),
              )
                  .toList(),
              onChanged: (val) {
                if (val == null) return;
                final nuevaFecha = DateTime(val, _focusedDay.month, 1);

                if (_esAntesDelPrimerMes(nuevaFecha)) {
                  _mostrarMensaje('No puedes ir a meses anteriores al actual');
                  return;
                }

                if (_esDespuesDelUltimoMes(nuevaFecha)) {
                  _mostrarMensaje('No puedes avanzar mas alla de diciembre de 2030');
                  return;
                }

                setState(() {
                  _focusedDay = nuevaFecha;
                  _selectedDay = nuevaFecha;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        TableCalendar(
          firstDay: _primerMesPermitido,
          lastDay: _ultimoMesPermitido,
          focusedDay: _focusedDay,
          headerVisible: false,
          availableGestures: AvailableGestures.none,
          eventLoader: (day) {
            final fechaNormalizada = DateTime(day.year, day.month, day.day);
            return _eventosMap[fechaNormalizada] ?? [];
          },
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: colorScheme.secondary,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            markersAlignment: Alignment.bottomCenter,
            markersMaxCount: 1,
            selectedTextStyle: TextStyle(color: colorScheme.onPrimary),
            todayTextStyle: TextStyle(color: colorScheme.onSecondary),
          ),
        ),
        const SizedBox(height: 12),
        const Divider(),
        Expanded(
          child: _buildEventoLista(),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEventoLista() {
    final fechaSeleccionada = _selectedDay ?? _focusedDay;
    final fechaNormalizada = DateTime(
      fechaSeleccionada.year,
      fechaSeleccionada.month,
      fechaSeleccionada.day,
    );

    final lista = List<Evento>.from(_eventosMap[fechaNormalizada] ?? []);

    lista.sort((a, b) {
      final prioridadA = _prioridadEstado(a, fechaNormalizada);
      final prioridadB = _prioridadEstado(b, fechaNormalizada);

      if (prioridadA != prioridadB) {
        return prioridadA.compareTo(prioridadB);
      }

      final horaA = _horaOrden(a, fechaNormalizada);
      final horaB = _horaOrden(b, fechaNormalizada);

      if (horaA != horaB) {
        return horaA.compareTo(horaB);
      }

      return a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase());
    });

    if (lista.isEmpty) {
      return const Center(
        child: Text("No hay eventos para este dia"),
      );
    }

    return ListView.builder(
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final evento = lista[index];
        final etiqueta = _etiquetaTiempo(evento, fechaNormalizada);

        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: SizedBox(
              width: 84,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  etiqueta,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
            ),
            title: Text(evento.titulo),
            subtitle: Text(evento.localizacion),
          ),
        );
      },
    );
  }
}