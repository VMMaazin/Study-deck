import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:study_deck/models/academic_resource_model.dart';
import 'package:study_deck/models/module_model.dart';
import 'package:study_deck/models/semester_model.dart';
import 'package:study_deck/models/subject_model.dart';

/// Categorization of search results across the academic hierarchy.
enum SearchResultType {
  semester,
  subject,
  module,
  resource,
}

/// A unified search result item with complete hierarchical context.
class SearchResultItem {
  const SearchResultItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.resultType,
    this.code,
    this.resourceType,
    this.semester,
    this.subject,
    this.module,
    this.resource,
    this.contextTrail = '',
  });

  final String id;
  final String title;
  final String subtitle;
  final SearchResultType resultType;
  final String? code;
  final ResourceType? resourceType;
  final SemesterModel? semester;
  final SubjectModel? subject;
  final ModuleModel? module;
  final AcademicResourceModel? resource;
  final String contextTrail;

  String get typeLabel {
    switch (resultType) {
      case SearchResultType.semester:
        return 'Semester Deck';
      case SearchResultType.subject:
        return code != null && code!.isNotEmpty ? 'Subject • $code' : 'Subject';
      case SearchResultType.module:
        return 'Module Unit';
      case SearchResultType.resource:
        return resourceType?.displayName ?? 'Resource';
    }
  }
}

/// Service that executes high-performance, real-time academic search
/// across published Firestore records with local memory caching and relationship resolution.
class AcademicSearchService {
  AcademicSearchService({
    FirebaseFirestore? firestore,
  }) : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;
  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  // Cached collections with TTL to avoid redundant network reads while typing
  List<SemesterModel>? _cachedSemesters;
  List<SubjectModel>? _cachedSubjects;
  List<ModuleModel>? _cachedModules;
  List<AcademicResourceModel>? _cachedResources;
  DateTime? _lastCacheTime;

  static const Duration _cacheTtl = Duration(minutes: 3);
  Future<void>? _activeLoadFuture;

  bool get _isCacheValid =>
      _lastCacheTime != null &&
      DateTime.now().difference(_lastCacheTime!) < _cacheTtl &&
      _cachedSemesters != null &&
      _cachedSubjects != null &&
      _cachedModules != null &&
      _cachedResources != null;

  /// Invalidate cache manually (e.g. upon refresh or after upload/edit)
  void clearCache() {
    _cachedSemesters = null;
    _cachedSubjects = null;
    _cachedModules = null;
    _cachedResources = null;
    _lastCacheTime = null;
    _activeLoadFuture = null;
  }

  /// Injects preloaded models for unit testing search algorithms without Firestore.
  @visibleForTesting
  void setMockData({
    List<SemesterModel>? semesters,
    List<SubjectModel>? subjects,
    List<ModuleModel>? modules,
    List<AcademicResourceModel>? resources,
  }) {
    _cachedSemesters = semesters ?? [];
    _cachedSubjects = subjects ?? [];
    _cachedModules = modules ?? [];
    _cachedResources = resources ?? [];
    _lastCacheTime = DateTime.now();
    _activeLoadFuture = null;
  }

  /// Prime or fetch all published records from Firestore in parallel with concurrency deduplication.
  Future<void> _ensurePublishedDataLoaded({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid) return;

    if (!forceRefresh && _activeLoadFuture != null) {
      return _activeLoadFuture!;
    }

    final future = _fetchPublishedRecords();
    _activeLoadFuture = future;
    try {
      await future;
    } finally {
      if (_activeLoadFuture == future) {
        _activeLoadFuture = null;
      }
    }
  }

