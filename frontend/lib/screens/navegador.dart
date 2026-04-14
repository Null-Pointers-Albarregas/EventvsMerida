import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_routes.dart';

class Navegador extends StatefulWidget {
  final Widget child;

  const Navegador({super.key, required this.child});

  @override
  State<StatefulWidget> createState() => _NavegadorState();
}

class _NavegadorState extends State<Navegador> {
  int _indiceActual = 0;

  int _calcularIndice(String localizacion) {
    switch (localizacion) {
      case AppRoutes.eventos:
        return 0;
      case AppRoutes.mapa:
        return 1;
      case AppRoutes.calendario:
        return 2;
      case AppRoutes.perfil:
        return 3;
    }
    return 0;
  }

  void _cambiarRuta(int indice) {
    switch (indice) {
      case 0:
        context.go(AppRoutes.eventos);
        break;
      case 1:
        context.go(AppRoutes.mapa);
        break;
      case 2:
        context.go(AppRoutes.calendario);
        break;
      case 3:
        context.go(AppRoutes.perfil);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizacion = GoRouterState.of(context).uri.toString();
    _indiceActual = _calcularIndice(localizacion);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: colorScheme.primary,
        unselectedItemColor: colorScheme.surface.withValues(alpha: 0.5),
        selectedItemColor: colorScheme.surface,
        currentIndex: _indiceActual,
        iconSize: 30,
        onTap: _cambiarRuta,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Calendario',),
          BottomNavigationBarItem(icon: Icon(Icons.person_2_rounded), label: 'Perfil',),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}