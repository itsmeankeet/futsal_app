import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../core/security/secure_storage.dart';

class AuthState {
  final String? token;
  final AppUser? user;
  final bool isLoading;
  final String? error;

  AuthState({this.token, this.user, this.isLoading = false, this.error});

  AuthState copyWith({String? token, AppUser? user, bool? isLoading, String? error}) {
    return AuthState(
      token: token ?? this.token,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isAuthenticated => token != null && user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final SecureStorageService _secureStorage = SecureStorageService();

  AuthNotifier(this._apiService) : super(AuthState()) {
    tryRestoreSession();
  }

  Future<void> tryRestoreSession() async {
    state = state.copyWith(isLoading: true);
    final token = await _secureStorage.getToken();
    if (token != null) {
      try {
        final profileData = await _apiService.getProfile();
        final user = AppUser.fromJson(profileData);
        state = AuthState(token: token, user: user);
      } catch (e) {
        await _secureStorage.clearSession();
        state = AuthState();
      }
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiService.login(username, password);
      final token = res['access'];
      
      // Save session securely
      await _secureStorage.saveSession(token: token, userId: '', role: '');

      // Load profile to set user
      final profileData = await _apiService.getProfile();
      final user = AppUser.fromJson(profileData);

      state = AuthState(token: token, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      rethrow;
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? companyName,
    String? panNumber,
    String? businessAddress,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.register(
        username: username,
        email: email,
        password: password,
        role: role,
        phone: phone,
        companyName: companyName,
        panNumber: panNumber,
        businessAddress: businessAddress,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      rethrow;
    }
  }

  Future<void> logout() async {
    await _secureStorage.clearSession();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthNotifier(apiService);
});
