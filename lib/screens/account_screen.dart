import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plagiarishield_sim/storage/credential_storage.dart';
import 'package:plagiarishield_sim/widgets/bottom_nav_bar.dart';

/// AccountScreen widget - allows the active user to:
/// - View and update their username/password
/// - Save changes if inputs are valid
/// - Log out of the current session
///
/// This screen is part of the BottomNavBar navigation (index = 2).
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // Text controllers for username and password fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isButtonEnabled = false; // Enables save button only if inputs are valid
  String? _errorMessage; // Stores error message (e.g., duplicate username)
  String? _successMessage; // Stores success message (e.g., changes saved)
  bool _showSuccessAnimation = false;
  bool _isLoggingOut = false;



  @override
  void initState() {
    super.initState();
    _loadUser(); // Load the current logged-in user credentials

    // Re-validate inputs whenever the user types
    _usernameController.addListener(_checkInput);
    _passwordController.addListener(_checkInput);
  }

  /// Loads the currently active user's credentials
  /// from [CredentialService] and fills the input fields.
  Future<void> _loadUser() async {
    final userId = await CredentialService.instance.getActiveUserId();
    if (userId == null) return;

    final username = await CredentialService.instance.getUsernameById(userId);
    final password =
        await CredentialService.instance.getPasswordForUser(username ?? '');

    setState(() {
      _usernameController.text = username ?? '';
      _passwordController.text = password ?? '';
    });
  }

  /// Checks if both input fields have values.
  /// Also clears success/error messages when typing.
  void _checkInput() {
    setState(() {
      _isButtonEnabled =
          _usernameController.text.isNotEmpty && _passwordController.text.isNotEmpty;
      _successMessage = null;
      _errorMessage = null;
    });
  }

  /// Saves the updated username and password.
  /// - Calls [CredentialService.updateCredentials]
  /// - Shows success if update is valid
  /// - Shows error if username is already taken
  Future<void> _saveChanges() async {
    final userId = await CredentialService.instance.getActiveUserId();
    if (userId == null) return;

    final newUsername = _usernameController.text.trim();
    final newPassword = _passwordController.text.trim();

    final success = await CredentialService.instance.updateCredentials(
      userId: userId,
      newUsername: newUsername,
      newPassword: newPassword,
    );

    setState(() {
      if (success) {
        _successMessage = 'Changes saved successfully';
        _errorMessage = null;
      } else {
        _errorMessage = 'Username already exists';
        _successMessage = null;
      }
    });
  }

  /// Logs out the current user.
  /// Shows a confirmation dialog before logging out.
  /// If confirmed, redirects to LoginScreen.
Future<void> _logout() async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // force user to pick an option
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        backgroundColor: Colors.white,
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔹 Logout Icon Header
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5F6D), Color(0xFFFF7F50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: const Icon(Icons.logout_rounded, color: Colors.white, size: 38),
              ),
              const SizedBox(height: 20),

              // 🔹 Title
              Text(
                'Confirm Logout',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 10),

              // 🔹 Content
              Text(
                'Are you sure you want to log out of your account?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 24),

              // 🔹 Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Colors.grey[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFB0BEC5)),
                        ),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Logout
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color(0xFFFF5F6D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  if (shouldLogout == true) {
    Navigator.pushReplacementNamed(context, '/login');
  }
}



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF43C5FC),
        centerTitle: true,
        title: Text(
          'Account',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Navigation bar (Account tab is active)
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),

      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_circle_rounded,
                    size: 110, color: Colors.grey.shade400),
                const SizedBox(height: 20),

                Text(
                  'Account Settings',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: const TextStyle(color: Color(0xFF43C5FC)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF43C5FC), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Color(0xFF43C5FC)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF43C5FC), width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                if (_successMessage != null)
                  Text(
                    _successMessage!,
                    style: const TextStyle(color: Colors.green, fontSize: 14),
                  ),

                const SizedBox(height: 24),

                // Save Changes button (with success animation)
GestureDetector(
  onTap: _isButtonEnabled
      ? () async {
          setState(() {
            _isButtonEnabled = false; // prevent double taps
          });

          await _saveChanges();

          if (_successMessage != null) {
            // briefly show success animation
            setState(() => _showSuccessAnimation = true);
            await Future.delayed(const Duration(seconds: 1));
            setState(() => _showSuccessAnimation = false);
          }

          _checkInput(); // re-enable button if still valid
        }
      : null,
  child: AnimatedContainer(
    duration: const Duration(milliseconds: 400),
    curve: Curves.easeInOut,
    width: double.infinity,
    height: 50,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: _showSuccessAnimation
            ? [Colors.greenAccent.shade400, Colors.green]
            : const [Color(0xFF43C5FC), Color(0xFF1E88E5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: _showSuccessAnimation
              ? Colors.green.withOpacity(0.4)
              : Colors.blue.withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _showSuccessAnimation
            ? const Icon(Icons.check_circle,
                color: Colors.white, size: 26, key: ValueKey('check'))
            : const Text(
                'Save Changes',
                key: ValueKey('text'),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    ),
  ),
),


                const SizedBox(height: 16),

                // Logout button (with fade-out red glow)
GestureDetector(
  onTap: () async {
    setState(() => _isLoggingOut = true);

    // Short animation delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Then show the confirmation dialog
    await _logout();

    // Reset animation state in case user cancels logout
    setState(() => _isLoggingOut = false);
  },
  child: AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    width: double.infinity,
    height: 50,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: _isLoggingOut
            ? [Colors.redAccent.shade700, Colors.redAccent.shade400]
            : const [Color(0xFFFF5F6D), Color(0xFFFF7F50)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: _isLoggingOut
              ? Colors.redAccent.withOpacity(0.5)
              : Colors.redAccent.withOpacity(0.3),
          blurRadius: _isLoggingOut ? 12 : 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _isLoggingOut
            ? const Icon(Icons.logout_rounded,
                color: Colors.white, size: 26, key: ValueKey('logout'))
            : const Text(
                'Logout',
                key: ValueKey('text'),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    ),
  ),
),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
