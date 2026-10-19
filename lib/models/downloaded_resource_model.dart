import 'package:study_deck/models/academic_resource_model.dart';

/// Metadata model for resources stored locally for in-app offline viewing.
/// Persisted locally in IndexedDB (Web) and application-private storage (Android).
class DownloadedResourceModel {
  const DownloadedResourceModel({
    required this.id,
    required this.title,
    required this.fileName,
    this.fileSize,
    required this.fileUrl,
    required this.semesterId,
    required this.semesterTitle,
    required this.subjectId,
    required this.subjectTitle,
    this.subjectCode,
    required this.moduleId,
    required this.moduleTitle,
    required this.resourceType,
    required this.savedAt,
    this.localPath,
  });

  /// The stable primary identifier, using the Firestore document ID.
  final String id;
  final String title;
  final String fileName;
  final int? fileSize;
  final String fileUrl;
  final String semesterId;
  final String semesterTitle;
  final String subjectId;
  final String subjectTitle;
  final String? subjectCode;
  final String moduleId;
  final String moduleTitle;
  final ResourceType resourceType;
  final DateTime savedAt;

  /// Android application-private file path, null on Flutter Web.
  final String? localPath;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'fileName': fileName,
      'fileSize': fileSize,
      'fileUrl': fileUrl,
      'semesterId': semesterId,
      'semesterTitle': semesterTitle,
      'subjectId': subjectId,
      'subjectTitle': subjectTitle,
      'subjectCode': subjectCode,
      'moduleId': moduleId,
      'moduleTitle': moduleTitle,
      'resourceType': resourceType.name,
      'savedAt': savedAt.toIso8601String(),
      'localPath': localPath,
    };
  }

  factory DownloadedResourceModel.fromMap(Map<String, dynamic> map) {
    ResourceType type = ResourceType.notes;
    final typeStr = map['resourceType'] as String?;
    if (typeStr != null) {
      for (final t in ResourceType.values) {
        if (t.name == typeStr) {
          type = t;
          break;
        }
      }
    }

    DateTime date;
    try {
      date = DateTime.parse(map['savedAt'] as String);
    } catch (_) {
      date = DateTime.now();
    }

    return DownloadedResourceModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      fileName: map['fileName'] as String? ?? '',
      fileSize: map['fileSize'] as int?,
      fileUrl: map['fileUrl'] as String? ?? '',
      semesterId: map['semesterId'] as String? ?? '',
      semesterTitle: map['semesterTitle'] as String? ?? 'Semester',
      subjectId: map['subjectId'] as String? ?? '',
      subjectTitle: map['subjectTitle'] as String? ?? 'Subject',
      subjectCode: map['subjectCode'] as String?,
      moduleId: map['moduleId'] as String? ?? '',
      moduleTitle: map['moduleTitle'] as String? ?? 'Module',
      resourceType: type,
      savedAt: date,
      localPath: map['localPath'] as String?,
    );
  }

  DownloadedResourceModel copyWith({
    String? id,
    String? title,
    String? fileName,
    int? fileSize,
    String? fileUrl,
    String? semesterId,
    String? semesterTitle,
    String? subjectId,
    String? subjectTitle,
    String? subjectCode,
    String? moduleId,
    String? moduleTitle,
    ResourceType? resourceType,
    DateTime? savedAt,
    String? localPath,
  }) {
    return DownloadedResourceModel(
      id: id ?? this.id,
      title: title ?? this.title,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      fileUrl: fileUrl ?? this.fileUrl,
      semesterId: semesterId ?? this.semesterId,
      semesterTitle: semesterTitle ?? this.semesterTitle,
      subjectId: subjectId ?? this.subjectId,
      subjectTitle: subjectTitle ?? this.subjectTitle,
      subjectCode: subjectCode ?? this.subjectCode,
      moduleId: moduleId ?? this.moduleId,
      moduleTitle: moduleTitle ?? this.moduleTitle,
      resourceType: resourceType ?? this.resourceType,
      savedAt: savedAt ?? this.savedAt,
      localPath: localPath ?? this.localPath,
    );
  }
}
