import 'package:flutter/material.dart';
import '../data/models/admin_user_model.dart';
import '../data/models/station_model.dart';
import '../data/models/vehicle_model.dart';
import '../data/models/trip_model.dart';
import '../data/sources/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  List<AdminUser> users = [];
  List<AdminUser> pendingDrivers = [];
  List<Station> stations = [];
  List<Vehicle> vehicles = [];
  List<Trip> trips = [];

  bool isLoading = false;
  String? error;

  // ─── Users ──────────────────────────────────────────────────────────
  Future<void> fetchUsers(String token) async {
    _setLoading(true);
    final (fetchedUsers, fetchError) = await _adminService.getAllUsers(token);

    if (fetchError != null) {
      error = fetchError;
    } else {
      users = fetchedUsers ?? [];
      error = null;
    }
    _setLoading(false);
  }

  Future<bool> createAdmin({
    required String token,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    final (admin, err) = await _adminService.createAdmin(
      token: token,
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
    );

    if (err != null) {
      error = err;
      _setLoading(false);
      return false;
    }

    await fetchUsers(token);
    return true;
  }

  Future<bool> deleteUser(int id, String token) async {
    _setLoading(true);
    final success = await _adminService.deleteUser(id, token);

    if (!success) {
      error = 'Failed to delete user';
      _setLoading(false);
      return false;
    }

    await fetchUsers(token);
    return true;
  }

  // ─── Pending Drivers ────────────────────────────────────────────────
  Future<void> fetchPendingDrivers(String token) async {
    _setLoading(true);
    final (fetchedDrivers, fetchError) = await _adminService.getPendingDrivers(token);

    if (fetchError != null) {
      error = fetchError;
    } else {
      pendingDrivers = fetchedDrivers ?? [];
      error = null;
    }
    _setLoading(false);
  }

  Future<bool> approveDriver(int id, String token) async {
    _setLoading(true);
    final (approvedDriver, approveError) = await _adminService.approveDriver(id, token);

    if (approveError != null) {
      error = approveError;
      _setLoading(false);
      return false;
    }

    await fetchPendingDrivers(token);
    return true;
  }

  Future<bool> declineDriver(int id, String token) async {
    _setLoading(true);
    final (declinedDriver, declineError) = await _adminService.declineDriver(id, token);

    if (declineError != null) {
      error = declineError;
      _setLoading(false);
      return false;
    }

    await fetchPendingDrivers(token);
    return true;
  }

  // ─── Stations ───────────────────────────────────────────────────────
  Future<void> fetchStations() async {
    _setLoading(true);
    stations = await _adminService.getAllStations();
    _setLoading(false);
  }

  Future<bool> createStation({
    required String token,
    required String name,
    required String city,
  }) async {
    _setLoading(true);
    final (station, err) = await _adminService.createStation(
      token: token,
      name: name,
      city: city,
    );

    if (err != null) {
      error = err;
      _setLoading(false);
      return false;
    }

    await fetchStations();
    return true;
  }

  Future<bool> deleteStation(int id, String token) async {
    _setLoading(true);
    final success = await _adminService.deleteStation(id, token);
    if (!success) {
      error = 'Failed to delete station';
      _setLoading(false);
      return false;
    }
    await fetchStations();
    return true;
  }

  // ─── Vehicles ───────────────────────────────────────────────────────
  Future<void> fetchVehicles() async {
    _setLoading(true);
    vehicles = await _adminService.getAllVehicles();
    _setLoading(false);
  }

  Future<bool> createVehicle({
    required String token,
    required String plate,
    required int capacity,
    required int driverId,
  }) async {
    _setLoading(true);
    final (vehicle, err) = await _adminService.createVehicle(
      token: token,
      plate: plate,
      capacity: capacity,
      driverId: driverId,
    );

    if (err != null) {
      error = err;
      _setLoading(false);
      return false;
    }

    await fetchVehicles();
    return true;
  }

  Future<bool> deleteVehicle(int id, String token) async {
    _setLoading(true);
    final success = await _adminService.deleteVehicle(id, token);
    if (!success) {
      error = 'Failed to delete vehicle';
      _setLoading(false);
      return false;
    }
    await fetchVehicles();
    return true;
  }

  // ─── Trips ──────────────────────────────────────────────────────────
  Future<void> fetchTrips() async {
    _setLoading(true);
    trips = await _adminService.getAllTrips();
    _setLoading(false);
  }

  Future<bool> createTrip({
    required String token,
    required int startStationId,
    required int endStationId,
    required DateTime departureTime,
  }) async {
    _setLoading(true);
    final (trip, err) = await _adminService.createTrip(
      token: token,
      startStationId: startStationId,
      endStationId: endStationId,
      departureTime: departureTime,
    );

    if (err != null) {
      error = err;
      _setLoading(false);
      return false;
    }

    await fetchTrips();
    return true;
  }

  Future<bool> deleteTrip(int id, String token) async {
    _setLoading(true);
    final success = await _adminService.deleteTrip(id, token);
    if (!success) {
      error = 'Failed to delete trip';
      _setLoading(false);
      return false;
    }
    await fetchTrips();
    return true;
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
