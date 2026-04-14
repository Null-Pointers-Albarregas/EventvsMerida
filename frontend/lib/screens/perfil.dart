import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_routes.dart';
import '../core/theme/controlador_tema.dart';
import '../services/shared_preferences_service.dart';
import '../models/usuario.dart';

class Perfil extends StatefulWidget {
  const Perfil({Key? key}) : super(key: key);

  @override
  State<Perfil> createState() => _PerfilState();
}

class _PerfilState extends State<Perfil> {
  Usuario? _usuario;

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  void _cargarUsuario() async {
    final usuario = await SharedPreferencesService.cargarUsuario();
    setState(() {
      _usuario = usuario;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Encabezado
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          color: colorScheme.primary,
          child: _usuario == null ? Column(
            // No logueado
            children: [
              const SizedBox(height: 20),
              Text(
                'Regístrate o inicia sesión',
                style: TextStyle(
                  color: colorScheme.surface,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colorScheme.surface),
                      foregroundColor: colorScheme.surface,
                    ),
                    onPressed: () => context.push(AppRoutes.registro),
                    child: const Text('Registrarse'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.surface,
                      foregroundColor: colorScheme.onSurface,
                    ),
                    onPressed: () => context.push(AppRoutes.login),
                    child: const Text('Iniciar sesión'),
                  ),
                ],
              )
            ],
          ) : Column(
            // Logueado
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                backgroundColor: colorScheme.surface.withOpacity(0.9),
                radius: 32,
                child: Icon(
                  Icons.person,
                  color: colorScheme.primary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "${_usuario!.nombre} ${_usuario!.apellidos}",
                style: TextStyle(
                  color: colorScheme.surface,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),

        // Contenido principal
        Expanded(
          child: ListView(
            children: [
              // Sección de preferencias
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'PREFERENCIAS',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildPreferencias(context, colorScheme, _usuario),

              // Separador
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Divider(
                  color: colorScheme.primary,
                  thickness: 2,
                ),
              ),

              // Sección de información legal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'INFORMACIÓN LEGAL',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildLegal(context, colorScheme),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildPreferencias(
      BuildContext context, ColorScheme colorScheme, Usuario? usuario) {
    final isRegistrado = usuario != null;
    return Column(
      children: isRegistrado
          ? [
        _buildItem(
            Icons.account_circle,
            "Cuenta",
            onTap: () {
              context.push(AppRoutes.cuenta);
            },
        ),
        _buildItem(
          Icons.dark_mode,
          "Modo Oscuro",
          trailing: Switch(
            value: Theme.of(context).brightness == Brightness.dark,
            activeColor: colorScheme.secondary,
            onChanged: (v) {
              themeController.value =
              v ? ThemeMode.dark : ThemeMode.light;
            },
          ),
        ),
        _buildItem(Icons.bookmark_border, "Eventos guardados", onTap: () {context.push(AppRoutes.eventosGuardados);}),
        _buildItem(Icons.notifications, "Preferencias de notificaciones"),
      ]
          : [
        _buildItem(
          Icons.dark_mode,
          "Modo Oscuro",
          trailing: Switch(
            value: Theme.of(context).brightness == Brightness.dark,
            activeColor: colorScheme.secondary,
            onChanged: (v) {
              themeController.value =
              v ? ThemeMode.dark : ThemeMode.light;
            },
          ),
        ),
      ],
    );
  }

  static Widget _buildLegal(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        _buildItem(
          Icons.file_copy,
          "Términos y servicios",
          onTap: () {
            context.push(AppRoutes.terminos);
          },
        ),
        _buildItem(
          Icons.privacy_tip,
          "Política de privacidad",
          onTap: () {
            context.push(AppRoutes.privacidad);
          },
        ),
      ],
    );
  }

  static Widget _buildItem(IconData icono, String titulo,
      {Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icono),
      title: Text(
        titulo,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      trailing: trailing ?? Icon(Icons.arrow_forward_ios),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      onTap: onTap,
    );
  }
}