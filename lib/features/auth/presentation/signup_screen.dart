import 'package:flutter/material.dart';
import 'package:bharatstock/l10n/app_localizations.dart';
import '../logic/auth_service.dart';
import 'widgets/auth_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  /// Returns null if valid, or a human-readable error message.
  String? _validateSignupInputs() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passController.text;
    final confirmPassword = _confirmPassController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      return 'Please fill in all fields to create your account.';
    }

    if (name.length < 2) {
      return 'Please enter your full name (at least 2 characters).';
    }

    // Email format check
    final emailRegex = RegExp(r'^[\w.+\-]+@[a-zA-Z\d\-]+\.[a-zA-Z\d\-.]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address (e.g. name@example.com).';
    }

    if (password.length < 7) {
      return 'Password must be at least 7 characters long.';
    }

    // Must have letter + digit + special character
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    final hasSpecial = RegExp(r'[@\$!%*#?&]').hasMatch(password);

    if (!hasLetter || !hasDigit || !hasSpecial) {
      return 'Password must contain a letter, a number, and a special character (e.g. @, !, #).';
    }

    if (password != confirmPassword) {
      return 'Passwords do not match. Please check and try again.';
    }

    return null; // All good
  }

  void _handleSignup() async {
    final validationError = _validateSignupInputs();
    if (validationError != null) {
      showTopToast(context, validationError, isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
        fullName: _nameController.text.trim(),
      );
      if (mounted) {
        showTopToast(context, 'Account created! Welcome to BharatStock.');
        // Let the root (AuthWrapper/InitialRouter) handle the next destination
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        final errMsg = e.toString().replaceAll('Exception: ', '');
        showTopToast(context, errMsg, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    const baseColor = Color(0xFFF2F4F8);

    return Scaffold(
      backgroundColor: baseColor,
      appBar: AppBar(
        backgroundColor: baseColor,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          child: Column(
            children: [
              ClayContainer(
                color: baseColor,
                borderRadius: 20,
                depth: 12,
                height: 72,
                width: 72,
                child: const Icon(
                  Icons.person_add_rounded,
                  color: Color(0xFFFFCA28),
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l.signupTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l.signupSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 28),

              ClayContainer(
                color: baseColor,
                borderRadius: 30,
                depth: 20,
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClayTextField(
                        controller: _nameController,
                        hint: l.fullNameHint,
                        icon: Icons.person_outline,
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 15),
                      ClayTextField(
                        controller: _emailController,
                        hint: l.emailHint,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 15),
                      ClayTextField(
                        controller: _passController,
                        hint: l.passwordHint,
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),
                      const SizedBox(height: 15),
                      ClayTextField(
                        controller: _confirmPassController,
                        hint: l.confirmPasswordHint,
                        icon: Icons.lock_reset_rounded,
                        isPassword: true,
                      ),
                      const SizedBox(height: 28),

                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFFCA28),
                              ),
                            )
                          : ClayPrimaryButton(
                              text: l.signupButton,
                              onTap: _handleSignup,
                            ),

                      const SizedBox(height: 18),

                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                              children: [
                                TextSpan(text: l.alreadyAccount),
                                TextSpan(
                                  text: l.loginLinkText,
                                  style: const TextStyle(
                                    color: Color(0xFF5D3FD3),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
