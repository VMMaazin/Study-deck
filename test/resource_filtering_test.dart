import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_deck/core/session/admin_session.dart';
import 'package:study_deck/models/academic_resource_model.dart';
import 'package:study_deck/models/module_model.dart';
import 'package:study_deck/models/semester_model.dart';
import 'package:study_deck/models/subject_model.dart';
import 'package:study_deck/screens/deck/module_resources_screen.dart';
import 'package:study_deck/services/academic_service.dart';
import 'package:study_deck/services/auth_service.dart';

class TestMockAuthService extends AuthService {}

class TestMockAcademicService extends AcademicService {
  TestMockAcademicService({required this.resources});
  final List<AcademicResourceModel> resources;

  @override
  Stream<List<AcademicResourceModel>> watchPublishedResources({
    required String subjectId,
    SubjectModel? subject,
    String? moduleId,
    ResourceType? type,
  }) {
    // Mimics the safe academic service filtering behavior
    if (moduleId != null && moduleId.trim().isNotEmpty) {
      final targetModId = moduleId.trim();
      final targetDigits = RegExp(r'\d+').firstMatch(targetModId)?.group(0);

      final filtered = resources.where((r) {
        final resModId = r.moduleId?.trim();
        if (resModId == null || resModId.isEmpty) return true;
        if (resModId == targetModId) return true;
        if (targetDigits != null) {
          if (resModId == targetDigits) return true;
          final resDigits = RegExp(r'\d+').firstMatch(resModId)?.group(0);
          if (resDigits != null && resDigits == targetDigits) return true;
          return false;
        }
        if (int.tryParse(resModId) != null) return true;
        return false;
      }).toList();
      return Stream.value(filtered);
    }
    return Stream.value(resources);
  }
}

void main() {
  const testSemester = SemesterModel(
    id: 'sem_1',
    semesterNumber: 1,
    title: 'Semester 1',
  );

  const testSubject = SubjectModel(
    id: 'sub_cs101',
    semesterId: 'sem_1',
    name: 'Computer Science 101',
    code: 'CS101',
    isPublished: true,
  );

  const testModule1 = ModuleModel(
    id: 'mod_1',
    subjectId: 'sub_cs101',
    moduleNumber: 1,
    title: 'Introduction to Algorithms',
    isPublished: true,
  );

  // 1. Module-1 specific notes
  final mod1Notes = AcademicResourceModel(
    id: 'res_mod1_notes',
    title: 'Module 1 Lecture Notes',
    semesterId: 'sem_1',
    subjectId: 'sub_cs101',
    moduleId: 'mod_1',
    type: ResourceType.notes,
    isPublished: true,
    fileUrl: 'https://example.com/mod1.pdf',
    fileName: 'mod1.pdf',
  );

  // 2. Legacy numeric module notes (e.g. moduleId: '1')
  final legacyNumericNotes = AcademicResourceModel(
    id: 'res_legacy_notes',
    title: 'Legacy Module 1 Handout',
    semesterId: 'sem_1',
    subjectId: 'sub_cs101',
    moduleId: '1', // Legacy numeric string
    type: ResourceType.notes,
    isPublished: true,
    fileUrl: 'https://example.com/legacy1.pdf',
    fileName: 'legacy1.pdf',
  );

  // 3. General Subject PYQ (moduleId is null)
  final generalPyq = AcademicResourceModel(
    id: 'res_general_pyq',
    title: '2024 End-Semester Question Paper',
    semesterId: 'sem_1',
    subjectId: 'sub_cs101',
    moduleId: null, // General subject resource
    type: ResourceType.pyq,
    isPublished: true,
    fileUrl: 'https://example.com/pyq.pdf',
    fileName: 'pyq.pdf',
  );

  // 4. General Subject Syllabus (moduleId is empty string)
  final generalSyllabus = AcademicResourceModel(
    id: 'res_general_syllabus',
    title: 'CS101 Official Syllabus',
    semesterId: 'sem_1',
    subjectId: 'sub_cs101',
    moduleId: '', // Empty moduleId representing general resource
    type: ResourceType.syllabus,
    isPublished: true,
    fileUrl: 'https://example.com/syllabus.pdf',
    fileName: 'syllabus.pdf',
  );

  // 5. Module-2 specific notes (should NOT appear in Module 1)
  final mod2Notes = AcademicResourceModel(
    id: 'res_mod2_notes',
    title: 'Module 2 Advanced Trees Notes',
    semesterId: 'sem_1',
    subjectId: 'sub_cs101',
    moduleId: 'mod_2',
    type: ResourceType.notes,
    isPublished: true,
    fileUrl: 'https://example.com/mod2.pdf',
    fileName: 'mod2.pdf',
  );

  // 6. Legacy Module-2 notes (should NOT appear in Module 1)
  final legacyMod2Notes = AcademicResourceModel(
    id: 'res_legacy_mod2_notes',
    title: 'Legacy Module 2 Practice',
    semesterId: 'sem_1',
    subjectId: 'sub_cs101',
    moduleId: '2',
    type: ResourceType.notes,
    isPublished: true,
    fileUrl: 'https://example.com/mod2_legacy.pdf',
    fileName: 'mod2_legacy.pdf',
  );

  group('Resource Filtering & Legacy Numeric Compatibility Tests', () {
    test('AcademicResourceModel.fromMap parses integer moduleId, semesterId, subjectId without crash', () {
      final rawData = {
        'title': 'Legacy Int Field Test',
        'semesterId': 1, // Integer in Firestore
        'subjectId': 101, // Integer in Firestore
        'moduleId': 1, // Integer in Firestore
        'type': 'notes',
        'isPublished': true,
      };

      final model = AcademicResourceModel.fromMap('res_test_1', rawData);
      expect(model.semesterId, '1');
      expect(model.subjectId, '101');
      expect(model.moduleId, '1');
      expect(model.type, ResourceType.notes);
    });

    testWidgets('ModuleResourcesScreen displays legacy numeric notes and excludes other module notes', (
      WidgetTester tester,
    ) async {
      final mockService = TestMockAcademicService(
        resources: [
          mod1Notes,
          legacyNumericNotes,
          mod2Notes,
          legacyMod2Notes,
          generalPyq,
          generalSyllabus,
        ],
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
              academicService: mockService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tab 1 (Notes):
      // Must show modern Module 1 notes and legacy numeric Module 1 notes
      expect(find.text('Module 1 Lecture Notes'), findsOneWidget);
      expect(find.text('Legacy Module 1 Handout'), findsOneWidget);

      // Must NOT show Module 2 notes
      expect(find.text('Module 2 Advanced Trees Notes'), findsNothing);
      expect(find.text('Legacy Module 2 Practice'), findsNothing);

      // Switch to Tab 2 (Question Bank):
      // Must show the general PYQ that had moduleId: null
      await tester.tap(find.text('Question Bank'));
      await tester.pumpAndSettle();
      expect(find.text('2024 End-Semester Question Paper'), findsOneWidget);

      // Switch to Tab 3 (Extra Resources):
      // Must show the general Syllabus that had empty moduleId
      await tester.tap(find.text('Extra Resources'));
      await tester.pumpAndSettle();
      expect(find.text('CS101 Official Syllabus'), findsOneWidget);
    });
  });
}
