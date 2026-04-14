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
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _autoLogin = false;
  bool _ocultarPassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final headerHeight = size.height * 0.18;
    final logoWidth = size.width * 0.70;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // CABECERA
          Container(
            color: colorScheme.primary,
            width: double.infinity,
            height: headerHeight,
            child: Center(
              child: Text(
                'Iniciar sesión',
                style: TextStyle(
                  color: colorScheme.surface,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // CUERPO PRINCIPAL
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      // LOGO
                      Image.asset(
                        'assets/images/logo-eventvs-merida-no-bg.png',
                        width: logoWidth,
                      ),
                      const SizedBox(height: 50),

                      // CAMPOS DE LOGIN
                      Column(
                        children: [
                          TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              labelText: 'Correo',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: passwordController,
                            obscureText: _ocultarPassword,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _ocultarPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: colorScheme.primary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _ocultarPassword = !_ocultarPassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // CHECKBOX DE INICIO DE SESIÓN AUTOMÁTICO
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Checkbox(
                                value: _autoLogin,
                                activeColor: colorScheme.primary,
                                onChanged: (value) {
                                  setState(() {
                                    _autoLogin = value ?? false;
                                  });
                                },
                              ),
                              Flexible(
                                child: Text(
                                  'Inicio de sesión automático',
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // BOTÓN DE INICIAR SESIÓN
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () async {
                                final respuesta = await ApiService.iniciarSesion(
                                  emailController.text.trim(),
                                  passwordController.text,
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                          Text(
                                            respuesta.mensaje,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor:
                                        respuesta.exito ? Colors.green : Colors.red,
                                    behavior:
                                    SnackBarBehavior.floating,
                                    margin: const EdgeInsets.only(
                                      left: 16,
                                      right: 16,
                                      bottom: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                    ),
                                  ),
                                );

                                if (respuesta.exito && respuesta.datos != null) {
                                  await SharedPreferencesService.iniciarSesion(
                                    usuario: respuesta.datos!,
                                    autoLogin: _autoLogin,
                                  );

                                  if (!mounted) return;
                                  context.go(AppRoutes.eventos);
                                }
                              },
                              child: Text(
                                'Iniciar sesión',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.surface,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ENLACE PARA REGISTRARSE
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "¿Aún no tienes cuenta? ",
                                style: TextStyle(color: colorScheme.onSurface),
                              ),
                              GestureDetector(
                                onTap: () {
                                  context.push(AppRoutes.registro);
                                },
                                child: Text(
                                  "Regístrate",
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
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