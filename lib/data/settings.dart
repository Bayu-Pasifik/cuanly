import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hashes [pin] with [salt] (hex). Kept top-level so it is unit-testable.
String hashPin(String pin, String salt) => sha256.convert(utf8.encode('$salt:$pin')).toString();

/// Local app preferences: theme mode, PIN lock and biometric unlock.
class AppSettings {
  AppSettings._();
  static final instance = AppSettings._();

  static const _kTheme = 'theme_mode';
  static const _kBio = 'biometric';
  static const _kPinHash = 'pin_hash';
  static const _kPinSalt = 'pin_salt';
  static const _kOnboarded = 'onboarded';

  final themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);
  final _secure = const FlutterSecureStorage();
  final _auth = LocalAuthentication();

  bool _hasPin = false;
  bool onboarded = false;
  bool biometric = false;
  String? _hash, _salt;

  bool get hasPin => _hasPin;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    themeMode.value = ThemeMode.values.firstWhere((m) => m.name == p.getString(_kTheme), orElse: () => ThemeMode.system);
    biometric = p.getBool(_kBio) ?? false;
    onboarded = p.getBool(_kOnboarded) ?? false;
    try {
      _hash = await _secure.read(key: _kPinHash);
      _salt = await _secure.read(key: _kPinSalt);
    } catch (_) {
      _hash = _salt = null;
    }
    _hasPin = _hash != null && _salt != null;
    if (!_hasPin) biometric = false;
  }

  Future<void> setOnboarded() async {
    onboarded = true;
    (await SharedPreferences.getInstance()).setBool(_kOnboarded, true);
  }

  Future<void> setThemeMode(ThemeMode m) async {
    themeMode.value = m;
    (await SharedPreferences.getInstance()).setString(_kTheme, m.name);
  }

  Future<void> setPin(String pin) async {
    final rnd = Random.secure();
    final salt = base64Url.encode(List.generate(16, (_) => rnd.nextInt(256)));
    final hash = hashPin(pin, salt);
    await _secure.write(key: _kPinSalt, value: salt);
    await _secure.write(key: _kPinHash, value: hash);
    _salt = salt;
    _hash = hash;
    _hasPin = true;
  }

  bool checkPin(String pin) => _hasPin && hashPin(pin, _salt!) == _hash;

  Future<void> clearPin() async {
    await _secure.delete(key: _kPinHash);
    await _secure.delete(key: _kPinSalt);
    _hash = _salt = null;
    _hasPin = false;
    await setBiometric(false);
  }

  Future<void> setBiometric(bool v) async {
    biometric = v;
    (await SharedPreferences.getInstance()).setBool(_kBio, v);
  }

  Future<bool> biometricAvailable() async {
    try {
      return await _auth.isDeviceSupported() && (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Prompts the system biometric dialog. False on cancel or any failure.
  Future<bool> authenticateBiometric() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Buka Cuanly',
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }
}
