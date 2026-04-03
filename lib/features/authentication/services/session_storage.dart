import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncora_frontend/core/data/database_manager.dart';
import 'package:syncora_frontend/core/utils/result.dart';
import 'package:syncora_frontend/features/authentication/models/session.dart';
import 'package:syncora_frontend/features/authentication/models/tokens.dart';

// This class loads user data on startup and stores tokens in memory when fetched to be used for subsequent requests
class SessionStorage {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _sharedPreferences;
  final DatabaseManager _databaseManager;

  static const _accessTokenKey = 'jwt_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user';
  static const _isVerifiedKey = 'isVerified';

  Tokens? _cachedTokens;

  Tokens? get tokens => _cachedTokens;

  SessionStorage(
    this._secureStorage,
    this._sharedPreferences,
    this._databaseManager,
  );

  Future<Tokens?> loadTokens() async {
    String? cachedAccessToken = await _secureStorage.read(key: _accessTokenKey);
    String? cachedRefreshToken =
        await _secureStorage.read(key: _refreshTokenKey);

    if (cachedAccessToken == null || cachedRefreshToken == null) {
      return null;
    }

    return Tokens(
        accessToken: cachedAccessToken, refreshToken: cachedRefreshToken);
  }

  Future<Result<Session?>> loadSession() async {
    try {
      int? userId = _sharedPreferences.getInt(_userIdKey);

      if (userId != null) {
        Tokens? tokens = await loadTokens();

        bool isVerified =
            bool.parse(_sharedPreferences.getString(_isVerifiedKey) ?? 'false');

        Session? session =
            Session(userId: userId, isVerified: isVerified, tokens: tokens);

        _cachedTokens = tokens;
        return Result.success(session);
      }
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }

    _cachedTokens = null;
    return Result.success(null);
  }

  Future<Result<void>> saveSession(
      {required int userId, Tokens? tokens, required bool isVerified}) async {
    try {
      await _sharedPreferences.setInt(_userIdKey, userId);
      await _sharedPreferences.setString(_isVerifiedKey, isVerified.toString());
      // await _sharedPreferences.setString(
      //     _userPreferencesKey, jsonEncode(preferences.toJson()));
      await updateTokens(
          accessToken: tokens?.accessToken, refreshToken: tokens?.refreshToken);

      _cachedTokens = tokens;
    } catch (e, stackTrace) {
      return Result.failure(e, stackTrace);
    }

    return Result.success();
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
      _sharedPreferences.remove(_userIdKey),
      _sharedPreferences.remove(_isVerifiedKey)
    ]);
  }
}
