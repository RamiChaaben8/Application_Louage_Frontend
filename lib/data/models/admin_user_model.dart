class AdminUser {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String userType;
  final String? licenseNumber;
  final String? status;
  final AdminVehicleInfo? vehicle;

  AdminUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.userType,
    this.licenseNumber,
    this.status,
    this.vehicle,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      userType: json['userType'] ?? '',
      licenseNumber: json['licenseNumber'],
      status: json['status'],
      vehicle: json['vehicle'] != null
          ? AdminVehicleInfo.fromJson(json['vehicle'])
          : null,
    );
  }
}

class AdminVehicleInfo {
  final int id;
  final String plate;
  final int capacity;
  final String status;

  AdminVehicleInfo({
    required this.id,
    required this.plate,
    required this.capacity,
    required this.status,
  });

  factory AdminVehicleInfo.fromJson(Map<String, dynamic> json) {
    return AdminVehicleInfo(
      id: json['id'],
      plate: json['plate'] ?? '',
      capacity: json['capacity'] ?? 0,
      status: json['status']?.toString() ?? 'Unknown',
    );
  }
}
