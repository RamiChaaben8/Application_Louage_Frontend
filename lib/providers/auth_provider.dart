import 'package:flutter/material.dart';
import '../data/sources/auth_service.dart';
import '../data/models/auth_response_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthResponse? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthResponse? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get isDriver => _currentUser?.userType.toLowerCase() == 'driver';
  bool get isCustomer => _currentUser?.userType.toLowerCase() == 'customer';
  bool get isAdmin => _currentUser?.userType.toLowerCase() == 'admin';
  String? get error => _error;

  Future<void> tryRestoreSession() async {
    _currentUser = await _authService.getStoredUser();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final (user, err) = await _authService.login(email, password);
    _currentUser = user;
    _error = err;

    _isLoading = false;
    notifyListeners();

    return _currentUser != null;
  }

  Future<bool> registerCustomer({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required int phoneNum,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final (user, err) = await _authService.registerCustomer(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      phoneNum: phoneNum,
    );
    _currentUser = user;
    _error = err;

    _isLoading = false;
    notifyListeners();

    return _currentUser != null;
  }

  Future<bool> registerDriver({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required int phoneNum,
    required String licenseNumber,
    required String plate,
    required int capacity,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final (user, err) = await _authService.registerDriver(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      phoneNum: phoneNum,
      licenseNumber: licenseNumber,
      plate: plate,
      capacity: capacity,
    );
    _currentUser = user;
    _error = err;

    _isLoading = false;
    notifyListeners();

    return _currentUser != null;
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }
}
