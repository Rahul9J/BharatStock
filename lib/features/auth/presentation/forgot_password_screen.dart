import 'package:flutter/material.dart';
import 'package:bharatstock/l10n/app_localizations.dart';
import '../logic/auth_service.dart';
import 'widgets/auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleReset() async {
    final l = AppLocalizations.of(context)!;
    if (_emailController.text.trim().isEmpty) {
      showTopToast(context, l.fillAllFields, isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authService.resetPassword(_emailController.text.trim());
      if (mounted) {
        showTopToast(context, l.resetLinkSent);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showTopToast(context, e.toString(), isError: true);
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
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              ClayContainer(
                color: baseColor,
                borderRadius: 20,
                depth: 12,
                height: 72,
                width: 72,
                child: const Icon(
                  Icons.lock_reset_rounded,
                  color: Color(0xFFFFCA28),
                  size: 34,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l.forgotPasswordTitle,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.forgotPasswordSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 36),

              ClayContainer(
                color: baseColor,
                borderRadius: 30,
                depth: 20,
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    children: [
                      ClayTextField(
                        controller: _emailController,
                        hint: l.emailHint,
                        icon: Icons.alternate_email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 30),
                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFFCA28),
                              ),
                            )
                          : ClayPrimaryButton(
                              text: l.sendLinkButton,
                              onTap: _handleReset,
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
