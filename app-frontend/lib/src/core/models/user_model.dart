class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String? role;
  final String? googleId;
  final bool hasPassword;

  // Computed property to easily get the full name.
  String get fullName => '$firstName $lastName';

  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.role,
    this.googleId,
    required this.hasPassword,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Helper to extract Role Name from the nested object {id: 2, name: "USER"}
    String? parsedRole;
    if (json['role'] != null) {
      if (json['role'] is Map) {
        parsedRole = json['role']['name']?.toString();
      } else if (json['role'] is String) {
        parsedRole = json['role'];
      }
    }

    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      role: parsedRole,
      googleId: json['googleId']?.toString(),
      // Parse hasPassword, defaulting to false if missing
      hasPassword: json['hasPassword'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'googleId': googleId,
      'hasPassword': hasPassword,
    };
  }
}
