import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart'; // <-- import your baseApiUrl

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
