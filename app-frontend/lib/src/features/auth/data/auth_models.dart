// lib/src/features/auth/data/auth_models.dart

class LoginSuccessResponse {
  final String accessToken;
  final int? sessionId; // Added sessionId

  const LoginSuccessResponse({
    required this.accessToken,
    this.sessionId,
  });

  factory LoginSuccessResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('access_token') && json['access_token'] is String) {
      return LoginSuccessResponse(
        accessToken: json['access_token'],
        // Parse sessionId (safely handle if it's missing or null)
        sessionId: json['sessionId'] is int ? json['sessionId'] : null,
      );
    } else {
      throw const FormatException(
          'Invalid JSON format for LoginSuccessResponse');
    }
  }
}
