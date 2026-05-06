import 'dart:convert';

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

  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _fechaNacController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repetirPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _repetirPasswordController.dispose();
    _telefonoController.dispose();
    _fechaNacController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // CARGA DE DATOS
  // ===========================================================================

  Future<void> _cargarUsuario() async {
    final usuario = await SharedPreferencesService.cargarUsuario();

    if (!mounted) return;

    setState(() {
      _usuario = usuario;

      if (usuario != null) {
        _nombreController.text = usuario.nombre;
        _apellidosController.text = usuario.apellidos;
        _fechaNacController.text = _formatearFechaNacimiento(usuario.fechaNacimiento);
        _correoController.text = usuario.email;
        _telefonoController.text = usuario.telefono;
      }
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

  InputDecoration _decorationModal(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _cs.primary),
      labelStyle: TextStyle(color: _cs.onSurface.withValues(alpha: 0.7)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _cs.onSurface.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _cs.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _cs.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _cs.error, width: 2),
      ),
    );
  }

  String _obtenerFechaFormateada(DateTime fecha) {
    final diaTxt = fecha.day.toString().padLeft(2, '0');
    final mesTxt = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString().padLeft(2, '0');
    return '$diaTxt/$mesTxt/$anio';
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
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
                    child:
                        _usuario?.fotoUrl != null &&
                            _usuario!.fotoUrl!.isNotEmpty
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
                        : Icon(Icons.person, color: _cs.primary, size: 34),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        children: [
          if (_usuario != null) ...[
            // Botón superior: Cambiar contraseña
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.lock_reset, color: _cs.surface),
                label: Text(
                  'Cambiar contraseña',
                  style: TextStyle(color: _cs.surface),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cs.primary,
                  foregroundColor: _cs.onPrimary,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () {
                  _buildModalEditarContrasenia();
                },
              ),
            ),

            const SizedBox(height: 12),

            // Fila inferior: Editar datos + Cerrar sesión
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.edit, color: _cs.surface),
                    label: Text(
                      'Editar datos',
                      style: TextStyle(color: _cs.surface),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cs.primary,
                      foregroundColor: _cs.onPrimary,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () {
                      _buildModalEditarDatos();
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'Cerrar sesión',
                      style: TextStyle(color: Colors.white),
                    ),
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
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic> _buildBodyEditar() {
    final body = {
      'nombre': _nombreController.text.trim(),
      'apellidos': _apellidosController.text.trim(),
      'fechaNacimiento': _fechaNacController.text.trim(),
      'email': _correoController.text.trim(),
      'telefono': _telefonoController.text.trim(),
      'password': _passwordController.text.trim(),
      'fotoPath': null,
    };

    debugPrint('========== BODY EDITAR ==========');
    debugPrint('ID usuario: ${_usuario?.id}');
    debugPrint('Body enviado: ${jsonEncode(body)}');
    debugPrint('Password: ${_passwordController.text}');
    debugPrint('Repetir password: ${_repetirPasswordController.text}');
    debugPrint('=================================');

    return body;
  }

  Future<void> _buildModalEditarDatos() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: _cs.primary.withValues(alpha: 0.4), width: 1.5),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 45,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _cs.onSurface.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  Text(
                    'Editar datos',
                    style: TextStyle(
                      color: _cs.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _nombreController,
                    decoration: _decorationModal('Nombre', Icons.person),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre es obligatorio';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _apellidosController,
                    decoration: _decorationModal('Apellidos', Icons.badge),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Los apellidos son obligatorios';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _fechaNacController,
                    decoration: _decorationModal(
                      'Fecha de nacimiento',
                      Icons.cake,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La fecha de nacimiento es obligatoria';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _correoController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _decorationModal(
                      'Correo electrónico',
                      Icons.email,
                    ),
                    validator: (value) {
                      final texto = value?.trim() ?? '';
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

                      if (texto.isEmpty) {
                        return 'El correo es obligatorio';
                      }

                      if (!emailRegex.hasMatch(texto)) {
                        return 'Introduce un correo válido';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _telefonoController,
                    keyboardType: TextInputType.phone,
                    decoration: _decorationModal('Teléfono', Icons.phone),
                    validator: (value) {
                      final texto = value?.trim() ?? '';
                      final phoneRegex = RegExp(r'^[679]\d{8}$');

                      if (texto.isEmpty) {
                        return 'El teléfono es obligatorio';
                      }

                      if (!phoneRegex.hasMatch(texto)) {
                        return 'Debe tener 9 dígitos y empezar por 6, 7 o 9';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _cs.primary,
                            side: BorderSide(color: _cs.primary),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;

                            final respuesta = await ApiService.editarUsuario(
                              idUsuario: _usuario!.id,
                              datosUsuario: _buildBodyEditar(),
                            );

                            if (!mounted) return;

                            Navigator.pop(context);

                            if (respuesta.exito && respuesta.datos != null) {
                              setState(() {
                                _usuario = respuesta.datos;
                              });

                              await SharedPreferencesService.iniciarSesion(
                                usuario: respuesta.datos!,
                                autoLogin: false,
                              );

                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Datos actualizados correctamente',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(respuesta.mensaje),
                                  backgroundColor: _cs.error,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _cs.primary,
                            foregroundColor: _cs.onPrimary,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text('Guardar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _buildModalEditarContrasenia() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: _cs.primary.withValues(alpha: 0.4), width: 1.5),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 45,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _cs.onSurface.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  Text(
                    'Cambiar contraseña',
                    style: TextStyle(
                      color: _cs.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _passwordController,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: _decorationModal('Contraseña nueva', Icons.key),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La contraseña es obligatoria';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _repetirPasswordController,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: _decorationModal(
                      'Confirmar contraseña',
                      Icons.key,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La confirmación de contraseña es obligatoria';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _cs.primary,
                            side: BorderSide(color: _cs.primary),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;

                            final respuesta = await ApiService.editarUsuario(
                              idUsuario: _usuario!.id,
                              datosUsuario: _buildBodyEditar(),
                            );

                            if (!mounted) return;

                            Navigator.pop(context);

                            if (respuesta.exito && respuesta.datos != null) {
                              setState(() {
                                _usuario = respuesta.datos;
                              });

                              await SharedPreferencesService.iniciarSesion(
                                usuario: respuesta.datos!,
                                autoLogin: await SharedPreferencesService.getAutoLogin(),
                              );

                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Contraseña actualizada correctamente',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(respuesta.mensaje),
                                  backgroundColor: _cs.error,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _cs.primary,
                            foregroundColor: _cs.onPrimary,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text('Cambiar contraseña'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cs.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // CABECERA FIJA
          _buildHeader(),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // DATOS DE USUARIO
                  _buildUserInfo(),

                  // BOTONES
                  _buildLogoutButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
