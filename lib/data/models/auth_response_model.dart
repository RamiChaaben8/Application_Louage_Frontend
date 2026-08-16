// Simple model built directly from what AuthResponseDto returns
class AuthResponse {
  final String token;
  final int userId;
  final String firstName;
  final String lastName;
  final String userType;

  AuthResponse({
    required this.token,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.userType,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      userId: json['userId'] ?? 0,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      userType: json['userType'] ?? 'Customer',
    );
  }
}
