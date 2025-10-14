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
      // Save the token, user_id, and expires_in locally
      final prefs = await SharedPreferences.getInstance();

      // Save current timestamp (in seconds since epoch)
      await prefs.setInt(
        'login_timestamp',
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

      await prefs.setString(
        'access_token',
        body['data']['access_token'].toString(),
      );
      await prefs.setString(
        'user_id',
        body['data']['user']['user_id'].toString(),
      );

      // Handle expires_in - convert to int if it's a string or number
      final expiresIn = body['data']['expires_in'];
      if (expiresIn != null) {
        await prefs.setInt(
          'expires_in',
          expiresIn is int ? expiresIn : int.parse(expiresIn.toString()),
        );
      }

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

Future<bool> isTokenValid() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');
  final expiresIn = prefs.getInt('expires_in');
  final loginTime = prefs.getInt('login_timestamp');

  if (token == null || expiresIn == null) {
    return false;
  }

  // If we don't have a login timestamp, we can't validate expiry
  if (loginTime == null) {
    return false;
  }

  // Calculate expiry time
  final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final expiryTime = loginTime + expiresIn;

  return currentTime < expiryTime;
}

Future<void> logout() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('access_token');
  await prefs.remove('user_id');
  await prefs.remove('expires_in');
  await prefs.remove('login_timestamp');
}
