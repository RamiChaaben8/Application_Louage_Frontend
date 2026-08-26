import 'user_model.dart';
import 'vehicle_model.dart';
import 'station_model.dart';

class Driver extends User {
  final String licenseNumber;
  final bool isAvailable;
  final Vehicle? vehicle;
  final String? status;
  final int? currentStationId;
  final Station? currentStation;
  final List<Station> stations;

  Driver({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.email,
    required super.phoneNum,
    required this.licenseNumber,
    required this.isAvailable,
    this.vehicle,
    this.status,
    this.currentStationId,
    this.currentStation,
    this.stations = const [],
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
      status: json['status'],
      currentStationId: json['currentStationId'],
      currentStation: json['currentStation'] != null ? Station.fromJson(json['currentStation']) : null,
      stations: json['stations'] != null
          ? (json['stations'] as List).map((s) => Station.fromJson(s)).toList()
          : [],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data['licenseNumber'] = licenseNumber;
    data['isAvailable'] = isAvailable;
    data['status'] = status;
    data['currentStationId'] = currentStationId;
    if (currentStation != null) {
      data['currentStation'] = currentStation!.toJson();
    }
    if (vehicle != null) {
      data['vehicle'] = vehicle!.toJson();
    }
    data['stations'] = stations.map((s) => s.toJson()).toList();
    return data;
  }
}
