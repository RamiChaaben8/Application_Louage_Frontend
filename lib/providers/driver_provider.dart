import 'package:flutter/material.dart';
import '../data/models/vehicle_model.dart';
import '../data/models/station_model.dart';
import '../data/models/enums.dart';
import '../data/sources/vehicle_service.dart';
import '../data/sources/auth_service.dart';

class DriverProvider with ChangeNotifier {
  final VehicleService _vehicleService = VehicleService();
  final AuthService _authService = AuthService();

  Vehicle? _assignedVehicle;
  Station? _currentStation;
  List<Station> _driverStations = [];
  String? _driverStatus;
  bool _isLoading = false;
  bool _isUpdatingStatus = false;
  bool _isUpdatingStation = false;
  String? _error;

  Vehicle? get assignedVehicle => _assignedVehicle;
  Station? get currentStation => _currentStation;
  List<Station> get driverStations => _driverStations;
  String? get driverStatus => _driverStatus;
  bool get isLoading => _isLoading;
  bool get isUpdatingStatus => _isUpdatingStatus;
  bool get isUpdatingStation => _isUpdatingStation;
  String? get error => _error;

  bool _isApprovedStatus(String? s) {
    if (s == null) return false;
    final lower = s.trim().toLowerCase();
    return lower == 'approved' || lower == '1' || lower == 'driverstatus.approved';
  }

  bool _isDeclinedStatus(String? s) {
    if (s == null) return false;
    final lower = s.trim().toLowerCase();
    return lower == 'declined' || lower == '2' || lower == 'driverstatus.declined';
  }

  bool get isApproved => _isApprovedStatus(_driverStatus);
  bool get isDeclined => _isDeclinedStatus(_driverStatus) && !isApproved;
  bool get isPending => !isApproved && !isDeclined;

  // Driver can only access dashboard if explicitly approved by Admin
  bool get isVerified => isApproved;

  bool isUserApproved(dynamic user) {
    if (isApproved) return true;
    final userStatus = (user != null && user.status != null) ? user.status.toString() : null;
    return _isApprovedStatus(userStatus);
  }

  Future<void> checkDriverStatus(int driverId, {String? fallbackStatus, Function(String)? onStatusUpdated}) async {
    if (_driverStatus == null && fallbackStatus != null) {
      _driverStatus = fallbackStatus;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final details = await _authService.getDriverDetails(driverId);
      if (details != null) {
        final status = (details['status'] ?? details['Status'])?.toString();
        if (status != null) {
          _driverStatus = status;
          onStatusUpdated?.call(status);
        }

        final currentStationData = details['currentStation'] ?? details['CurrentStation'];
        if (currentStationData != null) {
          _currentStation = Station.fromJson(currentStationData);
        } else {
          _currentStation = null;
        }

        final stationsData = details['stations'] ?? details['Stations'];
        if (stationsData is List) {
          _driverStations = stationsData.map((s) => Station.fromJson(s)).toList();
        }
      }

      _assignedVehicle = await _vehicleService.getDriverVehicle(driverId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateCurrentStation(int driverId, int stationId) async {
    _isUpdatingStation = true;
    notifyListeners();

    final success = await _authService.updateDriverCurrentStation(driverId, stationId);
    if (success) {
      // Re-fetch details to ensure complete sync
      await checkDriverStatus(driverId);
    }

    _isUpdatingStation = false;
    notifyListeners();
    return success;
  }

  Future<bool> setVehicleStatus(VehicleStatus status) async {
    if (_assignedVehicle == null) return false;

    _isUpdatingStatus = true;
    notifyListeners();

    final currentVehicle = _assignedVehicle!;
    final success = await _vehicleService.updateVehicleStatus(currentVehicle.id, status);

    if (success) {
      // Optimistically update vehicle status immediately
      _assignedVehicle = currentVehicle.copyWith(status: status);
      notifyListeners();

      // Re-fetch vehicle details to stay synced with backend
      final refreshed = await _vehicleService.getDriverVehicle(currentVehicle.driverId);
      if (refreshed != null) {
        _assignedVehicle = refreshed;
      }
    }

    _isUpdatingStatus = false;
    notifyListeners();
    return success;
  }
}
