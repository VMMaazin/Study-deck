import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_deck/core/session/admin_session.dart';
import 'package:study_deck/models/academic_resource_model.dart';
import 'package:study_deck/models/module_model.dart';
import 'package:study_deck/models/semester_model.dart';
import 'package:study_deck/models/subject_model.dart';
import 'package:study_deck/screens/deck/module_resources_screen.dart';
import 'package:study_deck/screens/viewer/pdf_viewer_screen.dart';
import 'package:study_deck/services/academic_service.dart';
import 'package:study_deck/services/auth_service.dart';

class MockPdfAcademicService extends AcademicService {
  MockPdfAcademicService({required this.resources});
  final List<AcademicResourceModel> resources;

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
}

class MockPdfAuthService extends AuthService {}

void main() {
  const testSemester = SemesterModel(
    id: 'sem_1',
    semesterNumber: 1,
    title: 'Semester 1',
  );

  const testSubject = SubjectModel(
    id: 'sub_1',
    semesterId: 'sem_1',
    name: 'Computer Networks',
    code: 'CN101',
    description: 'Networks basics',
    isPublished: true,
  );

  const testModule = ModuleModel(
    id: 'mod_1',
    subjectId: 'sub_1',
    moduleNumber: 1,
    title: 'OSI Model',
    description: 'Layers of OSI',
    isPublished: true,
  );

  const testResource = AcademicResourceModel(
    id: 'res_1',
    semesterId: 'sem_1',
    subjectId: 'sub_1',
    moduleId: 'mod_1',
    title: 'OSI Reference Guide',
    description: 'Comprehensive guide to OSI layers',
    fileUrl: 'https://res.cloudinary.com/demo/image/upload/sample.pdf',
    fileName: 'osi_guide.pdf',
    type: ResourceType.notes,
    isPublished: true,
  );

  testWidgets('ModuleResourcesScreen opens PdfViewerScreen when View PDF is clicked', (
    WidgetTester tester,
  ) async {
    final mockAcademic = MockPdfAcademicService(resources: [testResource]);
    final adminSession = AdminSession(authService: MockPdfAuthService());

    await tester.pumpWidget(
      AdminSessionScope(
        session: adminSession,
        child: MaterialApp(
          home: ModuleResourcesScreen(
            semester: testSemester,
            subject: testSubject,
            module: testModule,
            academicService: mockAcademic,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('OSI Reference Guide'), findsOneWidget);
    expect(find.text('View PDF'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);

    // Tap "View PDF"
    await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'View PDF'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'View PDF'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify PdfViewerScreen is pushed onto the navigation stack
    expect(find.byType(PdfViewerScreen), findsOneWidget);
    expect(find.text('OSI Reference Guide'), findsWidgets);
    expect(find.text('osi_guide.pdf'), findsOneWidget);
  });

  testWidgets('PdfViewerScreen displays controls and handles invalid URL safely', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PdfViewerScreen(
          title: 'Corrupt Document',
          fileUrl: '', // Invalid URL
          fileName: 'corrupt.pdf',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Corrupt Document'), findsOneWidget);
    expect(find.text('corrupt.pdf'), findsOneWidget);
    expect(find.text('Invalid Document URL'), findsOneWidget);
    expect(find.text('Go Back'), findsOneWidget);
  });
}
