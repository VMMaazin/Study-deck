import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an academic semester (e.g. Semester 1 to 8).
class SemesterModel {
  const SemesterModel({
    required this.id,
    required this.semesterNumber,
    required this.title,
    this.description = '',
    this.isPublished = true,
    this.order = 0,
  });

  final String id;
  final int semesterNumber;
  final String title;
  final String description;
  final bool isPublished;
  final int order;

  factory SemesterModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SemesterModel(
      id: doc.id,
      semesterNumber: (data['semesterNumber'] as num?)?.toInt() ?? 1,
      title: data['title'] as String? ?? 'Semester ${data['semesterNumber'] ?? ''}',
      description: data['description'] as String? ?? '',
      isPublished: data['isPublished'] as bool? ?? true,
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'semesterNumber': semesterNumber,
      'title': title,
      'description': description,
      'isPublished': isPublished,
      'order': order,
    };
  }
}
