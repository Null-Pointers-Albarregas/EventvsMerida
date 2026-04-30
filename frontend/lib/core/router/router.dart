import 'package:eventvsmerida/screens/tutorial.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:eventvsmerida/core/router/app_routes.dart';
import 'package:eventvsmerida/screens/calendario.dart';
import 'package:eventvsmerida/screens/cuenta.dart';
import 'package:eventvsmerida/screens/eventos.dart';
import 'package:eventvsmerida/screens/eventos_guardados.dart';
import 'package:eventvsmerida/screens/login.dart';
import 'package:eventvsmerida/screens/mapa.dart';
import 'package:eventvsmerida/screens/menu.dart';
import 'package:eventvsmerida/screens/perfil.dart';
import 'package:eventvsmerida/screens/privacidad.dart';
import 'package:eventvsmerida/screens/registro.dart';
import 'package:eventvsmerida/screens/splash.dart';
import 'package:eventvsmerida/screens/terminos.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  routes: _appRoutes,
);

final List<RouteBase> _appRoutes = [
  GoRoute(
    path: AppRoutes.splash,
    builder: (context, state) => const Splash(),
  ),
  ShellRoute(
    navigatorKey: _shellNavigatorKey,
    builder: (context, state, child) => Menu(child: child),
    routes: _shellRoutes,
  ),
];

final List<GoRoute> _shellRoutes = [
  GoRoute(path: AppRoutes.eventos, builder: (context, state) => const Eventos()),
  GoRoute(path: AppRoutes.calendario, builder: (context, state) => const Calendario()),
  GoRoute(path: AppRoutes.mapa, builder: (context, state) => const Mapa()),
  GoRoute(path: AppRoutes.login, builder: (context, state) => const Login()),
  GoRoute(path: AppRoutes.registro, builder: (context, state) => const Registro()),
  GoRoute(path: AppRoutes.perfil, builder: (context, state) => const Perfil()),
  GoRoute(path: AppRoutes.terminos, builder: (context, state) => const Terminos()),
  GoRoute(path: AppRoutes.privacidad, builder: (context, state) => const Privacidad()),
  GoRoute(path: AppRoutes.cuenta, builder: (context, state) => const Cuenta()),
  GoRoute(path: AppRoutes.eventosGuardados, builder: (context, state) => const EventosGuardados()),
  GoRoute(path: AppRoutes.tutorial, builder: (context, state) => const MyHomePage()),
];