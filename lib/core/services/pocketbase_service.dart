import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timebloxs/core/utils/app_logger.dart';

class PocketBaseService {
  static const String _baseUrl = 'https://pb-timebloxs.titanserver.org';
  static const String _authTokenKey = 'pb_auth_token';
  static const String _authModelKey = 'pb_auth_model';

  late final PocketBase _pb;

  PocketBaseService() {
    _pb = PocketBase(_baseUrl);
  }

  PocketBase get client => _pb;

  bool get isAuthenticated => _pb.authStore.isValid;
  RecordModel? get currentUser => _pb.authStore.record;

  /// Persist auth token to local storage
  Future<void> persistAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, _pb.authStore.token);
    if (_pb.authStore.record != null) {
      await prefs.setString(
        _authModelKey,
        _pb.authStore.record!.toJson().toString(),
      );
    }
  }

  /// Load persisted auth token on app start
  Future<void> loadPersistedAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_authTokenKey);

    if (token != null && token.isNotEmpty) {
      try {
        // Load the token into the auth store BEFORE calling authRefresh
        _pb.authStore.save(token, null);

        await _pb.collection('users').authRefresh();
        await persistAuth();
      } catch (e, stack) {
        await logger.error('PocketBase.loadPersistedAuth', e, stack);
        await clearAuth();
      }
    } else {
      await logger.debug('PocketBase.loadPersistedAuth', "No token found, user needs to login");
    }
  }

  /// Sign in with email and password
  Future<RecordAuth> signIn(String email, String password) async {
    try {
      final auth = await _pb.collection('users').authWithPassword(
        email,
        password,
      );
      await persistAuth();
      return auth;
    } catch (e, stack) {
      await logger.error('PocketBase.signIn', e, stack);
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _pb.authStore.clear();
    await clearAuth();
  }

  /// Clear persisted auth
  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
    await prefs.remove(_authModelKey);
  }
}