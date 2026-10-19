import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:study_deck/core/config/cloudinary_config.dart';

/// Exception thrown when a Cloudinary PDF upload fails.
class CloudinaryException implements Exception {
  const CloudinaryException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Result returned upon a successful Cloudinary PDF upload.
class CloudinaryUploadResult {
  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
    required this.originalFilename,
    required this.bytes,
    required this.format,
  });

  /// The HTTPS URL for securely viewing and downloading the uploaded PDF.
  final String secureUrl;

  /// The unique public identifier of the asset in Cloudinary.
  final String publicId;

  /// The original name of the file before upload.
  final String originalFilename;

  /// The size of the uploaded file in bytes.
  final int bytes;

  /// File format (typically 'pdf').
  final String format;

  factory CloudinaryUploadResult.fromJson(Map<String, dynamic> json) {
    return CloudinaryUploadResult(
      secureUrl: json['secure_url'] as String? ?? '',
      publicId: json['public_id'] as String? ?? '',
      originalFilename: json['original_filename'] as String? ?? '',
      bytes: (json['bytes'] as num?)?.toInt() ?? 0,
      format: json['format'] as String? ?? 'pdf',
    );
  }
}

/// Service that handles uploading PDF documents to Cloudinary using unsigned presets.
class CloudinaryService {
  CloudinaryService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  /// Validates and uploads a PDF file to Cloudinary.
  ///
  /// - Enforces that the file name has a `.pdf` extension.
  /// - Enforces that the file size does not exceed 10 MB (10,485,760 bytes).
  /// - Uses the unsigned upload preset and folder configured in [CloudinaryConfig].
  /// - Does NOT require or expose any Cloudinary API Secret.
  Future<CloudinaryUploadResult> uploadPdf({
    required Uint8List fileBytes,
    required String fileName,
    String? cloudName,
    String? uploadPreset,
    String? folder,
  }) async {
    final effectiveCloudName = cloudName ?? CloudinaryConfig.cloudName;
    final effectivePreset = uploadPreset ?? CloudinaryConfig.uploadPreset;
    final effectiveFolder = folder ?? CloudinaryConfig.assetFolder;

    // 1. Client-side File Format Validation
    final cleanFileName = fileName.trim();
    if (!cleanFileName.toLowerCase().endsWith('.pdf')) {
      throw CloudinaryException(
        'Invalid file type: "$cleanFileName". Only PDF documents (.pdf) are allowed.',
      );
    }

    // 2. Client-side File Size Validation (Max 10 MB)
    if (fileBytes.isEmpty) {
      throw CloudinaryException('The selected PDF file is empty (0 bytes).');
    }

    if (fileBytes.length > CloudinaryConfig.maxFileSizeBytes) {
      final sizeMb = (fileBytes.length / (1024 * 1024)).toStringAsFixed(2);
      throw CloudinaryException(
        'File size exceeds the 10 MB limit. Selected file size: $sizeMb MB.',
      );
    }

    // 3. Construct Multipart HTTP Request
    final uploadUri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$effectiveCloudName/auto/upload',
    );

    final request = http.MultipartRequest('POST', uploadUri)
      ..fields['upload_preset'] = effectivePreset
      ..fields['folder'] = effectiveFolder
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: cleanFileName,
        ),
      );

    try {
      final streamedResponse = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final result = CloudinaryUploadResult.fromJson(responseData);

        if (result.secureUrl.isEmpty) {
          throw CloudinaryException(
            'Cloudinary response did not contain a valid secure_url.',
            statusCode: response.statusCode,
          );
        }

        return result;
      } else {
        // Parse error message from Cloudinary if available
        String errorMessage = 'Upload failed with HTTP status ${response.statusCode}.';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData.containsKey('error')) {
            final errorMap = errorData['error'];
            if (errorMap is Map && errorMap.containsKey('message')) {
              errorMessage = errorMap['message'].toString();
            }
          }
        } catch (_) {
          errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
        }

        developer.log(
          'Cloudinary upload error (${response.statusCode}): $errorMessage',
          name: 'CloudinaryService',
        );

        throw CloudinaryException(
          'Cloudinary Error: $errorMessage',
          statusCode: response.statusCode,
        );
      }
    } on CloudinaryException {
      rethrow;
    } catch (e, st) {
      developer.log(
        'Network exception during Cloudinary upload: $e',
        error: e,
        stackTrace: st,
        name: 'CloudinaryService',
      );
      throw CloudinaryException(
        'Network error during upload. Please check your internet connection: $e',
      );
    }
  }
}
