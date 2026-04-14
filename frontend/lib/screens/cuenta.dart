import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_routes.dart';
import '../services/shared_preferences_service.dart';
import '../models/usuario.dart';

class Cuenta extends StatefulWidget {
  const Cuenta({super.key});

  @override
  State<Cuenta> createState() => _CuentaState();
}

class _CuentaState extends State<Cuenta> {
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

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.surface,
        centerTitle: true,
        title: const Text('Cuenta'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // CABECERA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              color: colorScheme.primary,
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.surface.withOpacity(0.9),
                    radius: 45,
                    child: Icon(
                      Icons.person,
                      color: colorScheme.primary,
                      size: 45,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // DATOS DE USUARIO
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  _infoTile(
                    context,
                    label: "Nombre",
                    value: _usuario!.nombre,
                    icon: Icons.badge,
                  ),
                  _infoTile(
                    context,
                    label: "Apellidos",
                    value: _usuario!.apellidos,
                    icon: Icons.badge,
                  ),
                  _infoTile(
                    context,
                    label: "Fecha de nacimiento",
                    value: "${_usuario!.fechaNacimiento.day.toString().padLeft(2, '0')}/${_usuario!.fechaNacimiento.month.toString().padLeft(2, '0')}/${_usuario!.fechaNacimiento.year}",
                    icon: Icons.cake,
                  ),
                  _infoTile(
                    context,
                    label: "Correo electrónico",
                    value: _usuario!.email,
                    icon: Icons.email,
                  ),
                  _infoTile(
                    context,
                    label: "Teléfono",
                    value: _usuario!.telefono,
                    icon: Icons.phone,
                  ),
                ],
              ),
            ),

            // BOTÓN DE CERRAR SESIÓN
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () async {
                  await SharedPreferencesService.cerrarSesion();
                  context.go(AppRoutes.eventos);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.secondary.withOpacity(0.15),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: colorScheme.primary, size: 28),
        title: Text(
          label,
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(color: colorScheme.onSurface, fontSize: 15),
        ),
      ),
    );
  }
}