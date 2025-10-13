import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class LoginResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  LoginResponse({required this.success, required this.message, this.data});
}

Future<LoginResponse> loginUser({
  required String email,
  required String password,
}) async {
  final url = Uri.parse('${AppConstants.baseApiUrl}/auth/login');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      // Save the token locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', body['data']['access_token']);

      return LoginResponse(
        success: true,
        message: body['message'] ?? 'Login successful',
        data: body['data'],
      );
    } else {
      return LoginResponse(
        success: false,
        message: body['message'] ?? 'Login failed',
        data: null,
      );
    }
  } catch (e) {
    return LoginResponse(
      success: false,
      message: 'An error occurred: $e',
      data: null,
    );
  }
}

class RegisterResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  RegisterResponse({required this.success, required this.message, this.data});
}

Future<RegisterResponse> registerUser({
  required String email,
  required String username,
  required String password,
}) async {
  final url = Uri.parse('${AppConstants.baseApiUrl}/auth/register');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'username': username,
        'password': password,
      }),
    );

    final body = jsonDecode(response.body);

    if ((response.statusCode == 201 || response.statusCode == 200) &&
        body['success'] == true) {
      return RegisterResponse(
        success: true,
        message: body['message'] ?? 'User registered successfully',
        data: body['data'], // Usually null in your API
      );
    } else {
      return RegisterResponse(
        success: false,
        message: body['message'] ?? 'Registration failed',
        data: null,
      );
    }
  } catch (e) {
    return RegisterResponse(
      success: false,
      message: 'An error occurred: $e',
      data: null,
    );
  }
}

Future<String?> getAccessToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('access_token');
}
