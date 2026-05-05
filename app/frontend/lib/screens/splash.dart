import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_routes.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  // ===========================================================================
  // VARIABLES
  // ===========================================================================

  Timer? _timer;

  ColorScheme get _cs => Theme.of(context).colorScheme;

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), _irAEventos);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ===========================================================================
  // FUNCIONES AUXILIARES
  // ===========================================================================

  void _irAEventos() {
    if (!mounted) return;
    context.go(AppRoutes.eventos);
  }

  // ===========================================================================
  // INTERFAZ
  // ===========================================================================

  Widget _logoSplash() {
    return Center(
      child: Image.asset(
        'assets/images/logo-eventvs-merida-no-bg.png',
        width: 350,
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
      body: _logoSplash(),
    );
  }
}