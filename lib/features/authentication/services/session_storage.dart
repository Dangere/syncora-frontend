import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncora_frontend/core/data/database_manager.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';

class SessionStorage {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _sharedPreferences;
  final DatabaseManager _databaseManager;
  String? _cachedToken;
  String? get token => _cachedToken;

  static const _tokenKey = 'jwt_token';
  static const _userKey = 'user';

  SessionStorage(
      {required secureStorage,
      required sharedPreferences,
      required databaseManager})
      : _secureStorage = secureStorage,
        _sharedPreferences = sharedPreferences,
        _databaseManager = databaseManager;

  Future<User?> loadSession() async {
    String? userJson = _sharedPreferences.getString(_userKey);

    if (userJson != null) {
      _cachedToken = await _secureStorage.read(key: _tokenKey);
      return User.fromJson(json.decode(userJson));
    }

    return null;
  }

  Future<void> saveSession(User user, String? token) async {
    _cachedToken = token;

    var db = await _databaseManager.getDatabase();
    await db.insert("users", user.toJson());
    await _secureStorage.write(key: _tokenKey, value: token);
    await _sharedPreferences.setString("user", json.encode(user));
  }

  Future<void> clearSession() async {
    _cachedToken = null;
    await _databaseManager.ensureDeleted();

    await Future.wait([
      _secureStorage.delete(key: _tokenKey),
      _sharedPreferences.remove(_userKey),
    ]);
  }
}
