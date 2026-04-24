import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:bharatstock/l10n/app_localizations.dart';

import 'package:bharatstock/core/theme/font_size_provider.dart';
import 'package:bharatstock/core/providers/language_provider.dart';
import 'package:bharatstock/features/language/language_screen.dart';
import 'package:bharatstock/features/onboarding/presentation/onboarding_screen.dart';
import 'package:bharatstock/features/auth/presentation/login_screen.dart';
import 'package:bharatstock/features/auth/presentation/signup_screen.dart';
import 'package:bharatstock/features/auth/presentation/forgot_password_screen.dart';
import 'package:bharatstock/features/home/presentation/home_screen.dart';
import 'package:bharatstock/features/auth/presentation/complete_profile_screen.dart';
import 'package:bharatstock/features/staff/presentation/staff_list_screen.dart';
import 'package:bharatstock/features/analytics/presentation/profit_loss_screen.dart';
import 'package:bharatstock/features/analytics/presentation/expenses_screen.dart';
import 'package:bharatstock/features/analytics/presentation/tax_ledger_screen.dart';
import 'package:bharatstock/features/analytics/presentation/sales_screen.dart';
import 'package:bharatstock/features/inventory/presentation/stock_screen.dart';
import 'package:bharatstock/features/accounting/presentation/party_list_screen.dart';
import 'package:bharatstock/features/interactions/presentation/interaction_hub_screen.dart';
import 'package:bharatstock/core/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  debugPrint("APP_START: Starting initialization...");
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("APP_START: Firebase initializing...");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("APP_START: Font size loading...");
  await FontSizeProvider.instance.load();
  debugPrint("APP_START: Language loading...");
  await LanguageProvider.instance.load();
  debugPrint("APP_START: Running App...");
  runApp(const BharatStockApp());
}

class BharatStockApp extends StatelessWidget {
  const BharatStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FontSizeProvider.instance,
      builder: (context, _) {
        final scale = FontSizeProvider.instance.scaleFactor;
        return ListenableBuilder(
          listenable: LanguageProvider.instance,
          builder: (context, child) {
            return MaterialApp(
              title: 'BharatStock',
              debugShowCheckedModeBanner: false,

              // Localization Setup
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'),
                Locale('hi'),
                Locale('gu'),
              ],
              locale: LanguageProvider.instance.currentLocale,

              theme: ThemeData(
                useMaterial3: true,
                scaffoldBackgroundColor: const Color(0xFFF2F4F8),
                primarySwatch: Colors.orange,
                pageTransitionsTheme: const PageTransitionsTheme(
                  builders: {
                    TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                  },
                ),
              ),
              builder: (context, child) {
                final mediaQueryData = MediaQuery.of(context);
                return MediaQuery(
                  data: mediaQueryData.copyWith(
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: child!,
                );
              },

              home: const AuthWrapper(),
              routes: {
                '/language': (context) => const LanguageScreen(),
                '/onboarding': (context) => const OnboardingScreen(),
                '/login': (context) => const LoginScreen(),
                '/signup': (context) => const SignupScreen(),
                '/forgot-password': (context) => const ForgotPasswordScreen(),
                '/home': (context) => const HomeScreen(),
                '/complete-profile': (context) => const CompleteProfileScreen(),
                '/staff': (context) => const StaffListScreen(),
                '/profit-loss': (context) => const ProfitLossScreen(),
                '/expenses': (context) => const ExpensesScreen(),
                '/tax-ledger': (context) => const TaxLedgerScreen(),
                '/sales': (context) => const SalesScreen(),
                '/stock': (context) => const StockScreen(),
                '/parties': (context) => const PartyListScreen(),
                '/business-hub': (context) => const InteractionHubScreen(),
              },
            );
          },
        );
      },
    );
  }
}

// ===========================================================
// THE BRAIN OF NAVIGATION — Professional app flow
// ===========================================================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        debugPrint("Auth State: ${authSnap.connectionState}, User: ${authSnap.data?.uid}");
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final user = authSnap.data;
        if (user != null) {
          return const InitialRouter();
        }
        return const LanguageScreen();
      },
    );
  }
}

/// A "Silent" router that checks the user's profile in Firestore
/// and sends them to the correct screen (Business Setup or Dashboard).
class InitialRouter extends StatelessWidget {
  const InitialRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const LanguageScreen();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        debugPrint("InitialRouter State: ${snapshot.connectionState}, HasData: ${snapshot.hasData}, Error: ${snapshot.error}");
        
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text("Error checking profile: ${snapshot.error}"),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          // If no profile found, user might have been deleted from DB
          FirebaseAuth.instance.signOut();
          return const LanguageScreen();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final businessId = userData?['businessId'];

        if (businessId != null) {
          FirestoreService().setBusinessId(businessId);
        }

        return const HomeScreen();
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF2F4F8),
      body: Center(child: CircularProgressIndicator(color: Color(0xFFFFCA28))),
    );
  }
}
