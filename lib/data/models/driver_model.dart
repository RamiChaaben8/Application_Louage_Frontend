import 'user_model.dart';
import 'vehicle_model.dart';

class Driver extends User {
  final String licenseNumber;
  final bool isAvailable;
  final Vehicle? vehicle;

  Driver({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.email,
    required super.phoneNum,
    required this.licenseNumber,
    required this.isAvailable,
    this.vehicle,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phoneNum: json['phoneNum'] ?? 0,
      licenseNumber: json['licenseNumber'] ?? '',
      isAvailable: json['isAvailable'] ?? false,
      vehicle: json['vehicle'] != null ? Vehicle.fromJson(json['vehicle']) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data['licenseNumber'] = licenseNumber;
    data['isAvailable'] = isAvailable;
    if (vehicle != null) {
      data['vehicle'] = vehicle!.toJson();
    }
    return data;
  }
}
