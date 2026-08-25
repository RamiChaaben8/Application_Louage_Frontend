import 'package:flutter/material.dart';
import '../data/models/vehicle_model.dart';
import '../data/models/enums.dart';
import '../data/sources/vehicle_service.dart';
import '../data/sources/auth_service.dart';

class DriverProvider with ChangeNotifier {
  final VehicleService _vehicleService = VehicleService();
  final AuthService _authService = AuthService();

  Vehicle? _assignedVehicle;
  String? _driverStatus;
  bool _isLoading = false;
  bool _isUpdatingStatus = false;
  String? _error;

  Vehicle? get assignedVehicle => _assignedVehicle;
  String? get driverStatus => _driverStatus;
  bool get isLoading => _isLoading;
  bool get isUpdatingStatus => _isUpdatingStatus;
  String? get error => _error;

  bool _isApprovedStatus(String? s) {
    if (s == null) return false;
    final lower = s.trim().toLowerCase();
    return lower == 'approved' || lower == '1' || lower.contains('approved');
  }

  bool _isDeclinedStatus(String? s) {
    if (s == null) return false;
    final lower = s.trim().toLowerCase();
    return lower == 'declined' || lower == '2' || lower.contains('declined');
  }

  bool get isApproved => _isApprovedStatus(_driverStatus) || _assignedVehicle != null;
  bool get isDeclined => _isDeclinedStatus(_driverStatus) && !isApproved;
  bool get isPending => !isApproved && !isDeclined;

  // Driver can access dashboard if approved or has assigned vehicle
  bool get isVerified => isApproved;

  bool isUserApproved(dynamic user) {
    if (isApproved) return true;
    final userStatus = (user != null && user.status != null) ? user.status.toString() : null;
    if (_isApprovedStatus(userStatus)) return true;
    if (_assignedVehicle != null) return true;
    return false;
  }

  Future<void> checkDriverStatus(int driverId, {String? fallbackStatus, Function(String)? onStatusUpdated}) async {
    if (_driverStatus == null && fallbackStatus != null) {
      _driverStatus = fallbackStatus;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final status = await _authService.getDriverStatus(driverId);
      if (status != null) {
        _driverStatus = status;
        onStatusUpdated?.call(status);
      }

      _assignedVehicle = await _vehicleService.getDriverVehicle(driverId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
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
