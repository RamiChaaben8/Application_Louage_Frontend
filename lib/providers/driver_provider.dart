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

  bool get isApproved => _driverStatus?.toLowerCase() == 'approved';
  bool get isDeclined => _driverStatus?.toLowerCase() == 'declined';
  bool get isPending => !isApproved && !isDeclined;

  // Driver can access dashboard if approved or has assigned vehicle
  bool get isVerified => isApproved;

  Future<void> checkDriverStatus(int driverId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final status = await _authService.getDriverStatus(driverId);
      if (status != null) {
        _driverStatus = status;
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

    final success = await _vehicleService.updateVehicleStatus(_assignedVehicle!.id, status);

    if (success) {
      // Re-fetch vehicle details
      _assignedVehicle = await _vehicleService.getDriverVehicle(_assignedVehicle!.driverId);
    }

    _isUpdatingStatus = false;
    notifyListeners();
    return success;
  }
}
