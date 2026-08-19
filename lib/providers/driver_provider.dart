import 'package:flutter/material.dart';
import '../data/models/vehicle_model.dart';
import '../data/models/enums.dart';
import '../data/sources/vehicle_service.dart';

class DriverProvider with ChangeNotifier {
  final VehicleService _vehicleService = VehicleService();

  Vehicle? _assignedVehicle;
  bool _isLoading = false;
  bool _isUpdatingStatus = false;
  String? _error;

  Vehicle? get assignedVehicle => _assignedVehicle;
  bool get isLoading => _isLoading;
  bool get isUpdatingStatus => _isUpdatingStatus;
  String? get error => _error;

  // A driver is considered verified and approved by the admin when they have an assigned vehicle in the system
  bool get isVerified => _assignedVehicle != null;

  Future<void> checkDriverStatus(int driverId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _assignedVehicle = await _vehicleService.getDriverVehicle(driverId);

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
