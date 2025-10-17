import 'package:flutter/material.dart';
import 'package:plagiarishield_sim/screens/signup_screen.dart';
import 'package:plagiarishield_sim/storage/credential_storage.dart';
import 'package:plagiarishield_sim/screens/home_screen.dart';

/// LoginScreen widget - handles user authentication.
/// Users enter their credentials, which are validated against
/// stored data via [CredentialService]. If valid, the app redirects
/// to the HomeScreen; otherwise, an error message is shown.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers for username and password input fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isButtonEnabled = false; // Enables login button only when both fields are filled
  String? _errorMessage; // Stores error messages (invalid login, etc.)

  /// Checks if both username and password fields are non-empty
  /// to enable or disable the login button dynamically.
  void _checkInput() {
    setState(() {
      _isButtonEnabled = _usernameController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
    });
  }

  /// Handles login logic:
  /// - Validates user credentials through CredentialService
  /// - Navigates to HomeScreen if successful
  /// - Displays error message if credentials are invalid
  Future<void> _login() async {
    final success = await CredentialService.instance.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success) {
      // Navigate to HomeScreen after successful login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      // Show error message if login fails
      setState(() {
        _errorMessage = 'Invalid username or password';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Add listeners to both input fields for real-time button enabling/disabling
    _usernameController.addListener(_checkInput);
    _passwordController.addListener(_checkInput);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3fc4fe), // App theme color
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8, // Adds shadow effect
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App logo
                  Image.asset('assets/logo.png', height: 80),
                  const SizedBox(height: 20),

                  // Login title
                  Text(
                    'Login',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3fc4fe),
                        ),
                  ),
                  const SizedBox(height: 20),

                  // Username input field
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Password input field (obscured)
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),

                  // Error message if login fails
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3fc4fe),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isButtonEnabled ? _login : null, // Disabled if inputs are empty
                      child: const Text(
                        'Login',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Redirect to SignupScreen if user has no account
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignupScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Don't have an account? Sign up",
                      style: TextStyle(color: Color(0xFF3fc4fe)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
