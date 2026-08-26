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
      token: json['token'] ?? json['Token'] ?? '',
      userId: json['userId'] ?? json['UserId'] ?? json['id'] ?? json['Id'] ?? 0,
      firstName: json['firstName'] ?? json['FirstName'] ?? '',
      lastName: json['lastName'] ?? json['LastName'] ?? '',
      userType: json['userType'] ?? json['UserType'] ?? 'Customer',
      email: json['email'] ?? json['Email'] ?? email,
      status: (json['status'] ?? json['Status'])?.toString(),
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

