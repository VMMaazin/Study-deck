import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_deck/core/config/cloudinary_config.dart';
import 'package:study_deck/services/cloudinary_service.dart';
import 'package:study_deck/services/pdf_picker_service.dart';

void main() {
  group('CloudinaryConfig & Service Validation Tests', () {
    test('CloudinaryConfig has expected non-secret parameters', () {
      expect(CloudinaryConfig.cloudName, equals('vk1tv53x'));
      expect(CloudinaryConfig.uploadPreset, equals('studydeck_pdfs'));
      expect(CloudinaryConfig.assetFolder, equals('studydeck/resources'));
      expect(CloudinaryConfig.maxFileSizeBytes, equals(10 * 1024 * 1024));
      expect(CloudinaryConfig.uploadUrl.toString(),
          contains('api.cloudinary.com/v1_1/vk1tv53x/auto/upload'));
    });

    test('CloudinaryService rejects non-PDF file extension before network call', () async {
      final service = CloudinaryService();
      final fakeBytes = Uint8List.fromList([1, 2, 3]);

      expect(
        () => service.uploadPdf(fileBytes: fakeBytes, fileName: 'notes.docx'),
        throwsA(
          isA<CloudinaryException>().having(
            (e) => e.message,
            'message',
            contains('Only PDF documents (.pdf) are allowed'),
          ),
        ),
      );
    });

    test('CloudinaryService rejects empty file before network call', () async {
      final service = CloudinaryService();
      final emptyBytes = Uint8List(0);

      expect(
        () => service.uploadPdf(fileBytes: emptyBytes, fileName: 'empty.pdf'),
        throwsA(
          isA<CloudinaryException>().having(
            (e) => e.message,
            'message',
            contains('empty (0 bytes)'),
          ),
        ),
      );
    });

    test('CloudinaryService rejects file exceeding 10 MB limit before network call', () async {
      final service = CloudinaryService();
      // 10 MB + 1 byte
      final oversizedBytes = Uint8List((10 * 1024 * 1024) + 1);

      expect(
        () => service.uploadPdf(fileBytes: oversizedBytes, fileName: 'large_syllabus.pdf'),
        throwsA(
          isA<CloudinaryException>().having(
            (e) => e.message,
            'message',
            contains('exceeds the 10 MB limit'),
          ),
        ),
      );
    });

    test('SelectedPdfDocument formats sizes accurately', () {
      final docKb = SelectedPdfDocument(
        name: 'intro.pdf',
        bytes: Uint8List(512 * 1024),
        size: 512 * 1024,
      );
      expect(docKb.formattedSize, equals('512.0 KB'));

      final docMb = SelectedPdfDocument(
        name: 'module1.pdf',
        bytes: Uint8List(2500000),
        size: 2500000,
      );
      expect(docMb.formattedSize, equals('2.38 MB'));
    });
  });
}
