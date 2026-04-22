import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  // Parámetro opcional por si en alguna pantalla quieres poner botones (como la lupa de buscar)
  final List<Widget>? actions;

  const CustomAppBar({super.key, this.actions});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppBar(
      centerTitle: true,
      backgroundColor: cs.surface,
      foregroundColor: cs.onPrimary,
      title: SizedBox(
        height: 40,
        child: Image.asset(
          'assets/images/logo-eventvs-merida-no-bg.png',
          fit: BoxFit.contain,
        ),
      ),
      // Si la pantalla que llama a este AppBar le pasa botones, los dibuja. Si no, no pone nada.
      actions: actions,
    );
  }

  // Flutter necesita saber la altura estándar de un AppBar (que es 56.0)
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}