import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an academic course/subject under a semester.
class SubjectModel {
  const SubjectModel({
    required this.id,
    required this.semesterId,
    required this.name,
    required this.code,
    this.description = '',
    this.isPublished = true,
    this.order = 0,
  });

  final String id;
  final String semesterId;
  final String name;
  final String code;
  final String description;
  final bool isPublished;
  final int order;

  factory SubjectModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SubjectModel(
      id: doc.id,
      semesterId: data['semesterId'] as String? ?? '',
      name: data['name'] as String? ?? 'Untitled Subject',
      code: data['code'] as String? ?? '',
      description: data['description'] as String? ?? '',
      isPublished: data['isPublished'] as bool? ?? true,
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }

  SubjectModel copyWith({
    String? id,
    String? semesterId,
    String? name,
    String? code,
    String? description,
    bool? isPublished,
    int? order,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      isPublished: isPublished ?? this.isPublished,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'semesterId': semesterId,
      'name': name,
      'code': code,
      'description': description,
      'isPublished': isPublished,
      'order': order,
    };
  }
}

