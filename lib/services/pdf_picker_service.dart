import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:study_deck/core/config/cloudinary_config.dart';
import 'package:study_deck/services/cloudinary_service.dart';

/// Represents a validated PDF document selected by the user.
class SelectedPdfDocument {
  const SelectedPdfDocument({
    required this.name,
    required this.bytes,
    required this.size,
  });

  /// The original filename (e.g., 'Unit1_DataStructures.pdf').
  final String name;

  /// The raw file bytes.
  final Uint8List bytes;

  /// The size of the file in bytes.
  final int size;

  /// Returns a human-readable file size string (e.g., '2.4 MB' or '520 KB').
  String get formattedSize {
    if (size >= 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(size / 1024).toStringAsFixed(1)} KB';
  }
}

/// Helper service for picking and validating PDF documents on Web and Android.
class PdfPickerService {
  const PdfPickerService();

  /// Opens the native platform file picker filtered to `.pdf` files.
  ///
  /// Enforces client-side validation:
  /// 1. Must be a PDF document (`.pdf`).
  /// 2. Must not exceed 10 MB.
  ///
  /// Returns `null` if the user cancelled the picker.
  Future<SelectedPdfDocument?> pickPdf() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );

    if (picked == null) {
      return null;
    }

    final fileName = picked.name.trim();

    // 1. Validate File Extension
    final isPdfExtension = fileName.toLowerCase().endsWith('.pdf') ||
        (picked.extension != null && picked.extension!.toLowerCase() == 'pdf');
    if (!isPdfExtension) {
      throw CloudinaryException(
        'Invalid file type: "$fileName". Only PDF documents (.pdf) are accepted.',
      );
    }

    // 2. Read bytes in a cross-platform manner (Web and Android compatible)
    final fileBytes = await picked.readAsBytes();

    if (fileBytes.isEmpty) {
      throw const CloudinaryException('The selected file is empty (0 bytes).');
    }

    final fileSize = fileBytes.length;

    // 3. Validate File Size (Maximum 10 MB)
    if (fileSize > CloudinaryConfig.maxFileSizeBytes) {
      final sizeMb = (fileSize / (1024 * 1024)).toStringAsFixed(2);
      throw CloudinaryException(
        'Selected file ($sizeMb MB) exceeds the maximum allowed size of 10 MB.',
      );
    }

    return SelectedPdfDocument(
      name: fileName,
      bytes: fileBytes,
      size: fileSize,
    );
  }
}
