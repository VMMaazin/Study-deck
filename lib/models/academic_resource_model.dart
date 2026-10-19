import 'package:cloud_firestore/cloud_firestore.dart';

/// Supported types of academic learning materials.
enum ResourceType {
  notes,
  pyq,
  assignment,
  syllabus,
  other;

  static ResourceType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'notes':
        return ResourceType.notes;
      case 'pyq':
        return ResourceType.pyq;
      case 'assignment':
        return ResourceType.assignment;
      case 'syllabus':
        return ResourceType.syllabus;
      default:
        return ResourceType.other;
    }
  }

  String get displayName {
    switch (this) {
      case ResourceType.notes:
        return 'Lecture Notes';
      case ResourceType.pyq:
        return 'Previous Year Question';
      case ResourceType.assignment:
        return 'Assignment';
      case ResourceType.syllabus:
        return 'Syllabus';
      case ResourceType.other:
        return 'Reference Material';
    }
  }
}

/// Represents an academic resource file or document (PDF, notes, PYQ, assignment).
class AcademicResourceModel {
  const AcademicResourceModel({
    required this.id,
    required this.title,
    required this.semesterId,
    required this.subjectId,
    this.moduleId,
    this.description = '',
    this.type = ResourceType.notes,
    this.fileUrl,
    this.fileName = '',
    this.fileSize,
    this.isPublished = true,
    this.createdAt,
  });

  final String id;
  final String title;
  final String semesterId;
  final String subjectId;
  final String? moduleId;
  final String description;
  final ResourceType type;
  final String? fileUrl;
  final String fileName;
  final int? fileSize;
  final bool isPublished;
  final DateTime? createdAt;

  factory AcademicResourceModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return AcademicResourceModel.fromMap(doc.id, doc.data() ?? {});
  }

  factory AcademicResourceModel.fromMap(String id, Map<String, dynamic> data) {
    final createdTimestamp = data['createdAt'] as Timestamp?;

    return AcademicResourceModel(
      id: id,
      title: data['title'] as String? ?? 'Untitled Resource',
      semesterId: data['semesterId']?.toString() ?? '',
      subjectId: data['subjectId']?.toString() ?? '',
      moduleId: data['moduleId']?.toString(),
      description: data['description'] as String? ?? '',
      type: ResourceType.fromString(data['type'] as String?),
      fileUrl: data['fileUrl'] as String?,
      fileName: data['fileName'] as String? ?? '',
      fileSize: (data['fileSize'] as num?)?.toInt(),
      isPublished: data['isPublished'] as bool? ?? true,
      createdAt: createdTimestamp?.toDate(),
    );
  }

  AcademicResourceModel copyWith({
    String? id,
    String? title,
    String? semesterId,
    String? subjectId,
    String? moduleId,
    String? description,
    ResourceType? type,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    bool? isPublished,
    DateTime? createdAt,
  }) {
    return AcademicResourceModel(
      id: id ?? this.id,
      title: title ?? this.title,
      semesterId: semesterId ?? this.semesterId,
      subjectId: subjectId ?? this.subjectId,
      moduleId: moduleId ?? this.moduleId,
      description: description ?? this.description,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'semesterId': semesterId,
      'subjectId': subjectId,
      'moduleId': moduleId,
      'description': description,
      'type': type.name,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'isPublished': isPublished,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}

