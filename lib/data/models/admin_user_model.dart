class AdminUser {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final int? phoneNum;
  final String userType;
  final String? licenseNumber;
  final String? status;
  final AdminVehicleInfo? vehicle;

  AdminUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNum,
    required this.userType,
    this.licenseNumber,
    this.status,
    this.vehicle,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] ?? json['Id'] ?? 0,
      firstName: json['firstName'] ?? json['FirstName'] ?? '',
      lastName: json['lastName'] ?? json['LastName'] ?? '',
      email: json['email'] ?? json['Email'] ?? '',
      phoneNum: json['phoneNum'] ?? json['PhoneNum'],
      userType: json['userType'] ?? json['UserType'] ?? '',
      licenseNumber: json['licenseNumber'] ?? json['LicenseNumber'],
      status: (json['status'] ?? json['Status'])?.toString(),
      vehicle: (json['vehicle'] ?? json['Vehicle']) != null
          ? AdminVehicleInfo.fromJson(json['vehicle'] ?? json['Vehicle'])
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
