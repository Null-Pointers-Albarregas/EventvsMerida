import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_routes.dart';
import '../services/api_service.dart';
import '../services/shared_preferences_service.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // ===========================================================================
  // VARIABLES
  // ===========================================================================

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _autoLogin = false;
  bool _ocultarPassword = true;

  ColorScheme get _cs => Theme.of(context).colorScheme;

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // FUNCIONES AUXILIARES
  // ===========================================================================

  InputDecoration _buildDecoration({required String labelText, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: _cs.primary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: _cs.primary,
          width: 2,
        ),
      ),
      suffixIcon: suffixIcon,
    );
  }

  void _mostrarSnackBar(String mensaje, {required bool exito}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              exito ? Icons.check : Icons.error_outline,
              size: 20,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                mensaje,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: exito ? Colors.green : _cs.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  String? _validarCamposVacios() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty && password.isEmpty) {
      return 'Introduce tu correo y tu contraseña.';
    }

    if (email.isEmpty) {
      return 'Introduce tu correo.';
    }

    if (password.isEmpty) {
      return 'Introduce tu contraseña.';
    }

    return null;
  }

  Future<void> _iniciarSesion() async {
    final mensajeError = _validarCamposVacios();

    if (mensajeError != null) {
      _mostrarSnackBar(mensajeError, exito: false);
      return;
    }

    final respuesta = await ApiService.iniciarSesion(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (!respuesta.exito) {
      _mostrarSnackBar(respuesta.mensaje, exito: false);
      return;
    }

    final usuario = respuesta.datos!;

    _mostrarSnackBar(respuesta.mensaje, exito: true);

    await SharedPreferencesService.iniciarSesion(
      usuario: usuario,
      autoLogin: _autoLogin,
    );

    if (!mounted) return;
    context.go(AppRoutes.eventos);
  }

  // ===========================================================================
  // INTERFAZ
  // ===========================================================================

  Widget _buildHeader() {
    return SafeArea(
      top: true,
      left: false,
      right: false,
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 35.0),
        color: _cs.primary,
        alignment: Alignment.center,
        child: Text(
          'Iniciar sesión',
          style: TextStyle(
            color: _cs.surface,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(double logoWidth) {
    return Image.asset(
      'assets/images/logo-eventvs-merida-no-bg.png',
      width: logoWidth,
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: _buildDecoration(
        labelText: 'Correo',
      ),
      onSubmitted: (_) => _iniciarSesion(),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _ocultarPassword,
      textInputAction: TextInputAction.done,
      decoration: _buildDecoration(
        labelText: 'Contraseña',
        suffixIcon: IconButton(
          icon: Icon(
            _ocultarPassword ? Icons.visibility_off : Icons.visibility,
            color: _cs.primary,
          ),
          onPressed: () {
            setState(() {
              _ocultarPassword = !_ocultarPassword;
            });
          },
        ),
      ),
      onSubmitted: (_) => _iniciarSesion(),
    );
  }

  Widget _buildAutoLogin() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: _autoLogin,
          activeColor: _cs.primary,
          onChanged: (value) {
            setState(() {
              _autoLogin = value ?? false;
            });
          },
        ),
        Flexible(
          child: Text(
            'Inicio de sesión automático',
            style: TextStyle(color: _cs.onSurface),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _cs.primary,
          foregroundColor: _cs.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: _iniciarSesion,
        child: Text(
          'Iniciar sesión',
          style: TextStyle(
            fontSize: 16,
            color: _cs.surface,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Aún no tienes cuenta? ',
          style: TextStyle(color: _cs.onSurface),
        ),
        GestureDetector(
          onTap: () {
            context.push(AppRoutes.registro);
          },
          child: Text(
            'Regístrate',
            style: TextStyle(
              color: _cs.onSurface,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationThickness: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoWidth = size.width * 0.70;

    return Scaffold(
      backgroundColor: _cs.surface,
      body: Column(
        children: [
          // CABECERA
          _buildHeader(),

          // CUERPO PRINCIPAL
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: _cs.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // LOGO
                      _buildLogo(logoWidth),
                      const SizedBox(height: 50),

                      // CAMPOS DE LOGIN
                      Column(
                        children: [
                          _buildEmailField(),
                          const SizedBox(height: 16),
                          _buildPasswordField(),
                          const SizedBox(height: 16),

                          // CHECKBOX DE INICIO DE SESIÓN AUTOMÁTICO
                          _buildAutoLogin(),
                          const SizedBox(height: 16),

                          // BOTÓN DE INICIAR SESIÓN
                          _buildLoginButton(),
                          const SizedBox(height: 16),

                          // ENLACE PARA REGISTRARSE
                          _buildRegisterLink(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}