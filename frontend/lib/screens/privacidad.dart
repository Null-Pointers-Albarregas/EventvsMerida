import 'package:flutter/material.dart';

class Privacidad extends StatefulWidget {
  const Privacidad({super.key});

  @override
  State<Privacidad> createState() => _PrivacidadState();
}

class _PrivacidadState extends State<Privacidad> {
  // ===========================================================================
  // VARIABLES
  // ===========================================================================
  ColorScheme get _cs => Theme.of(context).colorScheme;

  static const String _textoPrivacidad = '''
Política de Privacidad

1. Responsable del tratamiento
Eventvs Mérida es responsable de tus datos personales. Puedes contactar a través del email: info@eventvsmerida.com

2. Datos recopilados
Recopilamos los datos proporcionados en el registro (nombre, apellidos, correo electrónico, fecha de nacimiento y teléfono) y únicamente empleamos cookies técnicas.

3. Finalidad
Tus datos se emplean para la gestión de usuarios y eventos. No compartimos tu información con terceros, salvo requerimiento legal.

4. Legitimación
La base legal para el tratamiento es tu consentimiento al registrarte.

5. Conservación
Tus datos se conservarán sólo mientras seas usuario registrado o por requerimientos legales.

6. Derechos
Puedes ejercitar tus derechos de acceso, rectificación, cancelación y oposición escribiendo a info@eventvsmerida.com

7. Seguridad
Aplicamos medidas técnicas y organizativas para proteger tus datos de accesos no autorizados.

8. Cambios en la política
Esta política puede actualizarse en el futuro. Te notificaremos si hay cambios relevantes.

Última actualización: 06/03/2026
''';

  // ===========================================================================
  // INTERFAZ
  // ===========================================================================

  Widget _contenidoPrivacidad() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Text(
          _textoPrivacidad,
          style: TextStyle(
            color: _cs.onSurface,
            fontSize: 16,
          ),
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 8.0),
        color: _cs.primary,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: _cs.surface),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            Center(
              child: Text(
                'Política de Privacidad',
                style: TextStyle(
                  color: _cs.surface,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
      backgroundColor: _cs.surface,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _contenidoPrivacidad()),
        ],
      ),
    );
  }
}