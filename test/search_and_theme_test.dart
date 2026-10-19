import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_deck/core/session/admin_session.dart';
import 'package:study_deck/core/theme/theme_controller.dart';
import 'package:study_deck/models/academic_resource_model.dart';
import 'package:study_deck/models/admin_user_model.dart';
import 'package:study_deck/models/module_model.dart';
import 'package:study_deck/models/semester_model.dart';
import 'package:study_deck/models/subject_model.dart';
import 'package:study_deck/screens/deck/module_list_screen.dart';
import 'package:study_deck/screens/deck/module_resources_screen.dart';
import 'package:study_deck/screens/student/student_home_screen.dart';
import 'package:study_deck/services/academic_search_service.dart';
import 'package:study_deck/services/academic_service.dart';
import 'package:study_deck/services/auth_service.dart';
import 'package:study_deck/widgets/study_deck_app_bar.dart';

class MockAuthService extends AuthService {}

class MockTestAcademicService extends AcademicService {
  @override
  Stream<List<SemesterModel>> watchPublishedSemesters() {
    return Stream.value(<SemesterModel>[]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeController & Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ThemeController.instance.resetForTesting();
    });

    test('ThemeController defaults to ThemeMode.light', () async {
      final controller = ThemeController.instance;
      await controller.init();
      expect(controller.themeMode, ThemeMode.light);
      expect(controller.isDark, isFalse);
    });

