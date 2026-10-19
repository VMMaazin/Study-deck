import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_deck/models/academic_resource_model.dart';
import 'package:study_deck/models/module_model.dart';
import 'package:study_deck/models/semester_model.dart';
import 'package:study_deck/models/subject_model.dart';

/// Service managing academic hierarchy (semesters, subjects, modules, resources)
/// via Cloud Firestore.
class AcademicService {
  AcademicService({
    FirebaseFirestore? firestore,
  }) : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  // ==========================================
  // Public Student Queries (Published Only)
  // ==========================================

  /// Streams all published semesters ordered by order/semesterNumber.
  Stream<List<SemesterModel>> watchPublishedSemesters() {
    return _firestore
        .collection('semesters')
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => SemesterModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => a.order != b.order
          ? a.order.compareTo(b.order)
          : a.semesterNumber.compareTo(b.semesterNumber));
      return list;
    });
  }

  /// Streams all published subjects under a specific semester.
  ///
  /// Supports matching by exact Firestore Document ID, and provides backward
  /// compatibility for manually entered semester numbers or titles.
  Stream<List<SubjectModel>> watchPublishedSubjects(
    String semesterId, {
    SemesterModel? semester,
  }) {
    final candidateSemesterIds = <String>{
      semesterId.trim(),
      if (semester != null) ...[
        semester.id.trim(),
        '${semester.semesterNumber}',
        semester.title.trim(),
      ],
    }.where((id) => id.isNotEmpty).toList();

    Query<Map<String, dynamic>> query = _firestore.collection('subjects');
    if (candidateSemesterIds.length == 1) {
      query = query.where('semesterId', isEqualTo: candidateSemesterIds.first);
    } else if (candidateSemesterIds.length > 1) {
      query = query.where('semesterId', whereIn: candidateSemesterIds);
    }
    query = query.where('isPublished', isEqualTo: true);

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => SubjectModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => a.order != b.order
          ? a.order.compareTo(b.order)
          : a.name.compareTo(b.name));
      return list;
    });
  }

  /// Streams all published syllabus modules under a subject.
  ///
  /// Supports matching by exact Firestore Document ID, as well as subject name or code.
  Stream<List<ModuleModel>> watchPublishedModules(
    String subjectId, {
    SubjectModel? subject,
  }) {
    final candidateSubjectIds = <String>{
      subjectId.trim(),
      if (subject != null) ...[
        subject.id.trim(),
        subject.name.trim(),
        if (subject.code.trim().isNotEmpty) subject.code.trim(),
      ],
    }.where((id) => id.isNotEmpty).toList();

    Query<Map<String, dynamic>> query = _firestore.collection('modules');
    if (candidateSubjectIds.length == 1) {
      query = query.where('subjectId', isEqualTo: candidateSubjectIds.first);
    } else if (candidateSubjectIds.length > 1) {
      query = query.where('subjectId', whereIn: candidateSubjectIds);
    }
    query = query.where('isPublished', isEqualTo: true);

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ModuleModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => a.order != b.order
          ? a.order.compareTo(b.order)
          : a.moduleNumber.compareTo(b.moduleNumber));
      return list;
    });
  }

  /// Streams published academic study resources for a subject,
  /// with optional filtering by moduleId and ResourceType.
  ///
  /// Maintains backward compatibility for legacy records with numeric module IDs
  /// and supports subject-wide general resources (null/empty moduleId) such as
  /// syllabus documents and question bank (PYQ) collections.
  Stream<List<AcademicResourceModel>> watchPublishedResources({
    required String subjectId,
    SubjectModel? subject,
    String? moduleId,
    ResourceType? type,
  }) {
    final candidateSubjectIds = <String>{
      subjectId.trim(),
      if (subject != null) ...[
        subject.id.trim(),
        subject.name.trim(),
        if (subject.code.trim().isNotEmpty) subject.code.trim(),
        if (subject.semesterId.trim().isNotEmpty) subject.semesterId.trim(),
      ],
    }.where((id) => id.isNotEmpty).toList();

    Query<Map<String, dynamic>> query = _firestore.collection('resources');
    if (candidateSubjectIds.length == 1) {
      query = query.where('subjectId', isEqualTo: candidateSubjectIds.first);
    } else if (candidateSubjectIds.length > 1) {
      query = query.where('subjectId', whereIn: candidateSubjectIds);
    }
    query = query.where('isPublished', isEqualTo: true);

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => AcademicResourceModel.fromFirestore(doc))
          .toList();

      final filteredList = list.where((r) {
        // If moduleId is supplied, include matching module resources,
        // legacy records with numeric module numbers, and general resources (null/empty moduleId).
        if (moduleId != null && moduleId.trim().isNotEmpty) {
          final targetModId = moduleId.trim();
          final targetDigits = RegExp(r'\d+').firstMatch(targetModId)?.group(0);
          final resModId = r.moduleId?.trim();

          // 1. General subject resources without a specific module (e.g., syllabus, PYQs, general notes)
          if (resModId == null || resModId.isEmpty) {
            return true;
          }

          // 2. Exact match on target moduleId
          if (resModId == targetModId) {
            return true;
          }

          // 3. Legacy numeric module match when target has digits (e.g. targetModId 'mod_1' or '1' matches resModId '1')
          if (targetDigits != null) {
            if (resModId == targetDigits) return true;
            final resDigits = RegExp(r'\d+').firstMatch(resModId)?.group(0);
            if (resDigits != null && resDigits == targetDigits) return true;
            return false;
          }

          // 4. If targetModId is an opaque ID without digits, retain legacy numeric module IDs
          // so callers with ModuleModel context can match against moduleNumber
          if (int.tryParse(resModId) != null) {
            return true;
          }

          return false;
        }

        return true;
      }).toList();

      filteredList.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!);
        }
        return a.title.compareTo(b.title);
      });
      return filteredList;
    });
  }

  // ==========================================
  // Admin Operations (Requires Authorized Admin)
  // ==========================================

  /// Streams all semesters for admin view (both published and draft).
  Stream<List<SemesterModel>> watchAllSemesters() {
    return _firestore.collection('semesters').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => SemesterModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => a.order != b.order
          ? a.order.compareTo(b.order)
          : a.semesterNumber.compareTo(b.semesterNumber));
      return list;
    });
  }

  /// Streams all subjects for admin view.
  Stream<List<SubjectModel>> watchAllSubjects() {
    return _firestore.collection('subjects').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => SubjectModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  /// Streams all modules for admin view.
  Stream<List<ModuleModel>> watchAllModules() {
    return _firestore.collection('modules').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ModuleModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => a.moduleNumber.compareTo(b.moduleNumber));
      return list;
    });
  }

  /// Streams all resources for admin view.
  Stream<List<AcademicResourceModel>> watchAllResources() {
    return _firestore.collection('resources').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => AcademicResourceModel.fromFirestore(doc))
          .toList();
      return list;
    });
  }

  /// Creates a new semester in Firestore.
  Future<void> createSemester(SemesterModel semester) async {
    try {
      await _firestore.collection('semesters').add(semester.toMap());
    } catch (e, st) {
      developer.log('Failed to create semester', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Updates an existing semester in Firestore.
  Future<void> updateSemester(SemesterModel semester) async {
    try {
      await _firestore.collection('semesters').doc(semester.id).update(semester.toMap());
    } catch (e, st) {
      developer.log('Failed to update semester', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Deletes a semester from Firestore.
  Future<void> deleteSemester(String semesterId) async {
    try {
      await _firestore.collection('semesters').doc(semesterId).delete();
    } catch (e, st) {
      developer.log('Failed to delete semester', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Creates a new subject in Firestore.
  Future<void> createSubject(SubjectModel subject) async {
    try {
      await _firestore.collection('subjects').add(subject.toMap());
    } catch (e, st) {
      developer.log('Failed to create subject', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Updates an existing subject in Firestore.
  Future<void> updateSubject(SubjectModel subject) async {
    try {
      await _firestore.collection('subjects').doc(subject.id).update(subject.toMap());
    } catch (e, st) {
      developer.log('Failed to update subject', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Deletes a subject from Firestore.
  Future<void> deleteSubject(String subjectId) async {
    try {
      await _firestore.collection('subjects').doc(subjectId).delete();
    } catch (e, st) {
      developer.log('Failed to delete subject', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Creates a new module in Firestore.
  Future<void> createModule(ModuleModel module) async {
    try {
      await _firestore.collection('modules').add(module.toMap());
    } catch (e, st) {
      developer.log('Failed to create module', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Updates an existing module in Firestore.
  Future<void> updateModule(ModuleModel module) async {
    try {
      await _firestore.collection('modules').doc(module.id).update(module.toMap());
    } catch (e, st) {
      developer.log('Failed to update module', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Deletes a module from Firestore.
  Future<void> deleteModule(String moduleId) async {
    try {
      await _firestore.collection('modules').doc(moduleId).delete();
    } catch (e, st) {
      developer.log('Failed to delete module', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Creates a new academic resource record in Firestore.
  Future<void> createResource(AcademicResourceModel resource) async {
    try {
      await _firestore.collection('resources').add(resource.toMap());
    } catch (e, st) {
      developer.log('Failed to create resource', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Updates an academic resource record in Firestore.
  Future<void> updateResource(AcademicResourceModel resource) async {
    try {
      await _firestore.collection('resources').doc(resource.id).update(resource.toMap());
    } catch (e, st) {
      developer.log('Failed to update resource', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Deletes an academic resource from Firestore.
  Future<void> deleteResource(String resourceId) async {
    try {
      await _firestore.collection('resources').doc(resourceId).delete();
    } catch (e, st) {
      developer.log('Failed to delete resource', error: e, stackTrace: st);
      rethrow;
    }
  }
}
