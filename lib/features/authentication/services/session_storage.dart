import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncora_frontend/core/data/database_manager.dart';
import 'package:syncora_frontend/core/data/enums/database_tables.dart';
import 'package:syncora_frontend/features/authentication/models/session.dart';
import 'package:syncora_frontend/features/authentication/models/tokens_dto.dart';
import 'package:syncora_frontend/features/authentication/models/user.dart';

// This class loads user data on startup and stores tokens in memory when fetched to be used for subsequent requests
class SessionStorage {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _sharedPreferences;
  final DatabaseManager _databaseManager;

  static const _accessTokenKey = 'jwt_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user';
  static const _isVerifiedKey = 'isVerified';

  TokensDTO? _cachedTokens;

  TokensDTO? get tokens => _cachedTokens;

  SessionStorage(
      {required secureStorage,
      required sharedPreferences,
      required databaseManager})
      : _secureStorage = secureStorage,
        _sharedPreferences = sharedPreferences,
        _databaseManager = databaseManager;

  Future<TokensDTO?> loadTokens() async {
    String? cachedAccessToken = await _secureStorage.read(key: _accessTokenKey);
    String? cachedRefreshToken =
        await _secureStorage.read(key: _refreshTokenKey);

    if (cachedAccessToken == null || cachedRefreshToken == null) {
      return null;
    }

    return TokensDTO(
        accessToken: cachedAccessToken, refreshToken: cachedRefreshToken);
  }

  Future<Session?> loadSession() async {
    String? userJson = _sharedPreferences.getString(_userKey);

    if (userJson != null) {
      TokensDTO? tokens = await loadTokens();

      bool isVerified =
          bool.parse(_sharedPreferences.getString(_isVerifiedKey) ?? 'false');

      Session? session = Session(
          user: User.fromJson(json.decode(userJson)),
          isVerified: isVerified,
          tokens: tokens);

      _cachedTokens = tokens;
      return session;
    }

    _cachedTokens = null;
    return null;
  }

  Future<void> saveSession(
      {required User user, TokensDTO? tokens, required bool isVerified}) async {
    var db = await _databaseManager.getDatabase();

    var userJson = user.toJson();
    userJson.addAll({"isMainUser": 1});

    db.insert(DatabaseTables.users, userJson);
    await _sharedPreferences.setString(_userKey, json.encode(user));
    await _sharedPreferences.setString(_isVerifiedKey, isVerified.toString());
    await updateTokens(
        accessToken: tokens?.accessToken, refreshToken: tokens?.refreshToken);

    _cachedTokens = tokens;
  }

  Future<void> updateTokens({String? accessToken, String? refreshToken}) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);

    _cachedTokens = await loadTokens();
  }

  Future<void> clearSession() async {
    _cachedTokens = null;
    await _databaseManager.ensureDeleted();

    await Future.wait([
      _secureStorage.delete(key: _accessTokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
      _sharedPreferences.remove(_userKey),
      _sharedPreferences.remove(_isVerifiedKey)
    ]);
  }
}
