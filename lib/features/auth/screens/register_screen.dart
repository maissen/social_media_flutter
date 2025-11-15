import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/auth_helpers.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();

  DateTime? selectedDate;
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    dateOfBirthController.dispose();
    super.dispose();
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dateOfBirthController.text =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _register() async {
    final email = emailController.text.trim();
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    String? errorMessage;

    if (email.isEmpty) {
      errorMessage = 'Please enter your email';
    } else if (!email.contains('@')) {
      errorMessage = 'Please enter a valid email';
    } else if (username.isEmpty) {
      errorMessage = 'Please enter your username';
    } else if (password.isEmpty) {
      errorMessage = 'Please enter your password';
    } else if (password.length < 6) {
      errorMessage = 'Password must be at least 6 characters';
    } else if (confirmPassword.isEmpty) {
      errorMessage = 'Please confirm your password';
    } else if (confirmPassword != password) {
      errorMessage = 'Passwords do not match';
    } else if (selectedDate == null) {
      errorMessage = 'Please select your date of birth';
    } else if (_calculateAge(selectedDate!) < 18) {
      errorMessage = 'You must be at least 18 years old to register';
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await registerUser(
      email: email,
      username: username,
      password: password,
    );

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response.message),
        backgroundColor: response.success
            ? Colors.green.shade400
            : Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (response.success) {
      Navigator.pop(context);
    }
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon, color: Colors.deepPurple.shade300),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
                labelStyle: TextStyle(color: Colors.grey.shade600),
              ),
              obscureText: obscureText,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              onTap: onTap,
              readOnly: readOnly,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade50,
              Colors.blue.shade50,
              Colors.deepPurple.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              // Back Button
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                    color: Colors.deepPurple,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Logo/Icon with gradient
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.deepPurple, Colors.blue],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Colors.deepPurple, Colors.blue],
                ).createShader(bounds),
                child: const Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign up to get started',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 40),

              // Email Field
              _buildGlassTextField(
                controller: emailController,
                label: 'Email',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Username Field (max 15 chars, no spaces)
              _buildGlassTextField(
                controller: usernameController,
                label: 'Username',
                icon: Icons.person_rounded,
                keyboardType: TextInputType.text,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  LengthLimitingTextInputFormatter(15),
                ],
              ),
              const SizedBox(height: 20),

              // Password Field
              _buildGlassTextField(
                controller: passwordController,
                label: 'Password',
                icon: Icons.lock_rounded,
                obscureText: true,
              ),
              const SizedBox(height: 20),

              // Confirm Password Field
              _buildGlassTextField(
                controller: confirmPasswordController,
                label: 'Confirm Password',
                icon: Icons.lock_outline_rounded,
                obscureText: true,
              ),
              const SizedBox(height: 20),

              // Date of Birth Field
              _buildGlassTextField(
                controller: dateOfBirthController,
                label: 'Date of Birth',
                icon: Icons.calendar_today_rounded,
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 32),

              // Register Button
              _isLoading
                  ? Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.deepPurple, Colors.blue],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.deepPurple, Colors.blue],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 24),

              // Already have an account
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Colors.deepPurple, Colors.blue],
                      ).createShader(bounds),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
