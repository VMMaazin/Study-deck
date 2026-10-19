import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:idb_shim/idb_shim.dart';
import 'package:study_deck/models/academic_resource_model.dart';
import 'package:study_deck/models/downloaded_resource_model.dart';
import 'package:study_deck/models/module_model.dart';
import 'package:study_deck/models/semester_model.dart';
import 'package:study_deck/models/subject_model.dart';
import 'package:study_deck/screens/downloads/downloads_semester_screen.dart';
import 'package:study_deck/screens/viewer/pdf_viewer_screen.dart';
import 'package:study_deck/services/offline_storage_service.dart';
import 'package:study_deck/widgets/download_choice_dialog.dart';

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
    title: 'Module 1 Foundations',
    description: 'Intro to computing',
    isPublished: true,
  );

  const testResource = AcademicResourceModel(
    id: 'res_sample_1',
    semesterId: 'sem_1',
    subjectId: 'sub_trial',
    moduleId: 'mod_1',
    title: 'Lecture 1 Operating Systems',
    description: 'Kernel and Processes',
    fileUrl: 'https://res.cloudinary.com/demo/image/upload/sample.pdf',
    fileName: 'lecture1_os.pdf',
    type: ResourceType.notes,
    isPublished: true,
  );

  final samplePdfBytes = Uint8List.fromList(utf8.encode('%PDF-1.4 dummy test content'));

  group('OfflineStorageService Tests', () {
    late MemoryOfflineStorageAdapter memoryAdapter;
    late OfflineStorageService service;

    setUp(() {
      memoryAdapter = MemoryOfflineStorageAdapter();
      service = OfflineStorageService(adapter: memoryAdapter);
    });

    test('Saving and retrieving an offline resource', () async {
      final model = DownloadedResourceModel(
        id: testResource.id,
        title: testResource.title,
        fileName: testResource.fileName,
        fileSize: samplePdfBytes.length,
        fileUrl: testResource.fileUrl!,
        semesterId: testSemester.id,
        semesterTitle: testSemester.title,
        subjectId: testSubject.id,
        subjectTitle: testSubject.name,
        subjectCode: testSubject.code,
        moduleId: testModule1.id,
        moduleTitle: testModule1.title,
        resourceType: testResource.type,
        savedAt: DateTime.now(),
      );

      expect(await service.isResourceSaved(testResource.id), isFalse);

      await service.saveResource(metadata: model, bytes: samplePdfBytes);

      expect(await service.isResourceSaved(testResource.id), isTrue);

      final retrievedBytes = await service.getResourceBytes(testResource.id);
      expect(retrievedBytes, isNotNull);
      expect(retrievedBytes, equals(samplePdfBytes));

      final retrievedMeta = await service.getMetadata(testResource.id);
      expect(retrievedMeta, isNotNull);
      expect(retrievedMeta!.title, equals('Lecture 1 Operating Systems'));
    });

    test('Reliable Deduplication: saving matching ID overwrites without duplicates', () async {
      final model1 = DownloadedResourceModel(
        id: testResource.id,
        title: 'Initial Title',
        fileName: testResource.fileName,
        fileSize: 100,
        fileUrl: testResource.fileUrl!,
        semesterId: testSemester.id,
        semesterTitle: testSemester.title,
        subjectId: testSubject.id,
        subjectTitle: testSubject.name,
        moduleId: testModule1.id,
        moduleTitle: testModule1.title,
        resourceType: testResource.type,
        savedAt: DateTime.now(),
      );

      final model2 = model1.copyWith(title: 'Updated Title', fileSize: 200);

      await service.saveResource(metadata: model1, bytes: samplePdfBytes);
      await service.saveResource(metadata: model2, bytes: samplePdfBytes);

      final all = await service.getAllDownloadedResources();
      expect(all.length, equals(1));
      expect(all.first.title, equals('Updated Title'));
    });

    test('Safe Deletion: removing offline copy deletes only local copy', () async {
      final model = DownloadedResourceModel(
        id: testResource.id,
        title: testResource.title,
        fileName: testResource.fileName,
        fileSize: samplePdfBytes.length,
        fileUrl: testResource.fileUrl!,
        semesterId: testSemester.id,
        semesterTitle: testSemester.title,
        subjectId: testSubject.id,
        subjectTitle: testSubject.name,
        moduleId: testModule1.id,
        moduleTitle: testModule1.title,
        resourceType: testResource.type,
        savedAt: DateTime.now(),
      );

      await service.saveResource(metadata: model, bytes: samplePdfBytes);
      expect(await service.isResourceSaved(testResource.id), isTrue);

      await service.deleteResource(testResource.id);
      expect(await service.isResourceSaved(testResource.id), isFalse);
      expect(await service.getResourceBytes(testResource.id), isNull);
    });
  });

  group('DownloadChoiceDialog Widget Tests', () {
    testWidgets('Displays exactly two actions: Download in app and Download to device', (
      WidgetTester tester,
    ) async {
      final memoryAdapter = MemoryOfflineStorageAdapter();
      final service = OfflineStorageService(adapter: memoryAdapter);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadChoiceDialog(
              resource: testResource,
              semester: testSemester,
              subject: testSubject,
              module: testModule1,
              offlineStorageService: service,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Download Resource'), findsOneWidget);
      expect(find.text('Download in App'), findsOneWidget);
      expect(find.text('Download to Device'), findsOneWidget);
      expect(find.text('Save in App'), findsOneWidget);
      expect(find.text('Save File'), findsOneWidget);
    });

    testWidgets('Downloading in app persists offline and updates dialog to Saved state', (
      WidgetTester tester,
    ) async {
      final memoryAdapter = MemoryOfflineStorageAdapter();
      final service = OfflineStorageService(adapter: memoryAdapter);

      final mockClient = MockClient((request) async {
        return http.Response.bytes(samplePdfBytes, 200);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadChoiceDialog(
              resource: testResource,
              semester: testSemester,
              subject: testSubject,
              module: testModule1,
              offlineStorageService: service,
              httpClient: mockClient,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Click "Save in App"
      await tester.tap(find.text('Save in App'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify resource is now saved in memory storage
      expect(await service.isResourceSaved(testResource.id), isTrue);

      // Verify dialog now shows "View Offline" and remove icon
      expect(find.text('View Offline'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });
  });

  group('Downloads Navigation Hierarchy Tests', () {
    testWidgets('Downloads hierarchy navigates cleanly through Semester -> Subject -> Module -> Resource', (
      WidgetTester tester,
    ) async {
      final memoryAdapter = MemoryOfflineStorageAdapter();
      final service = OfflineStorageService(adapter: memoryAdapter);

      // Save a sample resource into offline storage
      final model = DownloadedResourceModel(
        id: testResource.id,
        title: testResource.title,
        fileName: testResource.fileName,
        fileSize: samplePdfBytes.length,
        fileUrl: testResource.fileUrl!,
        semesterId: testSemester.id,
        semesterTitle: testSemester.title,
        subjectId: testSubject.id,
        subjectTitle: testSubject.name,
        subjectCode: testSubject.code,
        moduleId: testModule1.id,
        moduleTitle: testModule1.title,
        resourceType: testResource.type,
        savedAt: DateTime.now(),
      );
      await service.saveResource(metadata: model, bytes: samplePdfBytes);

      // Step 1: Open DownloadsSemesterScreen
      await tester.pumpWidget(
        MaterialApp(
          home: DownloadsSemesterScreen(offlineStorageService: service),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Offline Downloads'), findsOneWidget);
      expect(find.text('Semester 1'), findsOneWidget);
      expect(find.text('1 saved document'), findsOneWidget);

      // Tap "Semester 1" to navigate to DownloadsSubjectScreen
      await tester.tap(find.text('Semester 1'));
      await tester.pumpAndSettle();

      // Step 2: Subject screen
      expect(find.text('Trial Course'), findsOneWidget);
      expect(find.text('TC101 • 1 saved document'), findsOneWidget);

      // Tap "Trial Course" to navigate to DownloadsModuleScreen
      await tester.tap(find.text('Trial Course'));
      await tester.pumpAndSettle();

      // Step 3: Module screen
      expect(find.text('Module 1 Foundations'), findsOneWidget);
      expect(find.text('1 saved PDF'), findsOneWidget);

      // Tap "Module 1 Foundations" to navigate to DownloadsResourceListScreen
      await tester.tap(find.text('Module 1 Foundations'));
      await tester.pumpAndSettle();

      // Step 4: Resource list screen
      expect(find.text('Lecture 1 Operating Systems'), findsOneWidget);
      expect(find.text('Saved Offline'), findsOneWidget);
      expect(find.text('View PDF'), findsOneWidget);
      expect(find.text('Export'), findsOneWidget);
    });

    testWidgets('Offline PDF viewer handles missing local data gracefully with re-download option', (
      WidgetTester tester,
    ) async {
      final memoryAdapter = MemoryOfflineStorageAdapter();
      OfflineStorageService.setMockInstance(OfflineStorageService(adapter: memoryAdapter));

      await tester.pumpWidget(
        const MaterialApp(
          home: PdfViewerScreen(
            title: 'Missing Document',
            documentId: 'non_existent_id',
            fileName: 'missing.pdf',
            fileUrl: 'https://res.cloudinary.com/demo/image/upload/sample.pdf',
            isOffline: true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Offline Document Not Found or Corrupted'), findsOneWidget);
      expect(find.text('Go Back'), findsOneWidget);
      expect(find.text('Try Re-download'), findsOneWidget);
    });
  });

  group('WebIndexedDbStorageAdapter Tests', () {
    late IdbFactory memoryIdb;
    late WebIndexedDbStorageAdapter webAdapter;

    setUp(() {
      memoryIdb = newIdbFactoryMemory();
      webAdapter = WebIndexedDbStorageAdapter(idbFactory: memoryIdb);
    });

    test('Separates metadata and PDF binary into distinct object stores', () async {
      await webAdapter.init();

      final model = DownloadedResourceModel(
        id: 'web_doc_1',
        title: 'Operating Systems Notes',
        fileName: 'os_notes.pdf',
        fileSize: samplePdfBytes.length,
        fileUrl: 'https://example.com/os.pdf',
        semesterId: testSemester.id,
        semesterTitle: testSemester.title,
        subjectId: testSubject.id,
        subjectTitle: testSubject.name,
        moduleId: testModule1.id,
        moduleTitle: testModule1.title,
        resourceType: ResourceType.notes,
        savedAt: DateTime.now(),
      );

      await webAdapter.save(metadata: model, bytes: samplePdfBytes);

      // Verify metadata store has entry without bytes
      final txn = webAdapter.db.transaction('saved_resources', idbModeReadOnly);
      final metaStore = txn.objectStore('saved_resources');
      final metaRaw = await metaStore.getObject('web_doc_1') as Map?;
      await txn.completed;

      expect(metaRaw, isNotNull);
      expect(metaRaw!['title'], 'Operating Systems Notes');
      expect(metaRaw.containsKey('bytes'), isFalse);

      // Verify blob store has bytes
      final blobTxn = webAdapter.db.transaction('resource_blobs', idbModeReadOnly);
      final blobStore = blobTxn.objectStore('resource_blobs');
      final blobRaw = await blobStore.getObject('web_doc_1') as Map?;
      await blobTxn.completed;

      expect(blobRaw, isNotNull);
      expect(blobRaw!['bytes'], equals(samplePdfBytes));

      // Listing downloads returns metadata without loading blobs
      final allMeta = await webAdapter.getAllMetadata();
      expect(allMeta.length, 1);
      expect(allMeta.first.title, 'Operating Systems Notes');

      // PDF retrieval retrieves bytes accurately
      final retrievedBytes = await webAdapter.getBytes('web_doc_1');
      expect(retrievedBytes, equals(samplePdfBytes));

      // Deletion deletes both metadata and blob
      await webAdapter.delete('web_doc_1');
      expect(await webAdapter.isSaved('web_doc_1'), isFalse);
      expect(await webAdapter.getBytes('web_doc_1'), isNull);
    });

    test('Backward compatibility: retrieves bytes from legacy v1 records with inline bytes', () async {
      // Simulate v1 legacy schema: database at version 1 with bytes inside saved_resources
      final v1Db = await memoryIdb.open(
        WebIndexedDbStorageAdapter.dbName,
        version: 1,
        onUpgradeNeeded: (event) {
          event.database.createObjectStore('saved_resources', keyPath: 'id');
        },
      );
      final v1Txn = v1Db.transaction('saved_resources', idbModeReadWrite);
      final v1Store = v1Txn.objectStore('saved_resources');
      await v1Store.put({
        'id': 'legacy_v1_doc',
        'title': 'Legacy V1 Notes',
        'fileName': 'legacy.pdf',
        'fileSize': samplePdfBytes.length,
        'fileUrl': 'https://example.com/legacy.pdf',
        'semesterId': testSemester.id,
        'semesterTitle': testSemester.title,
        'subjectId': testSubject.id,
        'subjectTitle': testSubject.name,
        'resourceType': 'notes',
        'savedAt': DateTime.now().toIso8601String(),
        'bytes': samplePdfBytes,
      });
      await v1Txn.completed;
      v1Db.close();

      // Open through upgraded WebIndexedDbStorageAdapter (version 2)
      final upgradedAdapter = WebIndexedDbStorageAdapter(idbFactory: memoryIdb);
      await upgradedAdapter.init();

      // Metadata listing does not include bytes
      final all = await upgradedAdapter.getAllMetadata();
      expect(all.length, 1);
      expect(all.first.id, 'legacy_v1_doc');
      expect(all.first.title, 'Legacy V1 Notes');

      // getBytes gracefully retrieves legacy inline bytes
      final bytes = await upgradedAdapter.getBytes('legacy_v1_doc');
      expect(bytes, equals(samplePdfBytes));
    });
  });

  group('IoFileStorageAdapter Android Manifest Atomic Writes & Recovery Tests', () {
    late io.Directory tempDir;
    late IoFileStorageAdapter ioAdapter;

    setUp(() {
      tempDir = io.Directory.systemTemp.createTempSync('studydeck_io_test_');
      ioAdapter = IoFileStorageAdapter(baseDirectory: tempDir);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Atomic write creates manifest.json and backup without leaving temporary files', () async {
      await ioAdapter.init();

      final model = DownloadedResourceModel(
        id: 'io_doc_1',
        title: 'Android Course Guide',
        fileName: 'android_guide.pdf',
        fileSize: samplePdfBytes.length,
        fileUrl: 'https://example.com/guide.pdf',
        semesterId: testSemester.id,
        semesterTitle: testSemester.title,
        subjectId: testSubject.id,
        subjectTitle: testSubject.name,
        moduleId: testModule1.id,
        moduleTitle: testModule1.title,
        resourceType: ResourceType.notes,
        savedAt: DateTime.now(),
      );

      await ioAdapter.save(metadata: model, bytes: samplePdfBytes);

      final offlineDir = io.Directory('${tempDir.path}${io.Platform.pathSeparator}studydeck_offline_docs');
      final manifestFile = io.File('${offlineDir.path}${io.Platform.pathSeparator}manifest.json');
      final tmpFile = io.File('${offlineDir.path}${io.Platform.pathSeparator}manifest.json.tmp');
      final bakFile = io.File('${offlineDir.path}${io.Platform.pathSeparator}manifest.json.bak');
      final pdfFile = io.File('${offlineDir.path}${io.Platform.pathSeparator}io_doc_1.pdf');

      expect(manifestFile.existsSync(), isTrue);
      expect(bakFile.existsSync(), isTrue);
      expect(tmpFile.existsSync(), isFalse); // Temporary file was properly renamed/cleaned up
      expect(pdfFile.existsSync(), isTrue);

      final retrieved = await ioAdapter.getMetadata('io_doc_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'Android Course Guide');
    });

    test('Crash recovery: promotes valid manifest.json.tmp if manifest.json was interrupted', () async {
      final offlineDir = io.Directory('${tempDir.path}${io.Platform.pathSeparator}studydeck_offline_docs');
      offlineDir.createSync(recursive: true);

      // Simulate interrupted write: manifest.json is truncated/empty, but manifest.json.tmp has valid JSON
      final validData = {
        'interrupted_doc': {
          'id': 'interrupted_doc',
          'title': 'Interrupted Document Recovered',
          'fileName': 'recovered.pdf',
          'fileSize': 1024,
          'fileUrl': 'https://example.com/rec.pdf',
          'semesterId': 'sem_1',
          'semesterTitle': 'Semester 1',
          'subjectId': 'sub_1',
          'subjectTitle': 'Subject 1',
          'resourceType': 'notes',
          'savedAt': DateTime.now().toIso8601String(),
        }
      };

      final tmpFile = io.File('${offlineDir.path}${io.Platform.pathSeparator}manifest.json.tmp');
      tmpFile.writeAsStringSync(jsonEncode(validData));

      final manifestFile = io.File('${offlineDir.path}${io.Platform.pathSeparator}manifest.json');
      manifestFile.writeAsStringSync('{"truncated_incomplete_json":');

      // Initialize adapter -> must recover from tmp
      final recoveryAdapter = IoFileStorageAdapter(baseDirectory: tempDir);
      await recoveryAdapter.init();

      final metadata = await recoveryAdapter.getMetadata('interrupted_doc');
      expect(metadata, isNotNull);
      expect(metadata!.title, 'Interrupted Document Recovered');
    });

    test('Corrupted manifest recovery: restores from manifest.json.bak and preserves corrupted file', () async {
      final offlineDir = io.Directory('${tempDir.path}${io.Platform.pathSeparator}studydeck_offline_docs');
      offlineDir.createSync(recursive: true);

      // Create valid backup file
      final backupData = {
        'backed_up_doc': {
          'id': 'backed_up_doc',
          'title': 'Backed Up Document',
          'fileName': 'backup.pdf',
          'fileSize': 2048,
          'fileUrl': 'https://example.com/bak.pdf',
          'semesterId': 'sem_1',
          'semesterTitle': 'Semester 1',
          'subjectId': 'sub_1',
          'subjectTitle': 'Subject 1',
          'resourceType': 'notes',
          'savedAt': DateTime.now().toIso8601String(),
        }
      };

      final bakFile = io.File('${offlineDir.path}${io.Platform.pathSeparator}manifest.json.bak');
      bakFile.writeAsStringSync(jsonEncode(backupData));

      // Create corrupted manifest.json
      final manifestFile = io.File('${offlineDir.path}${io.Platform.pathSeparator}manifest.json');
      manifestFile.writeAsStringSync('CORRUPT_BYTES_GARBAGE_DATA');

      // Initialize adapter -> must recover from bak without throwing or resetting to empty
      final recoveryAdapter = IoFileStorageAdapter(baseDirectory: tempDir);
      await recoveryAdapter.init();

      final metadata = await recoveryAdapter.getMetadata('backed_up_doc');
      expect(metadata, isNotNull);
      expect(metadata!.title, 'Backed Up Document');

      // Verify corrupted file was preserved with timestamp for diagnostics
      final preservedFiles = offlineDir.listSync().where(
        (f) => f.path.contains('manifest.corrupted.'),
      );
      expect(preservedFiles.isNotEmpty, isTrue);
    });
  });
}
