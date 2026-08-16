import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_constants.dart';
import '../models/auth_response_model.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  // Returns (AuthResponse, errorMessage)
  Future<(AuthResponse?, String?)> login(String email, String password) async {
    try {
      final url = ApiConstants.loginEndpoint;
      print('[LOGIN] POST $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      print('[LOGIN] Status: ${response.statusCode}');
      print('[LOGIN] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final authResponse = AuthResponse.fromJson(data);
        await _saveUser(authResponse);
        return (authResponse, null);
      }

      // Extract readable error from body
      final error = _extractError(response.body, response.statusCode);
      return (null, error);
    } catch (e) {
      print('[LOGIN] Exception: $e');
      return (null, 'Cannot connect to server: $e');
    }
  }

  Future<(AuthResponse?, String?)> registerCustomer({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required int phoneNum,
  }) async {
    try {
      final url = ApiConstants.registerEndpoint;
      final body = jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'phoneNum': phoneNum,
      });

      print('[REGISTER] POST $url');
      print('[REGISTER] Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 10));

      print('[REGISTER] Status: ${response.statusCode}');
      print('[REGISTER] Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final authResponse = AuthResponse.fromJson(data);
        await _saveUser(authResponse);
        return (authResponse, null);
      }

      final error = _extractError(response.body, response.statusCode);
      return (null, error);
    } catch (e) {
      print('[REGISTER] Exception: $e');
      return (null, 'Cannot connect to server: $e');
    }
  }

  String _extractError(String body, int statusCode) {
    try {
      // Try to parse JSON error
      final decoded = jsonDecode(body);
      if (decoded is String) return decoded;
      if (decoded is Map && decoded.containsKey('title')) return decoded['title'];
      if (decoded is Map && decoded.containsKey('message')) return decoded['message'];
      return body.isNotEmpty ? body : 'Server error ($statusCode)';
    } catch (_) {
      return body.isNotEmpty ? body : 'Server error ($statusCode)';
    }
  }

  Future<void> _saveUser(AuthResponse r) async {
    await _storage.write(key: 'jwt_token', value: r.token);
    await _storage.write(key: 'user_id', value: r.userId.toString());
    await _storage.write(key: 'user_type', value: r.userType);
    await _storage.write(key: 'first_name', value: r.firstName);
    await _storage.write(key: 'last_name', value: r.lastName);
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<AuthResponse?> getStoredUser() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return null;
    return AuthResponse(
      token: token,
      userId: int.tryParse(await _storage.read(key: 'user_id') ?? '') ?? 0,
      firstName: await _storage.read(key: 'first_name') ?? '',
      lastName: await _storage.read(key: 'last_name') ?? '',
      userType: await _storage.read(key: 'user_type') ?? 'Customer',
    );
  }
}
