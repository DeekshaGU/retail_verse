import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/login_role_parser.dart';
import '../../../data/remote/auth_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/session_service.dart';

/// Authentication state management
///
/// Manages:
/// - User authentication state (logged in/out)
/// - Loading states during auth operations
/// - Error handling and user-friendly messages
/// - Token and user data storage
class AuthState {
  final bool isLoading;
  final String? error;
  final String? token;
  final Map<String, dynamic>? user;

  AuthState({this.isLoading = false, this.error, this.token, this.user});

  AuthState copyWith({
    bool? isLoading,
    String? error,
    String? token,
    Map<String, dynamic>? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      token: token ?? this.token,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();

  AuthNotifier() : super(AuthState());

  /// Register a new user account
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      print('🔵 AuthProvider: Starting registration for $email');
      state = state.copyWith(isLoading: true, error: null);

      final result = await _authService.registerUser(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );

      print('✅ AuthProvider: Registration successful');
      print('  Token received: ${result['token'] != null ? 'Yes' : 'No'}');
      print('  User data: ${result['user']}');

      // Do not keep register token/user in memory or prefs — avoids a brief window
      // where the UI could read an old session role. User must log in explicitly.
      await SessionService.clearSession();
      state = AuthState(isLoading: false);

      return true;
    } catch (e) {
      print('❌ AuthProvider: Registration failed - $e');
      final errorMessage = _messageForError(e);
      state = state.copyWith(
        isLoading: false,
        token: null,
        user: null,
        error: errorMessage,
      );
      return false;
    }
  }

  /// Login an existing user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔵 AuthProvider: Starting login for $email');
      state = state.copyWith(isLoading: true, error: null);

      final result = await _authService.loginUser(
        email: email,
        password: password,
      );

      if (kDebugMode) {
        debugPrint(
          '[auth] login ok id=${result.user.id} role=${result.user.role} '
          'email=${result.user.email}',
        );
      }

      final token = result.token;
      final userMap = result.user.toJson();

      if (kDebugMode) {
        debugPrint(
          '[auth] LOGIN user map: $userMap | PARSED ROLE: ${result.user.role}',
        );
        debugPrint('[auth] SAVED ROLE (next line from SessionService):');
      }

      await SessionService.saveSession(
        token: token,
        userId: result.user.id,
        userName: result.user.name,
        userEmail: result.user.email,
        userPhone: result.user.phone,
        userRole: result.user.role,
        storeId: result.user.storeId,
      );

      if (kDebugMode) {
        debugPrint('[auth] NAV ROLE (Riverpod state): ${userMap['role']}');
      }

      state = state.copyWith(
        isLoading: false,
        token: token,
        user: userMap,
        error: null,
      );

      return true;
    } catch (e) {
      print('❌ AuthProvider: Login failed - $e');
      final errorMessage = _messageForError(e);
      state = state.copyWith(
        isLoading: false,
        token: null,
        user: null,
        error: errorMessage,
      );
      return false;
    }
  }

  Future<bool> sendOtp({required String phone}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authService.sendOtp(phone: phone);
      state = state.copyWith(isLoading: false, error: null);
      return true;
    } catch (e) {
      final errorMessage = _messageForError(e);
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> verifyOtp({required String phone, required String otp}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _authService.verifyOtp(phone: phone, otp: otp);

      final token = result.token;
      final userMap = result.user.toJson();

      await SessionService.saveSession(
        token: token,
        userId: result.user.id,
        userName: result.user.name,
        userEmail: result.user.email,
        userPhone: result.user.phone,
        userRole: result.user.role,
        storeId: result.user.storeId,
      );

      state = state.copyWith(
        isLoading: false,
        token: token,
        user: userMap,
        error: null,
      );
      return true;
    } catch (e) {
      final errorMessage = _messageForError(e);
      state = state.copyWith(
        isLoading: false,
        token: null,
        user: null,
        error: errorMessage,
      );
      return false;
    }
  }

  /// Convert error objects to user-friendly messages
  String _messageForError(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    final message = error.toString();
    return message.replaceFirst('Exception: ', '');
  }

  /// Restores token and user profile from [SessionService] after a cold start.
  /// Must run when splash finds a saved token so Riverpod matches SharedPreferences.
  Future<void> restoreFromStorage() async {
    final snap = await SessionService.readPersistedAuth();
    final token = snap[SessionService.persistedTokenKey];
    if (token == null || token.isEmpty) {
      return;
    }

    final userId = snap[SessionService.persistedUserIdKey];
    final userName = snap[SessionService.persistedUserNameKey];
    final userEmail = snap[SessionService.persistedUserEmailKey];
    final userPhone = snap[SessionService.persistedUserPhoneKey];
    final userRole = snap[SessionService.persistedUserRoleKey];
    final storeId = snap[SessionService.persistedStoreIdKey];

    Map<String, dynamic>? user;
    if (userId != null ||
        userName != null ||
        userEmail != null ||
        userRole != null ||
        storeId != null) {
      var roleStr = userRole?.trim();
      if (roleStr == null || roleStr.isEmpty) {
        roleStr = decodeJwtRoleClaim(token)?.trim();
      }
      final roleCanonical = canonicalUiRole(roleStr);
      if (roleCanonical == null) {
        if (kDebugMode) {
          debugPrint(
            '[auth] WARNING: RESTORED ROLE missing or unrecognized (prefs + JWT). Not setting role key.',
          );
        }
      }

      user = {
        if (userId != null) 'id': userId,
        if (userName != null) 'name': userName,
        if (userEmail != null) 'email': userEmail,
        if (userPhone != null) 'phone': userPhone,
        if (roleCanonical != null) 'role': roleCanonical,
        if (storeId != null) 'storeId': storeId,
      };

      if (kDebugMode) {
        debugPrint(
          '[auth] RESTORED ROLE: ${roleCanonical ?? "(none)"} raw=${roleStr ?? "(none)"} prefsRole=${snap[SessionService.persistedUserRoleKey]}',
        );
      }
    }

    // Do not use copyWith: `user: null` would incorrectly keep the previous user.
    state = AuthState(token: token, user: user);
    if (kDebugMode) {
      debugPrint(
        '[auth] restore tokenLen=${token.length} role=${user?['role']} id=${user?['id']}',
      );
    }
  }

  /// Logout user and clear auth state
  Future<void> logout() async {
    await SessionService.clearSession();
    state = AuthState();
  }

  Future<void> updateLocalUser(Map<String, dynamic> updates) async {
    final next = {...?state.user, ...updates};
    state = state.copyWith(user: next);

    final token = state.token ?? await SessionService.getToken();
    if (token != null && token.isNotEmpty) {
      await SessionService.saveSession(
        token: token,
        userId: next['id']?.toString(),
        userName: next['name']?.toString(),
        userEmail: next['email']?.toString(),
        userPhone: next['phone']?.toString(),
        userRole: next['role']?.toString(),
        storeId: next['storeId']?.toString(),
      );
    }
  }

  /// Clear current error message
  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});