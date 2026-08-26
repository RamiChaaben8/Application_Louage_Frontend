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
        final authResponse = AuthResponse.fromJson(data, email: email);
        await _saveUser(authResponse);
        return (authResponse, null);
      }

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
      final url = ApiConstants.registerCustomerEndpoint;
      final body = jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'phoneNum': phoneNum,
      });

      print('[REGISTER CUSTOMER] POST $url');
      print('[REGISTER CUSTOMER] Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 10));

      print('[REGISTER CUSTOMER] Status: ${response.statusCode}');
      print('[REGISTER CUSTOMER] Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final authResponse = AuthResponse.fromJson(data, email: email);
        await _saveUser(authResponse);
        return (authResponse, null);
      }

      final error = _extractError(response.body, response.statusCode);
      return (null, error);
    } catch (e) {
      print('[REGISTER CUSTOMER] Exception: $e');
      return (null, 'Cannot connect to server: $e');
    }
  }

  Future<(AuthResponse?, String?)> registerDriver({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required int phoneNum,
    required String licenseNumber,
    required String plate,
    required int capacity,
    required List<int> stationIds,
  }) async {
    try {
      final url = ApiConstants.registerDriverEndpoint;
      final body = jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'phoneNum': phoneNum,
        'licenseNumber': licenseNumber,
        'plate': plate,
        'capacity': capacity,
        'stationIds': stationIds,
      });

      print('[REGISTER DRIVER] POST $url');
      print('[REGISTER DRIVER] Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 10));

      print('[REGISTER DRIVER] Status: ${response.statusCode}');
      print('[REGISTER DRIVER] Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final authResponse = AuthResponse.fromJson(data, email: email);
        await _saveUser(authResponse);
        return (authResponse, null);
      }

      final error = _extractError(response.body, response.statusCode);
      return (null, error);
    } catch (e) {
      print('[REGISTER DRIVER] Exception: $e');
      return (null, 'Cannot connect to server: $e');
    }
  }

  String _extractError(String body, int statusCode) {
    try {
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
    await _storage.write(key: 'email', value: r.email);
    if (r.status != null) {
      await _storage.write(key: 'status', value: r.status!);
    }
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
      email: await _storage.read(key: 'email') ?? '',
      status: await _storage.read(key: 'status'),
    );
  }

  Future<void> saveStatus(String status) async {
    await _storage.write(key: 'status', value: status);
  }

  Future<Map<String, dynamic>?> getDriverDetails(int driverId) async {
    try {
      final token = await getToken();
      final url = ApiConstants.driverStatusEndpoint(driverId);
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final status = (data['status'] ?? data['Status'])?.toString();
        if (status != null) {
          await _storage.write(key: 'status', value: status);
        }
        return data;
      }
      return null;
    } catch (e) {
      print('[AuthService] getDriverDetails error: $e');
      return null;
    }
  }

  Future<bool> updateDriverCurrentStation(int driverId, int stationId) async {
    try {
      final token = await getToken();
      final url = ApiConstants.driverCurrentStationEndpoint(driverId);
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(stationId),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('[AuthService] updateDriverCurrentStation error: $e');
      return false;
    }
  }
}
