import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_routes.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      context.go(AppRoutes.eventos);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorFondo = Theme.of(context).colorScheme.surface;
    return Scaffold(
      backgroundColor: colorFondo,
      body: Center(
        child: Image.asset(
          'assets/images/logo-eventvs-merida-no-bg.png',
          width: 350,
        ),
      ),
    );
  }
}