  Future<void> _fetchPublishedRecords() async {
    try {
      final results = await Future.wait([
        // 1. Published Semesters
        _firestore
            .collection('semesters')
            .where('isPublished', isEqualTo: true)
            .get()
            .then((snap) => snap.docs
                .map((d) => SemesterModel.fromFirestore(d))
                .toList()),

        // 2. Published Subjects
        _firestore
            .collection('subjects')
            .where('isPublished', isEqualTo: true)
            .get()
            .then((snap) =>
                snap.docs.map((d) => SubjectModel.fromFirestore(d)).toList()),

        // 3. Published Modules
        _firestore
            .collection('modules')
            .where('isPublished', isEqualTo: true)
            .get()
            .then((snap) =>
                snap.docs.map((d) => ModuleModel.fromFirestore(d)).toList()),

        // 4. Published Resources
        _firestore
            .collection('resources')
            .where('isPublished', isEqualTo: true)
            .get()
            .then((snap) => snap.docs
                .map((d) => AcademicResourceModel.fromFirestore(d))
                .toList()),
      ]);

      _cachedSemesters = results[0] as List<SemesterModel>;
      _cachedSubjects = results[1] as List<SubjectModel>;
      _cachedModules = results[2] as List<ModuleModel>;
      _cachedResources = results[3] as List<AcademicResourceModel>;
      _lastCacheTime = DateTime.now();
    } catch (e, st) {
      developer.log('Error caching published academic records for search',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Performs a comprehensive, multi-entity search matching query against
  /// semesters, subjects, modules, resources, PDF titles, codes, and types.
  Future<List<SearchResultItem>> search(String rawQuery) async {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return const [];

    await _ensurePublishedDataLoaded();

    final semesters = _cachedSemesters ?? [];
    final subjects = _cachedSubjects ?? [];
    final modules = _cachedModules ?? [];
    final resources = _cachedResources ?? [];

    final results = <SearchResultItem>[];

    // Helper: find parent semester for a given subject (supporting legacy ID variants)
    SemesterModel? resolveSemester(String? semesterId) {
      if (semesterId == null) return null;
      final clean = semesterId.trim().toLowerCase();
      if (clean.isEmpty) return null;
      for (final s in semesters) {
        if (s.id.toLowerCase() == clean ||
            s.semesterNumber.toString() == clean ||
            s.title.toLowerCase() == clean) {
          return s;
        }
      }
      return null;
    }

    // Helper: find parent subject for a given subjectId
    SubjectModel? resolveSubject(String subjectId) {
      final clean = subjectId.trim().toLowerCase();
      for (final s in subjects) {
        if (s.id.toLowerCase() == clean ||
            s.name.toLowerCase() == clean ||
            s.code.toLowerCase() == clean) {
          return s;
        }
      }
      return null;
    }

    // Helper: find parent module for a given moduleId
    ModuleModel? resolveModule(String? moduleId) {
      if (moduleId == null || moduleId.trim().isEmpty) return null;
      final clean = moduleId.trim().toLowerCase();
      for (final m in modules) {
        if (m.id.toLowerCase() == clean ||
            'module ${m.moduleNumber}' == clean ||
            'mod ${m.moduleNumber}' == clean) {
          return m;
        }
      }
      return null;
    }

    // Extract potential semester number if user typed "sem 5", "semester 3", or "5"
    final semRegex = RegExp(r'^(?:sem(?:ester)?\s*)?(\d{1,2})$');
    final semMatch = semRegex.firstMatch(query);
    final queriedSemNumber = semMatch != null ? int.tryParse(semMatch.group(1)!) : null;

    // Extract potential module number if user typed "mod 2", "module 3"
    final modRegex = RegExp(r'^(?:mod(?:ule)?\s*)?(\d{1,2})$');
    final modMatch = modRegex.firstMatch(query);
    final queriedModNumber = modMatch != null ? int.tryParse(modMatch.group(1)!) : null;

    // Category query tokens
    final isNotesQuery = query.contains('note') || query == 'lecture';
    final isPyqQuery = query.contains('pyq') ||
        query.contains('question') ||
        query.contains('paper') ||
        query.contains('exam');
    final isAssignmentQuery = query.contains('assign') || query.contains('homework');
    final isSyllabusQuery = query.contains('syllab') || query.contains('curriculum');

    // 1. MATCH SEMESTERS
    for (final sem in semesters) {
      final semNumStr = sem.semesterNumber.toString();
      final title = sem.title.toLowerCase();

      final matches = title.contains(query) ||
          query == semNumStr ||
          query == 'sem $semNumStr' ||
          query == 'semester $semNumStr' ||
          (queriedSemNumber != null && sem.semesterNumber == queriedSemNumber);

      if (matches) {
        results.add(
          SearchResultItem(
            id: sem.id,
            title: sem.title,
            subtitle: 'Curriculum Deck • Explore Subjects',
            resultType: SearchResultType.semester,
            semester: sem,
            contextTrail: 'Academic Deck',
          ),
        );
      }
    }

    // 2. MATCH SUBJECTS
    for (final sub in subjects) {
      final name = sub.name.toLowerCase();
      final code = sub.code.toLowerCase();
      final desc = sub.description.toLowerCase();

      final matches = name.contains(query) ||
          (code.isNotEmpty && code.contains(query)) ||
          desc.contains(query);

      if (matches) {
        final parentSem = resolveSemester(sub.semesterId);
        results.add(
          SearchResultItem(
            id: sub.id,
            title: sub.name,
            subtitle: sub.description.isNotEmpty
                ? sub.description
                : (parentSem != null
                    ? '${parentSem.title} • Syllabus Modules'
                    : 'Syllabus Modules'),
            code: sub.code.isNotEmpty ? sub.code : null,
            resultType: SearchResultType.subject,
            semester: parentSem,
            subject: sub,
            contextTrail: parentSem?.title ?? '',
          ),
        );
      }
    }

    // 3. MATCH MODULES
    for (final mod in modules) {
      final modTitle = mod.title.toLowerCase();
      final modNumStr = mod.moduleNumber.toString();
      final desc = mod.description.toLowerCase();

      final matches = modTitle.contains(query) ||
          query == 'mod $modNumStr' ||
          query == 'module $modNumStr' ||
          (queriedModNumber != null && mod.moduleNumber == queriedModNumber) ||
          desc.contains(query);

      if (matches) {
        final parentSub = resolveSubject(mod.subjectId);
        final parentSem = parentSub != null
            ? resolveSemester(parentSub.semesterId)
            : null;

        results.add(
          SearchResultItem(
            id: mod.id,
            title: 'Module ${mod.moduleNumber}: ${mod.title}',
            subtitle: parentSub != null
                ? '${parentSub.name} (${parentSub.code})'
                : 'Module Unit',
            resultType: SearchResultType.module,
            semester: parentSem,
            subject: parentSub,
            module: mod,
            contextTrail: parentSub != null
                ? (parentSem != null
                    ? '${parentSem.title} > ${parentSub.name}'
                    : parentSub.name)
                : (parentSem?.title ?? ''),
          ),
        );
      }
    }

    // 4. MATCH RESOURCES
    for (final res in resources) {
      final title = res.title.toLowerCase();
      final fileName = res.fileName.toLowerCase();
      final desc = res.description.toLowerCase();
      final typeStr = res.type.name.toLowerCase();
      final typeDisplay = res.type.displayName.toLowerCase();

      final matchesCategory = (isNotesQuery && res.type == ResourceType.notes) ||
          (isPyqQuery && res.type == ResourceType.pyq) ||
          (isAssignmentQuery && res.type == ResourceType.assignment) ||
          (isSyllabusQuery && res.type == ResourceType.syllabus);

      final matches = title.contains(query) ||
          fileName.contains(query) ||
          desc.contains(query) ||
          typeStr.contains(query) ||
          typeDisplay.contains(query) ||
          matchesCategory;

      if (matches) {
        final parentSub = resolveSubject(res.subjectId);
        final parentSem = parentSub != null
            ? resolveSemester(parentSub.semesterId)
            : (res.semesterId.isNotEmpty
                ? resolveSemester(res.semesterId)
                : null);
        final parentMod = resolveModule(res.moduleId);

        final trail = [
          if (parentSem != null) parentSem.title,
          if (parentSub != null) parentSub.name,
          if (parentMod != null) 'Module ${parentMod.moduleNumber}',
        ].join(' > ');

        results.add(
          SearchResultItem(
            id: res.id,
            title: res.title,
            subtitle: res.fileName.isNotEmpty ? res.fileName : res.type.displayName,
            resultType: SearchResultType.resource,
            resourceType: res.type,
            semester: parentSem,
            subject: parentSub,
            module: parentMod,
            resource: res,
            contextTrail: trail,
          ),
        );
      }
    }

    // Sort results logically:
    // Semesters first, then Subjects, Modules, and Resources
    results.sort((a, b) => a.resultType.index.compareTo(b.resultType.index));

    return results;
  }
}
