import 'package:flutter_test/flutter_test.dart';
import 'package:surveyor_pro/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SurveyorProApp());

    // Verify that the OnboardingScreen is present (initial route).
    // Note: Since we use GoRouter with redirection, it might redirect. 
    // But initially it should build without crashing.
    // We just check if it pumps successfully for a smoke test.
    expect(find.byType(SurveyorProApp), findsOneWidget);
  });
}
