import 'dart:async'; // Used for Timer functionality
import 'package:flutter/material.dart';

/// SplashScreen widget - shown first when the app launches.
/// It displays the app logo and name with a fade-in animation,
/// then navigates automatically to the login screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller; // Controls the animation lifecycle
  late Animation<double> _fadeAnimation; // Defines the fade effect (0.0 - 1.0)

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _controller = AnimationController(
      vsync: this, // Prevents unnecessary resource usage when off-screen
      duration: const Duration(milliseconds: 1500), // Fade-in duration
    );

    // Create a fade animation from 0 (invisible) to 1 (fully visible)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    // Start the fade-in animation immediately
    _controller.forward();

    // After 3 seconds, navigate to the Login screen
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  void dispose() {
    // Always dispose controllers to free resources and prevent memory leaks
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF43C5FC), // App theme color
      body: Center(
        // Apply fade transition to the child widget
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo
              Image.asset(
                'assets/logo.png',
                height: 100,
              ),
              const SizedBox(height: 20), // Spacing between logo and text
              // App title text
              const Text(
                'PlagiariShield',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
