// lib/src/core/models/user_model.dart

// A simple data model to hold user profile information.
class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String email;

  // Computed property to easily get the full name.
  String get fullName => '$firstName $lastName';

  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
  });

  // A factory constructor to create a UserModel from a JSON map.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      return UserModel(
        id: json['id'] as int,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        phoneNumber: json['phoneNumber'] as String,
        email: json['email'] as String,
      );
    } catch (e) {
      // If parsing fails, throw a clear error.
      throw const FormatException('Failed to parse UserModel from JSON');
    }
  }
}