    test('ThemeController toggles between light and dark modes and persists preference', () async {
      final controller = ThemeController.instance;
      await controller.init();
      expect(controller.themeMode, ThemeMode.light);

      // Toggle to dark
      await controller.toggleTheme();
      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.isDark, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('studydeck_theme_mode'), 'dark');

      // Toggle back to light
      await controller.toggleTheme();
      expect(controller.themeMode, ThemeMode.light);
      expect(controller.isDark, isFalse);
      expect(prefs.getString('studydeck_theme_mode'), 'light');
    });

    test('ThemeController loads persisted preference on restart', () async {
      SharedPreferences.setMockInitialValues({'studydeck_theme_mode': 'dark'});
      final controller = ThemeController.instance;
      await controller.init();
      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.isDark, isTrue);
    });

    testWidgets('StudyDeckAppBar contains working theme toggle button', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final controller = ThemeController.instance;
      await controller.init();

      await tester.pumpWidget(
        AdminSessionScope(
          session: AdminSession.instance,
          child: ThemeScope(
            controller: controller,
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => MaterialApp(
                themeMode: controller.themeMode,
                theme: ThemeData.light(),
                darkTheme: ThemeData.dark(),
                home: const Scaffold(
                  appBar: StudyDeckAppBar(),
                ),
              ),
            ),
          ),
        ),
      );

      // Initially in light mode, toggle button tooltip should offer switching to Dark theme
      expect(find.byTooltip('Switch to Dark Theme'), findsOneWidget);

      // Tap toggle button
      await tester.tap(find.byTooltip('Switch to Dark Theme'));
      await tester.pumpAndSettle();

      // Now should be in dark mode, tooltip should offer switching to Light theme
      expect(controller.themeMode, ThemeMode.dark);
      expect(find.byTooltip('Switch to Light Theme'), findsOneWidget);
    });

    testWidgets('StudyDeckAppBar renders without overflow or clipping at narrow 360px viewport', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = ThemeController.instance;
      await controller.init();

      await tester.pumpWidget(
        AdminSessionScope(
          session: AdminSession.instance,
          child: ThemeScope(
            controller: controller,
            child: MaterialApp(
              home: const Scaffold(
                appBar: StudyDeckAppBar(
                  title: 'Long Semester Title That Could Overflow',
                  subtitle: 'Curriculum notes and modules',
                  showBackButton: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure no layout overflow exceptions were thrown
      expect(tester.takeException(), isNull);

      // Verify title is rendered
      expect(find.text('Long Semester Title That Could Overflow'), findsOneWidget);
      expect(find.text('Curriculum notes and modules'), findsOneWidget);

      // Verify actions are present
      expect(find.byTooltip('Admin Login'), findsOneWidget);
      expect(find.byTooltip('Offline Downloads'), findsOneWidget);
      expect(find.byTooltip('Switch to Dark Theme'), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);
    });

    testWidgets('StudyDeckAppBar in admin mode renders cleanly without overflow at 360px viewport', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = ThemeController.instance;
      await controller.init();

      final adminUser = AdminUserModel(
        uid: 'adm1',
        email: 'admin@studydeck.edu',
        role: 'admin',
        isActive: true,
      );
      AdminSession.instance.setAdmin(adminUser);
      addTearDown(() {
        AdminSession.instance.setAdmin(null);
      });

      await tester.pumpWidget(
        AdminSessionScope(
          session: AdminSession.instance,
          child: ThemeScope(
            controller: controller,
            child: MaterialApp(
              home: const Scaffold(
                appBar: StudyDeckAppBar(
                  title: 'Module 3: Advanced Graph Algorithms and Trees',
                  subtitle: 'Data Structures • Semester 5',
                  showBackButton: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure no layout overflow
      expect(tester.takeException(), isNull);

      // Verify admin badge and sign out action
      expect(find.text('Admin'), findsOneWidget);
      expect(find.byTooltip('Sign Out Admin'), findsOneWidget);
      expect(find.byTooltip('Offline Downloads'), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);
    });
  });

  group('AcademicSearchService Unit Tests', () {
    late AcademicSearchService searchService;

    // Test datasets
    final testSemesters = [
      SemesterModel(id: 'sem-1', semesterNumber: 1, title: 'Semester 1', isPublished: true),
      SemesterModel(id: 'sem-5', semesterNumber: 5, title: 'Semester 5', isPublished: true),
    ];

    final testSubjects = [
      SubjectModel(
        id: 'sub-dsa',
        semesterId: 'sem-5',
        name: 'Data Structures and Algorithms',
        code: 'CS201',
        description: 'Core computer science subject covering trees and graphs',
        isPublished: true,
      ),
      SubjectModel(
        id: 'sub-legacy',
        semesterId: '1', // Legacy numeric semester ID
        name: 'Engineering Mathematics',
        code: 'MAT101',
        description: 'Calculus and Linear Algebra',
        isPublished: true,
      ),
    ];

    final testModules = [
      ModuleModel(
        id: 'mod-trees',
        subjectId: 'sub-dsa',
        moduleNumber: 2,
        title: 'Binary Search Trees & AVL Trees',
        description: 'Self-balancing trees and search complexity',
        isPublished: true,
      ),
      ModuleModel(
        id: 'mod-calc',
        subjectId: 'sub-legacy',
        moduleNumber: 1,
        title: 'Differential Calculus',
        description: 'Limits and derivatives',
        isPublished: true,
      ),
    ];

    final testResources = [
      AcademicResourceModel(
        id: 'res-notes-1',
        title: 'Complete DSA Module 2 Handwritten Notes',
        fileName: 'dsa_module2_notes_handwritten.pdf',
        fileUrl: 'https://res.cloudinary.com/demo/image/upload/dsa_m2.pdf',
        fileSize: 204800,
        type: ResourceType.notes,
        semesterId: 'sem-5',
        subjectId: 'sub-dsa',
        moduleId: 'mod-trees',
        isPublished: true,
      ),
      AcademicResourceModel(
        id: 'res-pyq-1',
        title: '2023 End Semester Question Bank and PYQ',
        fileName: 'cs201_pyq_2023.pdf',
        fileUrl: 'https://res.cloudinary.com/demo/image/upload/cs201_pyq.pdf',
        fileSize: 409600,
        type: ResourceType.pyq,
        semesterId: 'sem-5',
        subjectId: 'sub-dsa',
        moduleId: null,
        isPublished: true,
      ),
      AcademicResourceModel(
        id: 'res-syllabus-1',
        title: 'Official Department Syllabus CS201',
        fileName: 'cs201_syllabus_official.pdf',
        fileUrl: 'https://res.cloudinary.com/demo/image/upload/cs201_syl.pdf',
        fileSize: 102400,
        type: ResourceType.syllabus,
        semesterId: 'sem-5',
        subjectId: 'sub-dsa',
        moduleId: null,
        isPublished: true,
      ),
      AcademicResourceModel(
        id: 'res-assign-1',
        title: 'Calculus Assignment 1 Problems',
        fileName: 'mat101_assignment1.pdf',
        fileUrl: 'https://res.cloudinary.com/demo/image/upload/mat101_a1.pdf',
        fileSize: 153600,
        type: ResourceType.assignment,
        semesterId: '1',
        subjectId: 'sub-legacy',
        moduleId: 'mod-calc',
        isPublished: true,
      ),
    ];

    setUp(() {
      searchService = AcademicSearchService();
      searchService.setMockData(
        semesters: testSemesters,
        subjects: testSubjects,
        modules: testModules,
        resources: testResources,
      );
    });

    test('Empty or blank query returns empty results', () async {
      expect(await searchService.search(''), isEmpty);
      expect(await searchService.search('   '), isEmpty);
    });

    test('Searches semesters by number and partial string', () async {
      final resSem5 = await searchService.search('Sem 5');
      expect(resSem5.any((r) => r.resultType == SearchResultType.semester && r.title == 'Semester 5'), isTrue);

      final resSem1 = await searchService.search('Semester 1');
      expect(resSem1.any((r) => r.resultType == SearchResultType.semester && r.title == 'Semester 1'), isTrue);
    });

    test('Searches subjects by name, code, and description case-insensitively', () async {
      // By Code
      final byCode = await searchService.search('cs201');
      expect(byCode.any((r) => r.resultType == SearchResultType.subject && r.code == 'CS201'), isTrue);

      // By Name
      final byName = await searchService.search('data structures');
      expect(byName.any((r) => r.resultType == SearchResultType.subject && r.id == 'sub-dsa'), isTrue);

      // Preserves context trail
      final dsaResult = byName.firstWhere((r) => r.id == 'sub-dsa');
      expect(dsaResult.contextTrail, 'Semester 5');
    });

    test('Resolves legacy numeric semester IDs for subjects gracefully', () async {
      final res = await searchService.search('Engineering Mathematics');
      expect(res.isNotEmpty, isTrue);
      final mathResult = res.firstWhere((r) => r.id == 'sub-legacy');
      expect(mathResult.semester?.title, 'Semester 1');
      expect(mathResult.contextTrail, 'Semester 1');
    });

    test('Searches modules by title, module number, and query variants', () async {
      // "Module 2"
      final mod2 = await searchService.search('Module 2');
      expect(mod2.any((r) => r.resultType == SearchResultType.module && r.id == 'mod-trees'), isTrue);

      // "mod 2"
      final mod2Short = await searchService.search('mod 2');
      expect(mod2Short.any((r) => r.resultType == SearchResultType.module && r.id == 'mod-trees'), isTrue);

      // Module Title
      final byTitle = await searchService.search('AVL Trees');
      expect(byTitle.any((r) => r.resultType == SearchResultType.module && r.id == 'mod-trees'), isTrue);
      final treeItem = byTitle.firstWhere((r) => r.id == 'mod-trees');
      expect(treeItem.contextTrail, 'Semester 5 > Data Structures and Algorithms');
    });

    test('Searches resources by title and PDF filename', () async {
      // By Title
      final byTitle = await searchService.search('Handwritten Notes');
      expect(byTitle.any((r) => r.resultType == SearchResultType.resource && r.id == 'res-notes-1'), isTrue);

      // By Filename
      final byFileName = await searchService.search('cs201_pyq_2023.pdf');
      expect(byFileName.any((r) => r.resultType == SearchResultType.resource && r.id == 'res-pyq-1'), isTrue);
    });

    test('Searches resources by academic category keywords (PYQ, Notes, Syllabus, Assignment)', () async {
      // "pyq" or "question bank"
      final pyqResults = await searchService.search('pyq');
      expect(pyqResults.any((r) => r.id == 'res-pyq-1'), isTrue);

      final qbResults = await searchService.search('question bank');
      expect(qbResults.any((r) => r.id == 'res-pyq-1'), isTrue);

      // "notes"
      final notesResults = await searchService.search('notes');
      expect(notesResults.any((r) => r.id == 'res-notes-1'), isTrue);

      // "syllabus"
      final sylResults = await searchService.search('syllabus');
      expect(sylResults.any((r) => r.id == 'res-syllabus-1'), isTrue);

      // "assignment"
      final assignResults = await searchService.search('assignment');
      expect(assignResults.any((r) => r.id == 'res-assign-1'), isTrue);
    });

    test('Constructs accurate hierarchical context trails for resource results', () async {
      final res = await searchService.search('Differential Calculus');
      expect(res.isNotEmpty, isTrue);

      final dsaNoteRes = await searchService.search('dsa_module2_notes_handwritten.pdf');
      final noteItem = dsaNoteRes.firstWhere((r) => r.id == 'res-notes-1');
      expect(noteItem.contextTrail, 'Semester 5 > Data Structures and Algorithms > Module 2');
      expect(noteItem.resource?.fileUrl, 'https://res.cloudinary.com/demo/image/upload/dsa_m2.pdf');
    });

    test('Returns null for semester and avoids synthetic fallback when semester ID is unresolved (deleted or missing)', () async {
      searchService.setMockData(
        semesters: [
          SemesterModel(id: 'sem-1', semesterNumber: 1, title: 'Semester 1', isPublished: true),
        ],
        subjects: [
          SubjectModel(
            id: 'sub-orphan',
            semesterId: 'deleted-sem-99',
            name: 'Orphaned Subject Without Semester',
            code: 'ORP101',
            isPublished: true,
          ),
        ],
      );

      final results = await searchService.search('Orphaned Subject');
      expect(results.length, 1);
      final item = results.first;
      expect(item.id, 'sub-orphan');
      expect(item.semester, isNull);
      expect(item.contextTrail, isEmpty);
    });

    test('Does not fallback to Semester 1 when module has unresolved subject', () async {
      searchService.setMockData(
        semesters: [
          SemesterModel(id: 'sem-1', semesterNumber: 1, title: 'Semester 1', isPublished: true),
        ],
        subjects: [],
        modules: [
          ModuleModel(
            id: 'mod-orphan',
            subjectId: 'nonexistent-sub',
            moduleNumber: 3,
            title: 'Orphan Module',
            isPublished: true,
          ),
        ],
      );

      final results = await searchService.search('Orphan Module');
      expect(results.length, 1);
      final item = results.first;
      expect(item.subject, isNull);
      expect(item.semester, isNull);
    });

    test('Does not fallback to Semester 1 when resource has unresolved subject and semester', () async {
      searchService.setMockData(
        semesters: [
          SemesterModel(id: 'sem-1', semesterNumber: 1, title: 'Semester 1', isPublished: true),
        ],
        subjects: [],
        resources: [
          AcademicResourceModel(
            id: 'res-orphan',
            title: 'Unlinked Resource Notes',
            fileName: 'unlinked_notes.pdf',
            type: ResourceType.notes,
            semesterId: '',
            subjectId: 'nonexistent-sub',
            isPublished: true,
          ),
        ],
      );

      final results = await searchService.search('Unlinked Resource Notes');
      expect(results.length, 1);
      final item = results.first;
      expect(item.subject, isNull);
      expect(item.semester, isNull);
      expect(item.contextTrail, isEmpty);
    });
  });

  group('Unresolved Search Result Navigation in StudentHomeScreen', () {
    late AcademicSearchService mockSearchService;
    late MockTestAcademicService mockAcademicService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ThemeController.instance.resetForTesting();
      mockAcademicService = MockTestAcademicService();
      mockSearchService = AcademicSearchService();
    });

    testWidgets('Selecting subject with unresolvable semester shows error snackbar and stays on page', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      mockSearchService.setMockData(
        semesters: [],
        subjects: [
          SubjectModel(
            id: 'sub-orphan',
            semesterId: 'deleted-sem-99',
            name: 'Quantum Physics',
            code: 'PHY301',
            isPublished: true,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: StudentHomeScreen(
            academicService: mockAcademicService,
            searchService: mockSearchService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Search for "Quantum Physics"
      await tester.enterText(find.byType(TextField), 'Quantum');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Tap the result tile
      expect(find.text('Quantum Physics'), findsOneWidget);
      await tester.tap(find.text('Quantum Physics'));
      await tester.pumpAndSettle();

      // Verify user-facing error snackbar is displayed
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Unable to open subject. Associated semester could not be resolved.'),
        findsOneWidget,
      );

      // Verify no invalid navigation occurred; still on StudentHomeScreen
      expect(find.byType(StudentHomeScreen), findsOneWidget);
      expect(find.byType(ModuleListScreen), findsNothing);
    });

    testWidgets('Selecting module with unresolvable subject shows error snackbar and stays on page', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      mockSearchService.setMockData(
        semesters: [],
        subjects: [],
        modules: [
          ModuleModel(
            id: 'mod-orphan',
            subjectId: 'deleted-subject-id',
            moduleNumber: 4,
            title: 'Neural Networks Architecture',
            isPublished: true,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: StudentHomeScreen(
            academicService: mockAcademicService,
            searchService: mockSearchService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Search for "Neural Networks"
      await tester.enterText(find.byType(TextField), 'Neural');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Tap the result tile
      expect(find.text('Module 4: Neural Networks Architecture'), findsOneWidget);
      await tester.tap(find.text('Module 4: Neural Networks Architecture'));
      await tester.pumpAndSettle();

      // Verify error snackbar is displayed
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Unable to open module. Associated subject could not be resolved.'),
        findsOneWidget,
      );

      // Verify no invalid navigation occurred
      expect(find.byType(StudentHomeScreen), findsOneWidget);
      expect(find.byType(ModuleResourcesScreen), findsNothing);
    });

    testWidgets('Selecting resource without PDF URL and unresolvable subject shows error feedback', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      mockSearchService.setMockData(
        semesters: [],
        subjects: [],
        modules: [],
        resources: [
          AcademicResourceModel(
            id: 'res-no-pdf',
            title: 'Unlinked Syllabus Document',
            fileName: '',
            fileUrl: '',
            type: ResourceType.syllabus,
            semesterId: '',
            subjectId: 'nonexistent-sub',
            isPublished: true,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: StudentHomeScreen(
            academicService: mockAcademicService,
            searchService: mockSearchService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Search for "Unlinked Syllabus"
      await tester.enterText(find.byType(TextField), 'Unlinked');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Tap the result tile
      expect(find.text('Unlinked Syllabus Document'), findsOneWidget);
      await tester.tap(find.text('Unlinked Syllabus Document'));
      await tester.pumpAndSettle();

      // Verify error feedback
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Unable to open "Unlinked Syllabus Document". Associated subject could not be resolved.'),
        findsOneWidget,
      );
      expect(find.byType(StudentHomeScreen), findsOneWidget);
    });
  });
}
