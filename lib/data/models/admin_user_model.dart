class AdminUser {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String userType;
  final String? licenseNumber;

  AdminUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.userType,
    this.licenseNumber,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      userType: json['userType'] ?? '',
      licenseNumber: json['licenseNumber'],
    );
  }
}
