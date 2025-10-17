import 'package:flutter/material.dart';
import 'package:plagiarishield_sim/screens/login_screen.dart';
import 'package:plagiarishield_sim/storage/credential_storage.dart';

/// SignupScreen widget - allows users to create a new account.
/// Validates inputs, checks if the username already exists,
/// and redirects to the LoginScreen upon successful registration.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Controllers for username and password input fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isButtonEnabled = false; // Controls whether the signup button is active
  String? _errorMessage; // Displays error messages (e.g., duplicate username)

  /// Checks if both fields have input, enabling the Sign Up button
  void _checkInput() {
    setState(() {
      _isButtonEnabled =
          _usernameController.text.isNotEmpty && _passwordController.text.isNotEmpty;
    });
  }

  /// Handles signup logic:
  /// - Attempts to register using CredentialService
  /// - Redirects to LoginScreen if successful
  /// - Shows an error if username already exists
  Future<void> _signup() async {
    final success = await CredentialService.instance.register(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return; // Ensure widget is still in the tree before proceeding

    if (success) {
      // Navigate to LoginScreen after successful signup
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      // Show error if username is already taken
      setState(() => _errorMessage = 'Username already exists');
    }
  }

  @override
  void initState() {
    super.initState();
    // Attach listeners to input fields to enable/disable the button dynamically
    _usernameController.addListener(_checkInput);
    _passwordController.addListener(_checkInput);
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF3FC4FE); // Theme primary color (same as Login screen)

    return Scaffold(
      backgroundColor: primary, // Matches LoginScreen background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App logo
                  Image.asset('assets/logo.png', height: 80),
                  const SizedBox(height: 20),

                  // Screen title
                  Text(
                    'Sign Up',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primary,
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

                  // Password input field (hidden text)
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  // Show error message if signup fails
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  ],

                  const SizedBox(height: 20),

                  // Sign Up button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isButtonEnabled ? _signup : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        // Slightly faded button when disabled
                        disabledBackgroundColor: primary.withOpacity(0.5),
                      ),
                      child: const Text('Sign Up', style: TextStyle(fontSize: 16)),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Redirect to Login screen if user already has an account
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      'Already have an account? Login',
                      style: TextStyle(color: primary),
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
