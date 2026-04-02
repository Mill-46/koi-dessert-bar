import 'package:flutter/material.dart';

import 'package:koi_dessert_bar/core/services/supabase_service.dart';
import 'package:koi_dessert_bar/features/auth/models/profile_model.dart';

class AuthProvider extends ChangeNotifier {
  ProfileModel? _profile;
  bool _isLoading = false;
  String? _error;

  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAdmin => _profile?.isAdmin ?? false;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<AuthActionResult> signIn(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      await SupabaseService.instance.signIn(email: email, password: password);
      await _loadProfile();
      return const AuthActionResult(success: true);
    } catch (e) {
      final message = SupabaseService.instance.describeAuthError(e);
      _setError(message);
      return AuthActionResult(success: false, message: message);
    } finally {
      _setLoading(false);
    }
  }

  Future<AuthActionResult> register(
    String email,
    String password,
    String fullName,
  ) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await SupabaseService.instance.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (response.session != null) {
        await _loadProfile();
        return const AuthActionResult(success: true);
      }

      return const AuthActionResult(
        success: true,
        requiresEmailConfirmation: true,
        message:
            'Akun berhasil dibuat. Cek email Anda untuk verifikasi sebelum login.',
      );
    } catch (e) {
      final message = SupabaseService.instance.describeAuthError(e);
      _setError(message);
      return AuthActionResult(success: false, message: message);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadProfile() async {
    if (!SupabaseService.instance.isLoggedIn) {
      _profile = null;
      notifyListeners();
      return;
    }

    _profile = await SupabaseService.instance.fetchProfile();
    notifyListeners();
  }

  Future<void> loadProfile() => _loadProfile();

  Future<void> signOut() async {
    await SupabaseService.instance.signOut();
    _profile = null;
    notifyListeners();
  }
}

class AuthActionResult {
  final bool success;
  final bool requiresEmailConfirmation;
  final String? message;

  const AuthActionResult({
    required this.success,
    this.requiresEmailConfirmation = false,
    this.message,
  });
}
