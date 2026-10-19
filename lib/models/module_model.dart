import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a syllabus unit or module within a subject.
class ModuleModel {
  const ModuleModel({
    required this.id,
    required this.subjectId,
    required this.moduleNumber,
    required this.title,
    this.description = '',
    this.isPublished = true,
    this.order = 0,
  });

  final String id;
  final String subjectId;
  final int moduleNumber;
  final String title;
  final String description;
  final bool isPublished;
  final int order;

  factory ModuleModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ModuleModel(
      id: doc.id,
      subjectId: data['subjectId'] as String? ?? '',
      moduleNumber: (data['moduleNumber'] as num?)?.toInt() ?? 1,
      title: data['title'] as String? ?? 'Module ${data['moduleNumber'] ?? ''}',
      description: data['description'] as String? ?? '',
      isPublished: data['isPublished'] as bool? ?? true,
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }

  ModuleModel copyWith({
    String? id,
    String? subjectId,
    int? moduleNumber,
    String? title,
    String? description,
    bool? isPublished,
    int? order,
  }) {
    return ModuleModel(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      moduleNumber: moduleNumber ?? this.moduleNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      isPublished: isPublished ?? this.isPublished,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectId': subjectId,
      'moduleNumber': moduleNumber,
      'title': title,
      'description': description,
      'isPublished': isPublished,
      'order': order,
    };
  }
}

