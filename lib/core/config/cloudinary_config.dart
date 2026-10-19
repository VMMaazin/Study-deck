/// Centralized configuration for Cloudinary PDF asset storage.
///
/// Security Notice: Unsigned uploads require ONLY the Cloud Name and the
/// Upload Preset. Never store, request, or expose the Cloudinary API Secret
/// in client-side mobile/web code.
class CloudinaryConfig {
  CloudinaryConfig._();

  /// Cloudinary Cloud Name configured in Cloudinary Console.
  /// Default value provided: 'vk1tv53x'.
  static const String cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'vk1tv53x',
  );

  /// Unsigned upload preset configured in Cloudinary Console (Settings -> Upload).
  /// Must be configured with Signing Mode: Unsigned.
  static const String uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'studydeck_pdfs',
  );

  /// Target asset folder in Cloudinary for academic resources.
  static const String assetFolder = 'studydeck/resources';

  /// Maximum file size allowed for academic documents: 10 MB (in bytes).
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  /// Unsigned upload REST API endpoint for the configured Cloudinary account.
  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/auto/upload';
}
