import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/station_model.dart';
import '../models/trip_model.dart';
import 'auth_service.dart';

class TripService {
  // Fetch all stations
  Future<List<Station>> getStations() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.stationsEndpoint),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Station.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('[TripService] getStations error: $e');
      return [];
    }
  }

  // Fetch filtered trips
  Future<List<Trip>> getTrips({
    int? startStationId,
    int? endStationId,
    DateTime? date,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (startStationId != null && startStationId > 0) {
        queryParams['startStationId'] = startStationId.toString();
      }
      if (endStationId != null && endStationId > 0) {
        queryParams['endStationId'] = endStationId.toString();
      }
      if (date != null) {
        queryParams['date'] = date.toIso8601String();
      }

      final uri = Uri.parse(ApiConstants.tripsEndpoint).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      print('[TripService] GET $uri');
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('[TripService] Trips Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Trip.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('[TripService] getTrips error: $e');
      return [];
    }
  }

  // Fetch trip by ID
  Future<Trip?> getTripById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.tripsEndpoint}/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return Trip.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('[TripService] getTripById error: $e');
      return null;
    }
  }

  // Create a trip (by admin or driver)
  Future<bool> createTrip({
    required int startStationId,
    required int endStationId,
    required DateTime departureTime,
    int? driverId,
  }) async {
    try {
      final body = {
        'startStationId': startStationId,
        'endStationId': endStationId,
        'departureTime': departureTime.toIso8601String(),
      };
      if (driverId != null) {
        body['driverId'] = driverId;
      }

      final response = await http.post(
        Uri.parse(ApiConstants.tripsEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 201;
    } catch (e) {
      print('[TripService] createTrip error: $e');
      return false;
    }
  }

  final AuthService _authService = AuthService();

  // Update trip status
  Future<bool> updateTripStatus(int tripId, int statusIndex) async {
    try {
      final token = await _authService.getToken();
      final response = await http.put(
        Uri.parse('${ApiConstants.tripsEndpoint}/$tripId/status'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(statusIndex),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('[TripService] updateTripStatus error: $e');
      return false;
    }
  }
}
