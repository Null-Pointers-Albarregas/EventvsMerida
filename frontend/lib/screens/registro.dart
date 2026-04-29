import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_routes.dart';
import '../services/api_service.dart';
import '../services/shared_preferences_service.dart';

class Registro extends StatefulWidget {
  const Registro({super.key});

  @override
  State<Registro> createState() => _RegistroState();
}

class _RegistroState extends State<Registro> {
  // ===========================================================================
  // VARIABLES
  // ===========================================================================

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repetirPasswordController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _diaController = TextEditingController();
  final TextEditingController _mesController = TextEditingController();
  final TextEditingController _anioController = TextEditingController();

  bool _aceptaTerminos = false;
  bool _ocultarPassword = true;
  bool _ocultarRepetirPassword = true;
  String? _mesSeleccionado;

  static const List<String> _meses = [
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

  static const Map<String, String> _mesNumero = {
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

  ColorScheme get _cs => Theme.of(context).colorScheme;

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _repetirPasswordController.dispose();
    _telefonoController.dispose();
    _diaController.dispose();
    _mesController.dispose();
    _anioController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // FUNCIONES AUXILIARES
  // ===========================================================================

  String _mesANumero(String mes) {
    return _mesNumero[mes] ?? '01';
  }

  String? _validarCampo(String label, String? value) {
    final texto = (value ?? '').trim();

    if (texto.isEmpty) {
      return 'Este campo es obligatorio';
    }

    if (label == 'Correo') {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
      if (!emailRegex.hasMatch(texto)) {
        return 'Introduce un email valido';
      }
    }

    if (label == 'Numero de telefono') {
      final phoneRegex = RegExp(r'^[679]\d{8}$');
      if (!phoneRegex.hasMatch(texto)) {
        return 'Debe tener 9 digitos y empezar por 6, 7 o 9';
      }
    }

    if (label == 'Contrasena') {
      final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');
      if (!passwordRegex.hasMatch(texto)) {
        return 'Debe tener 8 caracteres, mayuscula, minuscula y numero';
      }
    }

    if (label == 'Repetir contrasena' && texto != _passwordController.text) {
      return 'Las contrasenas no coinciden';
    }

    return null;
  }

  String? _obtenerFechaFormateada() {
    if (_mesSeleccionado == null) {
      return null;
    }

    final dia = int.tryParse(_diaController.text.trim());
    final anio = int.tryParse(_anioController.text.trim());
    final mes = int.parse(_mesANumero(_mesSeleccionado!));

    if (dia == null || anio == null) {
      return null;
    }

    try {
      final fecha = DateTime(anio, mes, dia);
      final fechaValida = fecha.day == dia && fecha.month == mes && fecha.year == anio;

      if (!fechaValida || fecha.isAfter(DateTime.now())) {
        return null;
      }

      final diaTxt = dia.toString().padLeft(2, '0');
      final mesTxt = mes.toString().padLeft(2, '0');
      return '$diaTxt/$mesTxt/$anio';
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _crearBodyRegistro(String fechaNacimiento) {
    return {
      'nombre': _nombreController.text.trim(),
      'apellidos': _apellidosController.text.trim(),
      'fechaNacimiento': fechaNacimiento,
      'email': _correoController.text.trim(),
      'telefono': _telefonoController.text.trim(),
      'password': _passwordController.text,
      'idRol': 1,
    };
  }

  Future<void> _registrarUsuario() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_aceptaTerminos) {
      _mostrarSnackBar('Debes aceptar los terminos', exito: false);
      return;
    }

    if (_mesSeleccionado == null) {
      _mostrarSnackBar('Selecciona un mes', exito: false);
      return;
    }

    final fechaNacimiento = _obtenerFechaFormateada();
    if (fechaNacimiento == null) {
      _mostrarSnackBar('Fecha invalida o futura', exito: false);
      return;
    }

    final body = _crearBodyRegistro(fechaNacimiento);
    final respuesta = await ApiService.registrarUsuario(body);

    if (!mounted) return;

    _mostrarSnackBar(respuesta.mensaje, exito: respuesta.exito);

    if (!respuesta.exito || respuesta.datos == null) {
      return;
    }

    await SharedPreferencesService.iniciarSesion(
      usuario: respuesta.datos!,
      autoLogin: false,
    );

    if (!mounted) return;
    context.go(AppRoutes.eventos);
  }

  void _seleccionarMes(String mes) {
    setState(() {
      _mesSeleccionado = mes;
      _mesController.text = mes;
    });
  }

  void _alternarPassword() {
    setState(() {
      _ocultarPassword = !_ocultarPassword;
    });
  }

  void _alternarRepetirPassword() {
    setState(() {
      _ocultarRepetirPassword = !_ocultarRepetirPassword;
    });
  }

  void _actualizarTerminos(bool? value) {
    setState(() {
      _aceptaTerminos = value ?? false;
    });
  }

  void _irALogin() {
    context.push(AppRoutes.login);
  }

  // ===========================================================================
  // MENSAJES
  // ===========================================================================

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

  // ===========================================================================
  // INTERFAZ
  // ===========================================================================

  InputDecoration _buildDecoration({
    required String label,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _cs.onSurface.withValues(alpha: 0.7)),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: _cs.onSurface.withValues(alpha: 0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: _cs.primary, width: 2),
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
        padding: const EdgeInsets.symmetric(vertical: 35.0),
        color: _cs.primary,
        alignment: Alignment.center,
        child: Text(
          'Crear cuenta',
          style: TextStyle(
            color: _cs.surface,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCampoTexto(
    String label, {
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggle,
    bool readOnly = false,
    bool isDropdown = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        style: TextStyle(color: _cs.onSurface),
        validator: (value) => _validarCampo(label, value),
        decoration: _buildDecoration(
          label: label,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: _cs.primary.withValues(alpha: 0.6),
                  ),
                  onPressed: onToggle,
                )
              : (isDropdown ? const Icon(Icons.arrow_drop_down) : null),
        ),
        obscureText: isPassword ? obscureText : false,
      ),
    );
  }

  Widget _buildFilaNombreApellidos() {
    return Row(
      children: [
        Expanded(
          child: _buildCampoTexto(
            'Nombre',
            controller: _nombreController,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildCampoTexto(
            'Apellido',
            controller: _apellidosController,
          ),
        ),
      ],
    );
  }

  Widget _buildFilaFecha() {
    return Row(
      children: [
        Expanded(
          child: _buildCampoTexto(
            'Dia',
            controller: _diaController,
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: PopupMenuButton<String>(
            constraints: const BoxConstraints(maxHeight: 200, minWidth: 120),
            onSelected: _seleccionarMes,
            itemBuilder: (context) {
              return _meses
                  .map(
                    (mes) => PopupMenuItem<String>(
                      value: mes,
                      child: Text(
                        mes,
                        style: TextStyle(color: _cs.onSurface),
                      ),
                    ),
                  )
                  .toList();
            },
            child: AbsorbPointer(
              child: _buildCampoTexto(
                'Mes',
                controller: _mesController,
                readOnly: true,
                isDropdown: true,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildCampoTexto(
            'Año',
            controller: _anioController,
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildTerminos() {
    return Row(
      children: [
        Checkbox(
          value: _aceptaTerminos,
          onChanged: _actualizarTerminos,
          activeColor: _cs.primary,
          checkColor: _cs.brightness == Brightness.dark ? Colors.black : Colors.white,
          side: BorderSide(color: _cs.onSurface.withValues(alpha: 0.5)),
        ),
        Expanded(
          child: Text(
            'He leido y acepto los Terminos y condiciones y la Politica de Privacidad',
            style: TextStyle(color: _cs.onSurface, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildBotonRegistro() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _cs.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        onPressed: _registrarUsuario,
        child: Text(
          'Registrarse',
          style: TextStyle(
            color: _cs.brightness == Brightness.dark ? Colors.black : Colors.white,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildLinkLogin() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Ya tienes cuenta? ',
          style: TextStyle(color: _cs.onSurface),
        ),
        GestureDetector(
          onTap: _irALogin,
          child: Text(
            'Inicia sesion',
            style: TextStyle(
              color: _cs.onSurface,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationThickness: 1.5
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormulario() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilaNombreApellidos(),
          _buildCampoTexto(
            'Correo',
            controller: _correoController,
            keyboardType: TextInputType.emailAddress,
          ),
          _buildCampoTexto(
            'Contrasena',
            controller: _passwordController,
            isPassword: true,
            obscureText: _ocultarPassword,
            onToggle: _alternarPassword,
          ),
          _buildCampoTexto(
            'Repetir contrasena',
            controller: _repetirPasswordController,
            isPassword: true,
            obscureText: _ocultarRepetirPassword,
            onToggle: _alternarRepetirPassword,
          ),
          _buildCampoTexto(
            'Numero de telefono',
            controller: _telefonoController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          _buildFilaFecha(),
          const SizedBox(height: 10),
          _buildTerminos(),
          const SizedBox(height: 15),
          _buildBotonRegistro(),
          const SizedBox(height: 10),
          _buildLinkLogin(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        decoration: BoxDecoration(
          color: _cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: _buildFormulario(),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildBody(),
        ],
      ),
    );
  }
}