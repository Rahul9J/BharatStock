import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:bharatstock/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('7.2 Integration Testing & 7.3 System Testing', () {
    testWidgets('App Boots up and shows initial screen (Login/Splash)', (tester) async {
      // Build our app and trigger a frame.
      app.main();
      
      // Wait for the app to finish settling (animations, etc.)
      await tester.pumpAndSettle();

      // Expect to find either a CircularProgressIndicator (loading splash), 
      // or some primary text from Login/Home depending on your routing state.
      // This is a basic sanity check that the app runs end-to-end without crashing.
      expect(find.byType(app.BharatStockApp), findsOneWidget);
      
      // We can also verify that a specific Login button or Dashboard text exists.
      // e.g. expect(find.text('Login'), findsWidgets);
    });
  });
}
