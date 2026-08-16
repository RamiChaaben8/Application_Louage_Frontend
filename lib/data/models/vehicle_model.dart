import 'enums.dart';
import 'driver_model.dart';

class Vehicle {
  final int id;
  final String plate;
  final int capacity;
  final VehicleStatus status;
  final int driverId;
  final Driver? driver;

  Vehicle({
    required this.id,
    required this.plate,
    required this.capacity,
    required this.status,
    required this.driverId,
    this.driver,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      plate: json['plate'] ?? '',
      capacity: json['capacity'] ?? 0,
      status: json['status'] != null
          ? VehicleStatusExtension.fromString(json['status'].toString())
          : VehicleStatus.available,
      driverId: json['driverId'] ?? 0,
      driver: json['driver'] != null ? Driver.fromJson(json['driver']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plate': plate,
      'capacity': capacity,
      'status': status.toString().split('.').last,
      'driverId': driverId,
      // Avoid circular toJson calls by omitting the nested driver object during serialization,
      // or implement partial serialization if needed.
    };
  }
}
