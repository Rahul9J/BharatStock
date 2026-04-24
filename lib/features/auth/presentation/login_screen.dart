import 'package:flutter/material.dart';
import 'package:bharatstock/l10n/app_localizations.dart';
import '../logic/auth_service.dart';
import 'widgets/auth_widgets.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  /// Returns null if valid, or a human-readable error message.
  String? _validateInputs() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      return 'Please fill in both email and password.';
    }

    // Basic email format check
    final emailRegex = RegExp(r'^[\w.+\-]+@[a-zA-Z\d\-]+\.[a-zA-Z\d\-.]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address (e.g. name@example.com).';
    }

    if (password.length < 6) {
      return 'Password must be at least 6 characters long.';
    }

    return null; // All good
  }

  void _handleLogin() async {
    final l = AppLocalizations.of(context)!;

    final validationError = _validateInputs();
    if (validationError != null) {
      showTopToast(context, validationError, isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        showTopToast(context, l.welcomeBackToast);
        // Pushing to root '/' forces AuthWrapper to re-evaluate
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      if (mounted) {
        // Show the actual Firebase error message for clarity
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              // Logo
              ClayContainer(
                color: baseColor,
                borderRadius: 24,
                depth: 12,
                height: 90,
                width: 90,
                child: const Icon(
                  Icons.storefront_rounded,
                  size: 44,
                  color: Color(0xFFFFCA28),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l.loginTitle,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l.loginSubtitle,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 36),

              // Login Card
              ClayContainer(
                color: baseColor,
                borderRadius: 30,
                depth: 20,
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.emailLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClayTextField(
                        controller: _emailController,
                        hint: l.emailHint,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 20),

                      Text(
                        l.passwordLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClayTextField(
                        controller: _passwordController,
                        hint: l.passwordHint,
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),

                      const SizedBox(height: 18),

                      // Forgot Password only
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          ),
                          child: Text(
                            l.forgotPassword,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFFCA28),
                              ),
                            )
                          : ClayPrimaryButton(
                              text: l.loginButton,
                              onTap: _handleLogin,
                            ),

                      const SizedBox(height: 20),

                      // Sign Up Link
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignupScreen(),
                            ),
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(text: l.newUserText),
                                TextSpan(
                                  text: l.signUpLinkText,
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
