import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_routes.dart';
import '../services/shared_preferences_service.dart';
import '../models/usuario.dart';

class Menu extends StatefulWidget {
  final Widget child;

  const Menu({super.key, required this.child});

  @override
  State<StatefulWidget> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  // ===========================================================================
  // VARIABLES
  // ===========================================================================

  int _indiceActual = 0;
  Usuario? _usuario;

  ColorScheme get _cs => Theme.of(context).colorScheme;

  static const List<String> _rutasPrincipales = [
    AppRoutes.eventos,
    AppRoutes.mapa,
    AppRoutes.calendario,
    AppRoutes.perfil,
  ];

  static const List<String> _rutasPerfil = [
    AppRoutes.perfil,
    AppRoutes.registro,
    AppRoutes.login,
    AppRoutes.cuenta,
    AppRoutes.eventosGuardados,
    AppRoutes.terminos,
    AppRoutes.privacidad,
  ];

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
    SharedPreferencesService.usuarioNotifier.addListener(_onUsuarioCambio);
  }

  void _onUsuarioCambio() {
    if (!mounted) return;
    setState(() {
      _usuario = SharedPreferencesService.usuarioNotifier.value;
    });
  }

  @override
  void dispose() {
    SharedPreferencesService.usuarioNotifier.removeListener(_onUsuarioCambio);
    super.dispose();
  }

  // ===========================================================================
  // CARGA DE DATOS
  // ===========================================================================

  Future<void> _cargarUsuario() async {
    final usuario = await SharedPreferencesService.cargarUsuario();
    if (!mounted) return;
    setState(() => _usuario = usuario);
  }

  // ===========================================================================
  // FUNCIONES AUXILIARES
  // ===========================================================================

  int _calcularIndice(String localizacion) {
    if (_rutasPrincipales.contains(localizacion)) {
      return _rutasPrincipales.indexOf(localizacion);
    }

    if (_rutasPerfil.contains(localizacion)) {
      return 3;
    }

    return 0;
  }

  void _cambiarRuta(int indice) {
    if (indice < 0 || indice >= _rutasPrincipales.length) return;
    context.go(_rutasPrincipales[indice]);
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final localizacion = GoRouterState.of(context).uri.toString();
    _indiceActual = _calcularIndice(localizacion);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: _cs.primary,
        unselectedItemColor: _cs.surface.withValues(alpha: 0.5),
        selectedItemColor: _cs.surface,
        currentIndex: _indiceActual,
        iconSize: 30,
        onTap: _cambiarRuta,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Calendario',),
          BottomNavigationBarItem(icon: Icon(Icons.person_2_rounded), label: _usuario?.nombre ?? 'Perfil')
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}