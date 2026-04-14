import 'package:flutter/material.dart';
import '../core/router/app_routes.dart';
import '../services/api_service.dart';
import '../services/shared_preferences_service.dart';
import 'package:go_router/go_router.dart';

class Registro extends StatefulWidget {
  const Registro({super.key});

  @override
  State<Registro> createState() => _RegistroState();
}

class _RegistroState extends State<Registro> {
  // Clave global para el formulario (permite validar campos)
  final _formKey = GlobalKey<FormState>();

  bool _aceptaTerminos = false;
  bool _oscurecerPassword = true;
  bool _oscurecerRepetirPassword = true;
  String? _mesSeleccionado;

  // Lista de meses para el selector
  final List<String> _meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  // Función que convierte el nombre del mes a número (para fechas)
  String mesANumero(String mes) {
    const meses = {
      'Enero': '01',
      'Febrero': '02',
      'Marzo': '03',
      'Abril': '04',
      'Mayo': '05',
      'Junio': '06',
      'Julio': '07',
      'Agosto': '08',
      'Septiembre': '09',
      'Octubre': '10',
      'Noviembre': '11',
      'Diciembre': '12',
    };
    return meses[mes] ?? '01';
  }

  // Controladores para manejar el texto de los campos
  final _mesController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repetirPasswordController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _diaController = TextEditingController();
  final _anioController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final headerHeight = size.height * 0.18;

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: colorScheme.primary,
            width: double.infinity,
            height: headerHeight,
            child: Center(
              child: Text(
                'Crear cuenta',
                style: TextStyle(
                  color: colorScheme.surface,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              //controla el espacio interno dentro de un contenedor
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const .vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                //agrupa varios campos de entrada TextFormField
                //Permite validar los campos de manera conjunta y manejar su estado.
                child: Form(
                  //Acceder al estado del formulario desde cualquier parte del código
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              context,
                              "Nombre",
                              controller: _nombreController,
                            ),
                          ),
                          const SizedBox(width: 15),
                          // Espacio horizontal entre los dos cuadros
                          Expanded(
                            child: _buildTextField(
                              context,
                              "Apellido",
                              controller: _apellidoController,
                            ),
                          ),
                        ],
                      ),
                      _buildTextField(
                        context,
                        "Correo",
                        controller: _correoController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _buildTextField(
                        context,
                        "Contraseña",
                        controller: _passwordController,
                        isPassword: true,
                        isObscured: _oscurecerPassword,
                        onToggle: () {
                          setState(() {
                            _oscurecerPassword = !_oscurecerPassword;
                          });
                        },
                      ),
                      _buildTextField(
                        context,
                        "Repetir contraseña",
                        controller: _repetirPasswordController,
                        isPassword: true,
                        isObscured: _oscurecerRepetirPassword,
                        onToggle: () {
                          setState(() {
                            _oscurecerRepetirPassword = !_oscurecerRepetirPassword;
                          });
                        },
                      ),
                      _buildTextField(
                        context,
                        "Número de teléfono",
                        controller: _telefonoController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              context,
                              "Día",
                              controller: _diaController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: PopupMenuButton<String>(
                              constraints: const BoxConstraints(
                                maxHeight: 200,
                                minWidth: 120,
                              ),
                              onSelected: (String valor) {
                                setState(() {
                                  _mesSeleccionado = valor;
                                  _mesController.text = valor;
                                });
                              },
                              itemBuilder: (BuildContext context) =>
                                  _meses.map((String mes) {
                                    return PopupMenuItem<String>(
                                      value: mes,
                                      child: Text(
                                        mes,
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              child: AbsorbPointer(
                                child: _buildTextField(
                                  context,
                                  "Mes",
                                  controller: _mesController,
                                  readOnly: true,
                                  isDropdown: true,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              context,
                              "Año",
                              controller: _anioController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Checkbox(
                            value: _aceptaTerminos,
                            onChanged: (bool? value) {
                              setState(() {
                                _aceptaTerminos = value ?? false;
                              });
                            },
                            activeColor: colorScheme.primary,
                            checkColor: colorScheme.brightness == Brightness.dark
                                ? Colors.black
                                : Colors.white,
                            side: BorderSide(
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "He leído y acepto los Términos y condiciones y la Política de Privacidad",
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: .circular(5),
                            ),
                          ),
                          onPressed: () async {
                            // Validar formulario (si hay errores, no continúa)
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }

                            // ¿Acepta términos?
                            if (!_aceptaTerminos) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Debes aceptar los términos")),
                              );
                              return;
                            }

                            // ¿Ha elegido mes?
                            if (_mesSeleccionado == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Selecciona un mes")),
                              );
                              return;
                            }

                            // Convertir fecha a número
                            int? dia = int.tryParse(_diaController.text);
                            int mes = int.parse(mesANumero(_mesSeleccionado!));
                            int? anio = int.tryParse(_anioController.text);

                            if (dia == null || anio == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Fecha inválida")),
                              );
                              return;
                            }

                            // Validar que la fecha es válida y no es futura
                            try {
                              DateTime fechaValida = DateTime(anio, mes, dia);
                              if (fechaValida.day != dia || fechaValida.month != mes || fechaValida.year != anio) {
                                throw Exception();
                              }
                              if (fechaValida.isAfter(DateTime.now())) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("La fecha no puede ser futura")),
                                );
                                return;
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Fecha inválida")),
                              );
                              return;
                            }

                            // Formatear fecha dd/MM/yyyy
                            final fechaString = "${dia.toString().padLeft(2,'0')}/${mes.toString().padLeft(2,'0')}/$anio";

                            // Crear objeto de usuario
                            final userData = {
                              "nombre": _nombreController.text,
                              "apellidos": _apellidoController.text,
                              "fechaNacimiento": fechaString,
                              "email": _correoController.text,
                              "telefono": _telefonoController.text,
                              "password": _passwordController.text,
                              "idRol": 1,
                            };

                            // Llamada al API para registrar: espera un mapa con 'mensaje' y 'usuario'
                            final result = await ApiService.registrar(userData);

                            final mensaje = result['mensaje'];
                            final usuario = result['usuario']; // Este será null si falla el registro

                            // Mostrar feedback al usuario SIEMPRE
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
                                      mensaje,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.green,
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

                            // Si el registro es correcto, guarda el usuario y navega
                            if (usuario != null) {
                              SharedPreferencesService.usuarioSesionActual = usuario;
                              context.go(AppRoutes.eventos);
                            }
                          },
                          child: Text(
                            "Registrarse",
                            style: TextStyle(
                              color: colorScheme.brightness == Brightness.dark
                                  ? Colors.black
                                  : Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "¿Ya tienes cuenta? ",
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                          GestureDetector(
                            onTap: () {
                              context.push(AppRoutes.login);
                            },
                            child: Text(
                              "Inicia sesión",
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      BuildContext context,
      String label, {
        bool isPassword = false,
        bool readOnly = false,
        VoidCallback? onTap, //Acción al tocar
        TextEditingController? controller,
        bool? isObscured,
        VoidCallback? onToggle, //Cambiar visibilidad contraseña
        bool isDropdown = false,
        TextInputType? keyboardType, //Tipo de teclado
      }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        style: TextStyle(color: colorScheme.onSurface),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "Este campo es obligatorio";
          }
          if (label == "Correo") {
            final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
            if (!emailRegex.hasMatch(value)) {
              return "Introduce un email válido";
            }
          }
          if (label == "Número de teléfono") {
            final phoneRegex = RegExp(r'^[679]\d{8}$');

            if (!phoneRegex.hasMatch(value)) {
              return "Debe tener 9 dígitos y empezar por 6, 7 o 9";
            }
          }
          if (label == "Contraseña") {
            final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');

            if (!passwordRegex.hasMatch(value)) {
              return "Debe tener 8 caracteres, mayúscula, minúscula y número";
            }
          }
          if (label == "Repetir contraseña") {
            if (value != _passwordController.text) {
              return "Las contraseñas no coinciden";
            }
          }

          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              isObscured! ? Icons.visibility_off : Icons.visibility,
              color: colorScheme.primary.withValues(alpha: 0.6),
            ),
            onPressed: onToggle,
          )
              : (isDropdown ? const Icon(Icons.arrow_drop_down) : null),
          enabledBorder: OutlineInputBorder(
            borderRadius: .circular(20),
            borderSide: BorderSide(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: .circular(20),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
        ),
        obscureText: isPassword ? (isObscured ?? true) : false,
      ),
    );
  }
}