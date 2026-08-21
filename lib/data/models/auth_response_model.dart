class AuthResponse {
  final String token;
  final int userId;
  final String firstName;
  final String lastName;
  final String userType;
  final String email;
  final String? status;

  AuthResponse({
    required this.token,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.userType,
    this.email = '',
    this.status,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json, {String email = ''}) {
    return AuthResponse(
      token: json['token'] ?? '',
      userId: json['userId'] ?? 0,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      userType: json['userType'] ?? 'Customer',
      email: json['email'] ?? email,
      status: json['status'],
    );
  }

  AuthResponse copyWith({String? email, String? status}) {
    return AuthResponse(
      token: token,
      userId: userId,
      firstName: firstName,
      lastName: lastName,
      userType: userType,
      email: email ?? this.email,
      status: status ?? this.status,
    );
  }
}
