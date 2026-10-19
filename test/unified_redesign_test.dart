import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_deck/core/session/admin_session.dart';
import 'package:study_deck/models/academic_resource_model.dart';
import 'package:study_deck/models/admin_user_model.dart';
import 'package:study_deck/models/module_model.dart';
import 'package:study_deck/models/semester_model.dart';
import 'package:study_deck/models/subject_model.dart';
import 'package:study_deck/screens/deck/module_list_screen.dart';
import 'package:study_deck/screens/deck/module_resources_screen.dart';
import 'package:study_deck/screens/student/subject_list_screen.dart';
import 'package:study_deck/services/academic_service.dart';
import 'package:study_deck/services/auth_service.dart';

class TestMockAcademicService extends AcademicService {
  TestMockAcademicService({
    this.subjects = const [],
    this.modules = const [],
    this.resources = const [],
  });

  final List<SubjectModel> subjects;
  final List<ModuleModel> modules;
  final List<AcademicResourceModel> resources;

  SubjectModel? lastUpdatedSubject;

  @override
  Stream<List<SubjectModel>> watchPublishedSubjects(
    String semesterId, {
    SemesterModel? semester,
  }) {
    return Stream.value(subjects);
  }

  @override
  Stream<List<SubjectModel>> watchAllSubjects() {
    return Stream.value(subjects);
  }

  @override
  Stream<List<ModuleModel>> watchPublishedModules(
    String subjectId, {
    SubjectModel? subject,
  }) {
    return Stream.value(modules);
  }

  @override
  Stream<List<ModuleModel>> watchAllModules() {
    return Stream.value(modules);
  }

  @override
  Stream<List<AcademicResourceModel>> watchPublishedResources({
    required String subjectId,
    SubjectModel? subject,
    String? moduleId,
    ResourceType? type,
  }) {
    return Stream.value(resources);
  }

  @override
  Stream<List<AcademicResourceModel>> watchAllResources() {
    return Stream.value(resources);
  }

  @override
  Future<void> updateSubject(SubjectModel subject) async {
    lastUpdatedSubject = subject;
  }
}

class TestMockAuthService extends AuthService {}

