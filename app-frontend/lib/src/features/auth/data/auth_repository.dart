import 'package:al_faruk_app/src/core/models/user_model.dart';
import 'package:dio/dio.dart';
import 'auth_models.dart';

// --- EXCEPTIONS ---
class RegistrationException implements Exception {
  final String message;
  RegistrationException(this.message);
  @override
  String toString() => message;
}

class LoginException implements Exception {
  final String message;
  LoginException(this.message);
  @override
  String toString() => message;
}

class ProfileException implements Exception {
  final String message;
  ProfileException(this.message);
  @override
  String toString() => message;
}

class ForgotPasswordException implements Exception {
  final String message;
  ForgotPasswordException(this.message);
  @override
  String toString() => message;
}

class ResetPasswordException implements Exception {
  final String message;
  ResetPasswordException(this.message);
  @override
  String toString() => message;
}

class ChangePasswordException implements Exception {
  final String message;
  ChangePasswordException(this.message);
  @override
  String toString() => message;
}

class SetPasswordException implements Exception {
  final String message;
  SetPasswordException(this.message);
  @override
  String toString() => message;
}

// --- REPOSITORY ---
class AuthRepository {
  final Dio _dio;
  AuthRepository({required Dio dio}) : _dio = dio;

  // --- GET PROFILE METHOD ---
  Future<UserModel> getProfile() async {
    try {
      print("🔹 Fetching Profile...");
      final response = await _dio.get('/auth/profile');
      print("✅ Profile Fetched Successfully: ${response.data}");
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      print("🚨 PROFILE ERROR CODE: ${e.response?.statusCode}");
      print("🚨 PROFILE ERROR DATA: ${e.response?.data}");

      if (e.response != null && e.response!.data != null) {
        final dynamic msg = e.response!.data['message'];
        final String errorMessage = msg is List
            ? msg.join('\n')
            : msg?.toString() ?? 'Failed to load profile.';
        throw ProfileException(errorMessage);
      } else {
        throw ProfileException('Network error. Please check your connection.');
      }
    } catch (e) {
      print("🚨 UNEXPECTED ERROR: $e");
      throw ProfileException(
          'An unexpected error occurred while fetching your profile.');
    }
  }

  // --- SET PASSWORD METHOD (UPDATED TO PATCH) ---
  Future<String> setPassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      // FIX: Changed to PATCH based on your Swagger screenshot
      final response = await _dio.patch(
        '/auth/set-password',
        data: {
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );
      return response.data['message'] as String;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final dynamic msg = e.response!.data['message'];
        final String errorMessage = msg is List
            ? msg.join('\n')
            : msg?.toString() ?? 'An unknown server error occurred.';
        throw SetPasswordException(errorMessage);
      } else {
        throw SetPasswordException(
            'Failed to connect to the server. Please check your internet connection.');
      }
    } catch (e) {
      throw SetPasswordException(
          'An unexpected error occurred. Please try again.');
    }
  }

  // --- CHANGE PASSWORD METHOD ---
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dio.patch(
        '/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );
      return response.data['message'] as String;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final dynamic msg = e.response!.data['message'];
        final String errorMessage = msg is List
            ? msg.join('\n')
            : msg?.toString() ?? 'An unknown server error occurred.';
        throw ChangePasswordException(errorMessage);
      } else {
        throw ChangePasswordException(
            'Failed to connect to the server. Please check your internet connection.');
      }
    } catch (e) {
      throw ChangePasswordException(
          'An unexpected error occurred. Please try again.');
    }
  }

  // --- RESET PASSWORD METHOD ---
  Future<String> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/reset-password',
        data: {
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );
      return response.data['message'] as String;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final dynamic msg = e.response!.data['message'];
        final String errorMessage = msg is List
            ? msg.join('\n')
            : msg?.toString() ?? 'An unknown server error occurred.';
        throw ResetPasswordException(errorMessage);
      } else {
        throw ResetPasswordException(
            'Failed to connect to the server. Please check your internet connection.');
      }
    } catch (e) {
      throw ResetPasswordException(
          'An unexpected error occurred. Please try again.');
    }
  }

  // --- FORGOT PASSWORD METHOD ---
  Future<String> forgotPassword({required String email}) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
      return response.data['message'] as String;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final dynamic msg = e.response!.data['message'];
        final String errorMessage = msg is List
            ? msg.join('\n')
            : msg?.toString() ?? 'An unknown server error occurred.';
        throw ForgotPasswordException(errorMessage);
      } else {
        throw ForgotPasswordException(
            'Failed to connect to the server. Please check your internet connection.');
      }
    } catch (e) {
      throw ForgotPasswordException(
          'An unexpected error occurred. Please try again.');
    }
  }

  // --- LOGIN METHOD ---
  Future<LoginSuccessResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'loginIdentifier': email, 'password': password},
      );
      return LoginSuccessResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final dynamic msg = e.response!.data['message'];
        final String errorMessage = msg is List
            ? msg.join('\n')
            : msg?.toString() ?? 'An unknown server error occurred.';
        throw LoginException(errorMessage);
      } else {
        throw LoginException(
            'Failed to connect to the server. Please check your internet connection and try again.');
      }
    } catch (e) {
      throw LoginException('An unexpected error occurred. Please try again.');
    }
  }

  // --- REGISTER METHOD ---
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      await _dio.post(
        '/auth/register',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phoneNumber': phoneNumber,
          'password': password,
          'confirmPassword': confirmPassword,
          'agreedToTerms': true,
        },
      );
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final dynamic msg = e.response!.data['message'];
        final String errorMessage = msg is List
            ? msg.join('\n')
            : msg?.toString() ?? 'An unknown server error occurred.';
        throw RegistrationException(errorMessage);
      } else {
        throw RegistrationException(
            'Failed to connect to the server. Please check your internet connection and try again.');
      }
    } catch (e) {
      throw RegistrationException(
          'An unexpected error occurred. Please try again.');
    }
  }

  // --- GOOGLE LOGIN METHOD ---
  Future<LoginSuccessResponse> loginWithGoogle(String idToken) async {
    try {
      final response = await _dio.post(
        '/auth/google-mobile',
        data: {'token': idToken},
      );
      return LoginSuccessResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final dynamic msg = e.response!.data['message'];
        final String errorMessage = msg is List
            ? msg.join('\n')
            : msg?.toString() ?? 'Google login failed.';
        throw LoginException(errorMessage);
      } else {
        throw LoginException('Connection error. Please check your internet.');
      }
    } catch (e) {
      throw LoginException('An unexpected error occurred: $e');
    }
  }
}
