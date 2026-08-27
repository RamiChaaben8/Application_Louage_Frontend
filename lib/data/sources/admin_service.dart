import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/admin_user_model.dart';
import '../models/station_model.dart';
import '../models/vehicle_model.dart';
import '../models/trip_model.dart';

class AdminService {
  // ─── Users ──────────────────────────────────────────────────────────
  Future<(List<AdminUser>?, String?)> getAllUsers(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.adminUsersEndpoint),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final users = data.map((json) => AdminUser.fromJson(json)).toList();
        return (users, null);
      } else {
        return (null, _extractErrorMessage(response));
      }
    } catch (e) {
      return (null, e.toString());
    }
  }

  Future<(AdminUser?, String?)> createAdmin({
    required String token,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.adminCreateAdminEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return (AdminUser.fromJson(data), null);
      } else {
        return (null, _extractErrorMessage(response));
      }
    } catch (e) {
      return (null, e.toString());
    }
  }

  Future<bool> deleteUser(int id, String token) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConstants.adminDeleteUserEndpoint(id)),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // ─── Pending Drivers ────────────────────────────────────────────────
  Future<(List<AdminUser>?, String?)> getPendingDrivers(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.adminPendingDriversEndpoint),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final drivers = data.map((json) => AdminUser.fromJson(json)).toList();
        return (drivers, null);
      } else {
        return (null, _extractErrorMessage(response));
      }
    } catch (e) {
      return (null, e.toString());
    }
  }

  Future<(AdminUser?, String?)> approveDriver(int id, String token) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConstants.adminApproveDriverEndpoint(id)),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (AdminUser.fromJson(data), null);
      } else {
        return (null, _extractErrorMessage(response));
      }
    } catch (e) {
      return (null, e.toString());
    }
  }

  Future<(AdminUser?, String?)> declineDriver(int id, String token) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConstants.adminDeclineDriverEndpoint(id)),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (AdminUser.fromJson(data), null);
      } else {
        return (null, _extractErrorMessage(response));
      }
    } catch (e) {
      return (null, e.toString());
    }
  }

  Future<(List<AdminUser>?, String?)> getAvailableDrivers(String token, {int? stationId}) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.adminAvailableDriversEndpoint(stationId: stationId)),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final drivers = data.map((json) => AdminUser.fromJson(json)).toList();
        return (drivers, null);
      } else {
        return (null, _extractErrorMessage(response));
      }
    } catch (e) {
      return (null, e.toString());
    }
  }

  // ─── Stations ───────────────────────────────────────────────────────
  Future<List<Station>> getAllStations() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.stationsEndpoint));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Station.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<(Station?, String?)> createStation({
    required String token,
    required String name,
    required String city,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.stationsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name, 'city': city}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return (Station.fromJson(data), null);
      } else {
        return (null, _extractErrorMessage(response));
      }
    } catch (e) {
      return (null, e.toString());
    }
  }

  Future<bool> deleteStation(int id, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.stationsEndpoint}/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // ─── Vehicles ───────────────────────────────────────────────────────
  Future<List<Vehicle>> getAllVehicles() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.vehiclesEndpoint));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Vehicle.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<(Vehicle?, String?)> createVehicle({
    required String token,
    required String plate,
    required int capacity,
    required int driverId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.vehiclesEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'plate': plate,
          'capacity': capacity,
          'driverId': driverId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return (Vehicle.fromJson(data), null);
      } else {
        return (null, _extractErrorMessage(response));
      }
    } catch (e) {
      return (null, e.toString());
    }
  }

  Future<bool> deleteVehicle(int id, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.vehiclesEndpoint}/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // ─── Trips ──────────────────────────────────────────────────────────
  Future<List<Trip>> getAllTrips() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.tripsEndpoint));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Trip.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> updateTripStatus(int id, int statusIndex, String token) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.tripsEndpoint}/$id/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(statusIndex),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<(Trip?, String?)> createTrip({
    required String token,
    required int startStationId,
    required int endStationId,
    required DateTime departureTime,
    int? driverId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.tripsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'startStationId': startStationId,
          'endStationId': endStationId,
          'departureTime': departureTime.toIso8601String(),
          if (driverId != null) 'driverId': driverId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return (Trip.fromJson(data), null);
      } else {
        return (null, _extractErrorMessage(response));
      }
    } catch (e) {
      return (null, e.toString());
    }
  }

  Future<bool> deleteTrip(int id, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.tripsEndpoint}/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<bool> bookOfflineTicket({
    required int tripId,
    required String passengerName,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/Tickets/buy-offline?tripId=$tripId&passengerName=${Uri.encodeComponent(passengerName)}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is String) return decoded;
      if (decoded is Map<String, dynamic> && decoded.containsKey('message')) {
        return decoded['message'];
      }
      if (decoded is Map<String, dynamic> && decoded.containsKey('title')) {
        return decoded['title'];
      }
      return 'Request failed with status: ${response.statusCode}';
    } catch (_) {
      return 'Request failed with status: ${response.statusCode}';
    }
  }
}
