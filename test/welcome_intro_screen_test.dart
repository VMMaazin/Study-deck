import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_deck/core/constants/app_constants.dart';
import 'package:study_deck/models/semester_model.dart';
import 'package:study_deck/screens/student/student_home_screen.dart';
import 'package:study_deck/screens/welcome/welcome_intro_screen.dart';
import 'package:study_deck/services/academic_service.dart';

class MockWelcomeAcademicService extends AcademicService {
  @override
  Stream<List<SemesterModel>> watchPublishedSemesters() {
    return Stream.value(<SemesterModel>[]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WelcomeIntroScreen Widget & Animation Tests', () {
    testWidgets('Renders mascot stage, title, and subtitle during intro', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeIntroScreen(
            academicService: MockWelcomeAcademicService(),
            duration: const Duration(milliseconds: 1000),
          ),
        ),
      );

      // Verify immediate initial render of Skip button
      expect(find.text('Skip'), findsOneWidget);

      // Advance frames through reveal phase (e.g. 500ms)
      await tester.pump(const Duration(milliseconds: 600));

      // Verify presence of title and subtitle
      expect(find.textContaining('Welcome to StudyDeck'), findsOneWidget);
      expect(find.text('All the best for your studies!'), findsOneWidget);

      // Settle remaining animation
      await tester.pumpAndSettle();
    });

    testWidgets('Tapping Skip navigates immediately to StudentHomeScreen', (
      WidgetTester tester,
    ) async {
      bool onFinishedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeIntroScreen(
            academicService: MockWelcomeAcademicService(),
            onFinished: () {
              onFinishedCalled = true;
            },
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Tap Skip button
      final skipFinder = find.text('Skip');
      expect(skipFinder, findsOneWidget);
      await tester.tap(skipFinder);
      await tester.pump();

      expect(onFinishedCalled, isTrue);
    });

    testWidgets('Tapping background screen triggers immediate transition', (
      WidgetTester tester,
    ) async {
      bool onFinishedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeIntroScreen(
            academicService: MockWelcomeAcademicService(),
            onFinished: () {
              onFinishedCalled = true;
            },
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Tap anywhere on screen
      await tester.tap(find.byType(WelcomeIntroScreen));
      await tester.pump();

      expect(onFinishedCalled, isTrue);
    });

    testWidgets('Automatically replaces route with StudentHomeScreen on completion', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeIntroScreen(
            academicService: MockWelcomeAcademicService(),
            duration: const Duration(milliseconds: 500),
          ),
        ),
      );

      // Settle entire animation and navigation transition
      await tester.pumpAndSettle();

      // Verify StudentHomeScreen is now active
      expect(find.byType(StudentHomeScreen), findsOneWidget);
      expect(find.text(AppConstants.appName), findsWidgets);
    });

    testWidgets('Respects reduced motion preference by completing immediately', (
      WidgetTester tester,
    ) async {
      bool onFinishedCalled = false;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: WelcomeIntroScreen(
              academicService: MockWelcomeAcademicService(),
              onFinished: () {
                onFinishedCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.pump();

      expect(onFinishedCalled, isTrue);
    });
  });
}
