import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:study_deck/core/constants/app_constants.dart';
import 'package:study_deck/core/session/admin_session.dart';
import 'package:study_deck/core/theme/app_theme.dart';
import 'package:study_deck/core/theme/theme_controller.dart';
import 'package:study_deck/firebase_options.dart';
import 'package:study_deck/screens/student/student_home_screen.dart';
import 'package:study_deck/screens/welcome/welcome_intro_screen.dart';
import 'package:study_deck/services/academic_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    developer.log(
      'Failed to initialize Firebase',
      error: error,
      stackTrace: stackTrace,
    );
  }

  // Initialize theme mode persistence before app launch
  await ThemeController.instance.init();

  runApp(const StudyDeckApp());
}

/// The root widget of the StudyDeck application.
class StudyDeckApp extends StatelessWidget {
  const StudyDeckApp({
    super.key,
    this.academicService,
    this.adminSession,
    this.themeController,
    this.showWelcomeIntro = true,
  });

  final AcademicService? academicService;
  final AdminSession? adminSession;
  final ThemeController? themeController;
  final bool showWelcomeIntro;

  @override
  Widget build(BuildContext context) {
    final session = adminSession ?? AdminSession.instance;
    final themeCtrl = themeController ?? ThemeController.instance;

    return AdminSessionScope(
      session: session,
      child: ThemeScope(
        controller: themeCtrl,
        child: ListenableBuilder(
          listenable: themeCtrl,
          builder: (context, _) {
            return MaterialApp(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeCtrl.themeMode,
              home: showWelcomeIntro
                  ? WelcomeIntroScreen(academicService: academicService)
                  : StudentHomeScreen(academicService: academicService),
            );
          },
        ),
      ),
    );
  }
}
