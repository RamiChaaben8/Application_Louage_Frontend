import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/vehicle_model.dart';
import '../models/enums.dart';
import 'auth_service.dart';

class VehicleService {
  // Fetch all vehicles
  Future<List<Vehicle>> getAllVehicles() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.vehiclesEndpoint),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Vehicle.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('[VehicleService] getAllVehicles error: $e');
      return [];
    }
  }

  // Find vehicle assigned to a specific driver
  Future<Vehicle?> getDriverVehicle(int driverId) async {
    try {
      final vehicles = await getAllVehicles();
      final matches = vehicles.where((v) => v.driverId == driverId);
      if (matches.isNotEmpty) {
        return matches.first;
      }
      return null;
    } catch (e) {
      print('[VehicleService] getDriverVehicle error: $e');
      return null;
    }
  }

  final AuthService _authService = AuthService();

  // Update vehicle status
  Future<bool> updateVehicleStatus(int vehicleId, VehicleStatus status) async {
    try {
      final token = await _authService.getToken();
      final url = '${ApiConstants.vehiclesEndpoint}/$vehicleId/status';
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(status.index), // or status name
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('[VehicleService] updateVehicleStatus error: $e');
      return false;
    }
  }
}
