import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_deck/core/constants/app_constants.dart';
import 'package:study_deck/main.dart';
import 'package:study_deck/models/semester_model.dart';
import 'package:study_deck/screens/admin/admin_login_screen.dart';
import 'package:study_deck/services/academic_service.dart';
import 'package:study_deck/services/auth_service.dart';

class MockAcademicService extends AcademicService {
  @override
  Stream<List<SemesterModel>> watchPublishedSemesters() {
    return Stream.value(<SemesterModel>[]);
  }
}

class MockAuthService extends AuthService {}

void main() {
  testWidgets('Public student access renders without requiring login', (
    WidgetTester tester,
  ) async {
    // Build StudyDeck application with isolated mock service and trigger frame.
    await tester.pumpWidget(
      StudyDeckApp(
        academicService: MockAcademicService(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify application name and tagline are visible
    expect(find.text(AppConstants.appName), findsWidgets);
    expect(find.text(AppConstants.appTagline), findsWidgets);

    // Verify public open access indicators
    expect(
      find.text('Public Academic Hub • Open Access'),
      findsOneWidget,
    );
    expect(
      find.text('Open Student Access — No Login Required'),
      findsOneWidget,
    );

    // Verify clean empty state is displayed when database has no content yet
    expect(
      find.text('Academic Content Preparing'),
      findsOneWidget,
    );
  });

  testWidgets('Admin login screen renders properly with email and password fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdminLoginScreen(
          authService: MockAuthService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify admin login elements
    expect(find.text('Administrator Sign In'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Sign In as Administrator'), findsOneWidget);

    // Verify student reassurance banner exists
    expect(
      find.textContaining('Are you a student? You do not need to sign in'),
      findsOneWidget,
    );
  });
}
