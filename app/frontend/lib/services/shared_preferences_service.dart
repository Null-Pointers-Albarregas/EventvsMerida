import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/usuario.dart';

class SharedPreferencesService {
  SharedPreferencesService._();

  static const String _usuarioKey = 'usuario_data';
  static const String _autoLoginKey = 'autologin_data';
  static const String _tutorialKey = 'tutorial_data';

  // Sesion en memoria para la ejecucion actual de la app.
  static Usuario? usuarioSesionActual;
  static final ValueNotifier<Usuario?> usuarioNotifier = ValueNotifier<Usuario?>(null);

  static Future<SharedPreferences> get _prefs async {
    return SharedPreferences.getInstance();
  }

  // ===========================
  // API principal de sesion
  // ===========================

  static Future<void> iniciarSesion({required Usuario usuario, required bool autoLogin}) async {
    usuarioSesionActual = usuario;
    usuarioNotifier.value = usuario;

    final prefs = await _prefs;
    await prefs.setBool(_autoLoginKey, autoLogin);

    if (autoLogin) {
      await prefs.setString(_usuarioKey, jsonEncode(usuario.toJson()));
    } else {
      await prefs.remove(_usuarioKey);
    }
  }

  static Future<void> cerrarSesion() async {
    usuarioSesionActual = null;
    usuarioNotifier.value = null;

    final prefs = await _prefs;
    await prefs.remove(_usuarioKey);
    await prefs.remove(_autoLoginKey);
  }

  static Future<Usuario?> cargarUsuario() async {
    final prefs = await _prefs;
    final autoLogin = prefs.getBool(_autoLoginKey) ?? false;

    if (autoLogin) {
      return await _cargarUsuarioPersistido(prefs);
    }

    return usuarioSesionActual;
  }

  // ===========================
  // Internos
  // ===========================

  static Future<Usuario?> _cargarUsuarioPersistido(SharedPreferences prefs) async {
    final json = prefs.getString(_usuarioKey);

    if (json == null || json.isEmpty) {
      await prefs.remove(_usuarioKey);
      await prefs.remove(_autoLoginKey);
      return null;
    }

    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      final usuario = Usuario.fromJson(data);
      usuarioSesionActual = usuario;
      usuarioNotifier.value = usuario;
      return usuario;
    } catch (_) {
      await prefs.remove(_usuarioKey);
      await prefs.remove(_autoLoginKey);
      return null;
    }
  }

    // ===========================
    // Comprobaciones carga tutorial
    // ===========================

  static Future<bool> cargarTutorial() async {
    final prefs = await _prefs;
    return prefs.getBool(_tutorialKey) ?? true;
  }

  static Future<void> finalizarTurorial() async {
    final prefs = await _prefs;
    await prefs.setBool(_tutorialKey, false);
  }

  static Future<void> resetearTutorial() async {
    final prefs = await _prefs;
    await prefs.setBool(_tutorialKey, true);
  }
}