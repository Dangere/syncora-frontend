import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncora_frontend/core/data/database_manager.dart';
import 'package:syncora_frontend/core/data/enums/database_tables.dart';
import 'package:syncora_frontend/features/authentication/models/tokens_dto.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';
import 'package:syncora_frontend/features/users/services/users_service.dart';

class SessionStorage {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _sharedPreferences;
  final DatabaseManager _databaseManager;
  String? _cachedAccessToken;
  String? get accessToken => _cachedAccessToken;

  String? _cachedRefreshToken;
  String? get refreshToken => _cachedRefreshToken;

  static const _accessTokenKey = 'jwt_token';
  static const _refreshTokenKey = 'refresh_token';

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
      _cachedAccessToken = await _secureStorage.read(key: _accessTokenKey);
      _cachedRefreshToken = await _secureStorage.read(key: _refreshTokenKey);

      return User.fromJson(json.decode(userJson));
    }

    return null;
  }

  Future<void> saveSession({required User user, TokensDTO? tokens}) async {
    var db = await _databaseManager.getDatabase();

    db.insert(DatabaseTables.users, user.toJson());
    await _sharedPreferences.setString("user", json.encode(user));
    await updateTokens(
        accessToken: tokens?.accessToken, refreshToken: tokens?.refreshToken);
  }

  Future<void> updateTokens({String? accessToken, String? refreshToken}) async {
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;

    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clearSession() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    await _databaseManager.ensureDeleted();

    await Future.wait([
      _secureStorage.delete(key: _accessTokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
      _sharedPreferences.remove(_userKey),
    ]);
  }
}
