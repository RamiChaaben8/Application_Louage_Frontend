abstract class User {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final int phoneNum;
  // Note: PasswordHash is usually omitted in frontend models for security reasons, 
  // but included here since it's on the base backend model.

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNum,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNum': phoneNum,
    };
  }
}
