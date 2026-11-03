import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  static const String _pinHashKey = 'user_pin_hash';
  static const String _pinSaltKey = 'user_pin_salt';
  static const String _pinEnabledKey = 'pin_lock_enabled';

  SecurityService({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuth,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _localAuth = localAuth ?? LocalAuthentication();

  Future<bool> isPinSet() async {
    final hash = await _storage.read(key: _pinHashKey);
    final enabled = await _storage.read(key: _pinEnabledKey);
    return hash != null && hash.isNotEmpty && enabled == 'true';
  }

  Future<void> setPin(String pin) async {
    final salt = DateTime.now().millisecondsSinceEpoch.toString();
    final hash = _hashPin(pin, salt);
    await _storage.write(key: _pinHashKey, value: hash);
    await _storage.write(key: _pinSaltKey, value: salt);
    await _storage.write(key: _pinEnabledKey, value: 'true');
  }

  Future<void> removePin() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _pinSaltKey);
    await _storage.write(key: _pinEnabledKey, value: 'false');
  }

  Future<bool> verifyPin(String pin) async {
    final savedHash = await _storage.read(key: _pinHashKey);
    final salt = await _storage.read(key: _pinSaltKey);
    if (savedHash == null || salt == null) return false;
    final testHash = _hashPin(pin, salt);
    return testHash == savedHash;
  }

  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Buka BELANJAKU dengan sidik jari / wajah',
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }

  static String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$pin::$salt');
    return sha256.convert(bytes).toString();
  }
}
