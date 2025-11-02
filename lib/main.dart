import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';

void main() async { // <-- GINAWANG ASYNC
  // Tinitiyak na ang Flutter ay handa na bago mag-run ng app
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // Entry point of the app
  runApp(const PlagiariShieldApp());
}

// Root widget of the application
class PlagiariShieldApp extends StatelessWidget {
  const PlagiariShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Removes the debug banner
      title: 'PlagiariShield 2.0',
      
      // First screen shown when app starts
      initialRoute: '/',
      
      // Define app routes for navigation
      routes: {
        '/': (context) => const SplashScreen(), // Splash screen
        '/login': (context) => const LoginScreen(), // Login screen
        '/signup': (context) => const SignupScreen(), // Signup screen
        '/home': (context) => const HomeScreen(), // Home screen
      },
    );
  }
}
