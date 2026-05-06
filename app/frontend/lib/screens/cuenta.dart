import 'package:eventvsmerida/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../core/router/app_routes.dart';
import '../models/usuario.dart';
import '../services/shared_preferences_service.dart';
import '../widgets/componentes_compartidos.dart';

class Cuenta extends StatefulWidget {
  const Cuenta({super.key});

  @override
  State<Cuenta> createState() => _CuentaState();
}

class _CuentaState extends State<Cuenta> {
  // ===========================================================================
  // VARIABLES
  // ===========================================================================

  Usuario? _usuario;

  ColorScheme get _cs => Theme.of(context).colorScheme;

  XFile? _imagen;

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

  String _formatearFechaNacimiento(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();
    return '$dia/$mes/$anio';
  }

  Future<void> _editarImagenPerfil() async {
    final imagenSeleccionada = await elegirImagen(context);

    if (imagenSeleccionada == null) return;
    if (_usuario == null) return;

    final respuesta = await ApiService.editarUsuario(
      idUsuario: _usuario!.id,
      imagen: imagenSeleccionada,
    );

    if (!mounted) return;

    if (respuesta.exito && respuesta.datos != null) {
      setState(() {
        _usuario = respuesta.datos;
      });

      await SharedPreferencesService.iniciarSesion(
        usuario: respuesta.datos!,
        autoLogin: await SharedPreferencesService.getAutoLogin(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imagen actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta.mensaje),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // ===========================================================================
  // INTERFAZ
  // ===========================================================================

  Widget _infoTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
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
    return SafeArea(
      top: true,
      left: false,
      right: false,
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        color: _cs.primary,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: _cs.surface),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        context.pop();
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                  ),
                ),
                Center(
                  child: Text(
                    'Cuenta',
                    style: TextStyle(
                      color: _cs.surface,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            GestureDetector(
              onTap: _editarImagenPerfil,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    backgroundColor: _cs.surface.withValues(alpha: 0.9),
                    radius: 45,
                    child: _usuario?.fotoUrl != null && _usuario!.fotoUrl!.isNotEmpty
                        ? ClipOval(
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/images/icono.gif',
                        image: _usuario!.fotoUrl!,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        placeholderFit: BoxFit.contain,
                      ),
                    )
                        : Icon(
                      Icons.person,
                      color: _cs.primary,
                      size: 34,
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _cs.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: _cs.surface, width: 2),
                    ),
                    child: Icon(Icons.edit, color: _cs.primary, size: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
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