void main() {
  const testSemester = SemesterModel(
    id: 'sem_1',
    semesterNumber: 1,
    title: 'Semester 1',
  );

  const testSubject = SubjectModel(
    id: 'sub_trial',
    semesterId: 'sem_1',
    name: 'Trial Course',
    code: 'TC101',
    description: 'Course description for trial',
    isPublished: true,
  );

  const testModule1 = ModuleModel(
    id: 'mod_1',
    subjectId: 'sub_trial',
    moduleNumber: 1,
    title: 'Foundations of Computing',
    description: 'Introduction to hardware and software',
    isPublished: true,
  );

  const testModule2 = ModuleModel(
    id: 'mod_2',
    subjectId: 'sub_trial',
    moduleNumber: 2,
    title: 'Data Structures',
    description: 'Arrays, lists, and trees',
    isPublished: true,
  );

  final testNotesResource = AcademicResourceModel(
    id: 'res_notes_1',
    title: 'Module 1 Complete Lecture Notes',
    semesterId: 'sem_1',
    subjectId: 'sub_trial',
    moduleId: 'mod_1',
    type: ResourceType.notes,
    fileUrl: 'https://example.com/notes1.pdf',
    fileName: 'lecture_notes.pdf',
    fileSize: 1024 * 1024,
    isPublished: true,
  );

  final testPyqResource = AcademicResourceModel(
    id: 'res_pyq_1',
    title: '2025 Midterm Question Paper',
    semesterId: 'sem_1',
    subjectId: 'sub_trial',
    moduleId: 'mod_1',
    type: ResourceType.pyq,
    fileUrl: 'https://example.com/pyq2025.pdf',
    fileName: 'pyq_2025.pdf',
    fileSize: 500 * 1024,
    isPublished: true,
  );

  final testExtraResource = AcademicResourceModel(
    id: 'res_extra_1',
    title: 'Assignment 1 Problem Set',
    semesterId: 'sem_1',
    subjectId: 'sub_trial',
    moduleId: 'mod_1',
    type: ResourceType.assignment,
    fileUrl: 'https://example.com/assign1.pdf',
    fileName: 'assignment_1.pdf',
    fileSize: 300 * 1024,
    isPublished: true,
  );

  final adminUser = AdminUserModel(
    uid: 'admin_uid_1',
    email: 'admin@college.edu',
    role: 'admin',
    displayName: 'Professor Admin',
    isActive: true,
  );

  testWidgets('Subject page shows subjects for students without edit controls', (
    WidgetTester tester,
  ) async {
    final mockAcademic = TestMockAcademicService(
      subjects: [testSubject],
    );
    final adminSession = AdminSession(authService: TestMockAuthService());
    adminSession.setAdmin(null); // Ensure logged out student mode

    await tester.pumpWidget(
      AdminSessionScope(
        session: adminSession,
        child: MaterialApp(
          home: SubjectListScreen(
            semester: testSemester,
            academicService: mockAcademic,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify subject renders
    expect(find.text('Trial Course'), findsOneWidget);
    expect(find.text('TC101'), findsOneWidget);
    expect(find.text('Course description for trial'), findsOneWidget);

    // Verify Admin Login button is available in the app bar for faculty
    expect(find.text('Admin Login'), findsOneWidget);

    // Verify normal students DO NOT see Edit controls or Add Subject
    expect(find.byIcon(Icons.edit_note_rounded), findsNothing);
    expect(find.text('Add Subject'), findsNothing);
  });

  testWidgets('Subject page shows Edit option when admin is signed in and preserves IDs', (
    WidgetTester tester,
  ) async {
    final mockAcademic = TestMockAcademicService(
      subjects: [testSubject],
    );
    final adminSession = AdminSession(authService: TestMockAuthService());
    adminSession.setAdmin(adminUser); // Admin mode active

    await tester.pumpWidget(
      AdminSessionScope(
        session: adminSession,
        child: MaterialApp(
          home: SubjectListScreen(
            semester: testSemester,
            academicService: mockAcademic,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Admin badge should be visible
    expect(find.text('Admin'), findsOneWidget);
    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);

    // Edit button on subject card should be visible
    expect(find.byIcon(Icons.edit_note_rounded), findsOneWidget);
    expect(find.text('Add Subject'), findsOneWidget);

    // Tap the Edit Subject button
    await tester.tap(find.byIcon(Icons.edit_note_rounded));
    await tester.pumpAndSettle();

    // Edit dialog should appear with pre-populated values
    expect(find.text('Edit Subject'), findsOneWidget);
    expect(find.text('Trial Course'), findsWidgets);
    expect(find.text('TC101'), findsWidgets);

    // Enter new name and save
    final nameField = find.widgetWithText(TextFormField, 'Subject Name *');
    await tester.enterText(nameField, 'Renamed Algorithms');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    // Verify mock academic service received update preserving ID & semesterId
    expect(mockAcademic.lastUpdatedSubject, isNotNull);
    expect(mockAcademic.lastUpdatedSubject!.id, equals('sub_trial'));
    expect(mockAcademic.lastUpdatedSubject!.semesterId, equals('sem_1'));
    expect(mockAcademic.lastUpdatedSubject!.name, equals('Renamed Algorithms'));
    expect(mockAcademic.lastUpdatedSubject!.code, equals('TC101'));
  });

  testWidgets('Module page displays modules labeled Module 1, Module 2, Module 3', (
    WidgetTester tester,
  ) async {
    final mockAcademic = TestMockAcademicService(
      modules: [testModule1, testModule2],
    );
    final adminSession = AdminSession(authService: TestMockAuthService());
    adminSession.setAdmin(null);

    await tester.pumpWidget(
      AdminSessionScope(
        session: adminSession,
        child: MaterialApp(
          home: ModuleListScreen(
            semester: testSemester,
            subject: testSubject,
            academicService: mockAcademic,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify module badges and titles
    expect(find.text('Module 1'), findsOneWidget);
    expect(find.text('Foundations of Computing'), findsOneWidget);
    expect(find.text('Module 2'), findsOneWidget);
    expect(find.text('Data Structures'), findsOneWidget);
  });

  testWidgets('Module Resources page displays exactly 3 tabs (Notes, Question Bank, Extra Resources)', (
    WidgetTester tester,
  ) async {
    final mockAcademic = TestMockAcademicService(
      resources: [testNotesResource, testPyqResource, testExtraResource],
    );
    final adminSession = AdminSession(authService: TestMockAuthService());
    adminSession.setAdmin(null);

    await tester.pumpWidget(
      AdminSessionScope(
        session: adminSession,
        child: MaterialApp(
          home: ModuleResourcesScreen(
            semester: testSemester,
            subject: testSubject,
            module: testModule1,
            academicService: mockAcademic,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify the exactly 3 tabs
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Question Bank'), findsOneWidget);
    expect(find.text('Extra Resources'), findsOneWidget);

    // Initial tab is Notes: should show Notes item with View and Download buttons
    expect(find.text('Module 1 Complete Lecture Notes'), findsOneWidget);
    expect(find.text('View PDF'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);

    // Switch to Question Bank tab
    await tester.tap(find.text('Question Bank'));
    await tester.pumpAndSettle();
    expect(find.text('2025 Midterm Question Paper'), findsOneWidget);

    // Switch to Extra Resources tab
    await tester.tap(find.text('Extra Resources'));
    await tester.pumpAndSettle();
    expect(find.text('Assignment 1 Problem Set'), findsOneWidget);
  });

  testWidgets('Admin mode displays subjects created with numeric semesterId ("1") matching Semester 1', (
    WidgetTester tester,
  ) async {
    const legacySemester = SemesterModel(
      id: 'SvbRKso2z7h30cuB8wE8',
      semesterNumber: 1,
      title: 'Semester 1',
    );

    const legacyTrialSubject = SubjectModel(
      id: 'KGPqKCEH0Pt2ji9QmqTz',
      semesterId: '1', // Legacy format stored as semesterNumber string
      name: 'Trial',
      code: 'TR101',
      description: 'Trial subject from previous dashboard',
      isPublished: true,
    );

    final mockAcademic = TestMockAcademicService(
      subjects: [legacyTrialSubject],
    );
    final adminSession = AdminSession(authService: TestMockAuthService());
    adminSession.setAdmin(adminUser); // Admin mode active

    await tester.pumpWidget(
      AdminSessionScope(
        session: adminSession,
        child: MaterialApp(
          home: SubjectListScreen(
            semester: legacySemester,
            academicService: mockAcademic,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify "Trial" is visible in admin mode
    expect(find.text('Trial'), findsOneWidget);
    expect(find.text('TR101'), findsOneWidget);
    // Verify admin edit option is available on the Trial card
    expect(find.byIcon(Icons.edit_note_rounded), findsOneWidget);
    // Verify empty state is NOT displayed
    expect(find.text('No Subjects Published'), findsNothing);
  });
}

