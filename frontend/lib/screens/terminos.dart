import 'package:flutter/material.dart';

class Terminos extends StatefulWidget {
  const Terminos({super.key});

  @override
  State<Terminos> createState() => _TerminosState();
}

class _TerminosState extends State<Terminos> {
  // ===========================================================================
  // VARIABLES
  // ===========================================================================
  ColorScheme get _cs => Theme.of(context).colorScheme;

  static const String _textoTerminos = '''
Términos y Condiciones de Uso

Bienvenido a Eventvs Mérida. Al utilizar nuestra aplicación, aceptas los siguientes términos:

1. Objeto
Eventvs Mérida es una plataforma para la consulta y gestión de eventos culturales en Mérida.

2. Uso de la aplicación
Los usuarios se comprometen a hacer un uso adecuado de los servicios, sin vulnerar derechos de terceros ni la legislación vigente. Está prohibido el uso para fines ilícitos o fraudulentos.

3. Propiedad intelectual
Todos los derechos sobre los contenidos, imágenes, logotipos y marcas son propiedad de Eventvs Mérida, salvo que se indique lo contrario.

4. Responsabilidad
Eventvs Mérida no se responsabiliza por la exactitud de los datos de los eventos ni por daños derivados del uso de la app.

5. Modificaciones
Los presentes términos podrán ser modificados para adaptarlos a nuevas normativas o mejorar el servicio.

6. Legislación y jurisdicción
La relación se regirá por la legislación española. Para cualquier controversia, las partes se someten a los juzgados de Mérida (España).

Última actualización: 06/03/2026
''';

  // ===========================================================================
  // INTERFAZ
  // ===========================================================================

  Widget _contenidoTerminos() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Text(
          _textoTerminos,
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
                'Términos y Servicios',
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
          Expanded(child: _contenidoTerminos()),
        ],
      ),
    );
  }
}