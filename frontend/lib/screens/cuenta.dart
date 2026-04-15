import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_routes.dart';
import '../models/usuario.dart';
import '../services/shared_preferences_service.dart';

class Cuenta extends StatefulWidget {
  const Cuenta({super.key});

  @override
  State<Cuenta> createState() => _CuentaState();
}

class _CuentaState extends State<Cuenta> {
  // ===========================================================================
  // ESTADO
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
  // HELPERS DE UI
  // ===========================================================================

  String _formatearFechaNacimiento(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();
    return '$dia/$mes/$anio';
  }

  Widget _infoTile({required String label, required String value, required IconData icon}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _cs.secondary.withValues(alpha: 0.15),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: _cs.primary, size: 28),
        title: Text(
          label,
          style: TextStyle(
            color: _cs.primary,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(color: _cs.onSurface, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    if (_usuario == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          _infoTile(
            label: 'Nombre',
            value: _usuario!.nombre,
            icon: Icons.badge,
          ),
          _infoTile(
            label: 'Apellidos',
            value: _usuario!.apellidos,
            icon: Icons.badge,
          ),
          _infoTile(
            label: 'Fecha de nacimiento',
            value: _formatearFechaNacimiento(_usuario!.fechaNacimiento),
            icon: Icons.cake,
          ),
          _infoTile(
            label: 'Correo electrónico',
            value: _usuario!.email,
            icon: Icons.email,
          ),
          _infoTile(
            label: 'Teléfono',
            value: _usuario!.telefono,
            icon: Icons.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      color: _cs.primary,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: _cs.surface.withValues(alpha: 230),
            radius: 45,
            child: Icon(
              Icons.person,
              color: _cs.primary,
              size: 45,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.logout),
        label: const Text('Cerrar sesión'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _cs.error,
          foregroundColor: _cs.onError,
          minimumSize: const Size.fromHeight(48),
        ),
        onPressed: () async {
          await SharedPreferencesService.cerrarSesion();
          if (!mounted) return;
          context.go(AppRoutes.eventos);
        },
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
      appBar: AppBar(
        backgroundColor: _cs.primary,
        foregroundColor: _cs.surface,
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
            _buildHeader(),

            // DATOS DE USUARIO
            _buildUserInfo(),

            // BOTÓN DE CERRAR SESIÓN
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }
}