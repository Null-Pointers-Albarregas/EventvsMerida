import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_routes.dart';
import '../core/theme/controlador_tema.dart';
import '../services/shared_preferences_service.dart';
import '../models/usuario.dart';

class Perfil extends StatefulWidget {
  const Perfil({super.key});

  @override
  State<Perfil> createState() => _PerfilState();
}

class _PerfilState extends State<Perfil> {
  // ===========================================================================
  // VARIABLES
  // ===========================================================================

  Usuario? _usuario;

  ColorScheme get _cs => Theme.of(context).colorScheme;

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  // ===========================================================================
  // CARGA DE DATOS
  // ===========================================================================

  Future<void> _cargarUsuario() async {
    final usuario = await SharedPreferencesService.cargarUsuario();

    if (!mounted) return;

    setState(() {
      _usuario = usuario;
    });
  }

  // ===========================================================================
  // FUNCIONES AUXILIARES
  // ===========================================================================

  void _cambiarTema(bool activado) {
    themeController.value = activado ? ThemeMode.dark : ThemeMode.light;
  }

  // ===========================================================================
  // INTERFAZ
  // ===========================================================================

  Widget _buildSeccionTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Text(
        titulo,
        style: TextStyle(
          color: _cs.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildItem(IconData icono, String titulo, {Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icono),
      title: Text(
        titulo,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      onTap: onTap,
    );
  }

  Widget _buildCabeceraNoLogueado() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Regístrate o inicia sesión',
          style: TextStyle(
            color: _cs.surface,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _cs.surface),
                foregroundColor: _cs.surface,
              ),
              onPressed: () => context.push(AppRoutes.registro),
              child: const Text('Registrarse'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _cs.surface,
                foregroundColor: _cs.onSurface,
              ),
              onPressed: () => context.push(AppRoutes.login),
              child: const Text('Iniciar sesión'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCabeceraLogueado() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundColor: _cs.surface.withValues(alpha: 0.9),
          radius: 32,
          child: Icon(
            Icons.person,
            color: _cs.primary,
            size: 34,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_usuario!.nombre} ${_usuario!.apellidos}',
          style: TextStyle(
            color: _cs.surface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildCabecera() {
    return SafeArea(
      top: true,
      left: false,
      right: false,
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        color: _cs.primary,
        child: _usuario == null ? _buildCabeceraNoLogueado() : _buildCabeceraLogueado(),
      ),
    );
  }

  Widget _buildModoOscuro() {
    return _buildItem(
      Icons.dark_mode,
      'Modo Oscuro',
      trailing: Switch(
        value: Theme.of(context).brightness == Brightness.dark,
        activeThumbColor: _cs.secondary,
        onChanged: _cambiarTema,
      ),
    );
  }

  Widget _buildPreferencias() {
    final isRegistrado = _usuario != null;

    return Column(
      children: [
        if (isRegistrado) ...[
          _buildItem(Icons.account_circle, 'Cuenta', onTap: () => context.push(AppRoutes.cuenta)),
          _buildItem(Icons.bookmark_border, 'Eventos guardados', onTap: () => context.push(AppRoutes.eventosGuardados),),
          _buildItem(Icons.notifications, 'Preferencias de notificaciones'),
        ],

        _buildModoOscuro(),
      ],
    );
  }

  Widget _buildLegal() {
    return Column(
      children: [
        _buildItem(Icons.file_copy, 'Términos y servicios', onTap: () => context.push(AppRoutes.terminos)),
        _buildItem(Icons.privacy_tip, 'Política de privacidad', onTap: () => context.push(AppRoutes.privacidad)),
      ],
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final double bottomPad = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        _buildCabecera(),

        // Lista de contenido
        Expanded(
          child: ListView(
            padding: EdgeInsets.only(top: 24.0, bottom: 16.0 + bottomPad),
            children: [
              _buildSeccionTitulo('PREFERENCIAS'),
              _buildPreferencias(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Divider(
                  color: _cs.primary,
                  thickness: 2,
                ),
              ),
              _buildSeccionTitulo('INFORMACIÓN LEGAL'),
              _buildLegal(),
              const SizedBox(height: 8),
            ],
          ),
        ),

        // Footer fijo: logo + versión
        SafeArea(
          top: false,
          bottom: true,
          left: false,
          right: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(right: 24.0, bottom: 8.0, top: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Image.asset(
                  'assets/images/logo-eventvs-merida-no-bg.png',
                  height: 30,
                ),
                const SizedBox(height: 8),
                Text(
                  'Versión 1.0.0',
                  style: TextStyle(
                    color: _cs.onSurface,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}