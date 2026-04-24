import 'package:flutter/material.dart';
import 'package:clay_containers/clay_containers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bharatstock/l10n/app_localizations.dart';
import '../../core/providers/language_provider.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("Building LanguageScreen...");
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClayContainer(
                height: 80,
                width: 80,
                depth: 20,
                borderRadius: 40,
                color: const Color(0xFFF6F7FB),
                child: const Icon(
                  Icons.language,
                  size: 40,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                l?.chooseLanguage ?? "Choose Language",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D3A),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "भाषा चुनें • ભાષા પસંદ કરો",
                style: TextStyle(fontSize: 14, color: Color(0xFF8A8A99)),
              ),
              const SizedBox(height: 50),
              _buildLanguageButton(context, "English", "Aa", 'en'),
              const SizedBox(height: 20),
              _buildLanguageButton(context, "हिंदी", "अ", 'hi'),
              const SizedBox(height: 20),
              _buildLanguageButton(context, "ગુજરાતી", "ગ", 'gu'),
              const SizedBox(height: 60),
              const Text(
                "SAFE • SECURE • MADE FOR INDIA",
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton(
    BuildContext context,
    String name,
    String symbol,
    String code,
  ) {
    return GestureDetector(
      onTap: () async {
        await LanguageProvider.instance.changeLanguage(code);
        if (FirebaseAuth.instance.currentUser != null) {
          if (context.mounted) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context); // Go back to Home/Drawer
            }
          }
        } else {
          if (context.mounted) {
            // In Phase 1 onboarding is not built, but we prepare the route
            try {
              Navigator.pushReplacementNamed(context, '/onboarding');
            } catch (e) {
              // Ignore route not found during Phase 1 testing
              debugPrint('Route /onboarding not found yet');
            }
          }
        }
      },
      child: ClayContainer(
        height: 70,
        width: double.infinity,
        borderRadius: 20,
        depth: 15,
        spread: 2,
        color: const Color(0xFFF6F7FB),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    symbol,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D3A),
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
