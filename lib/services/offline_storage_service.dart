import 'dart:convert';
import 'dart:io' as io;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:idb_shim/idb_browser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:study_deck/models/downloaded_resource_model.dart';

/// Abstract storage adapter defining low-level persistence operations.
abstract class OfflineStorageAdapter {
  Future<void> init();
  Future<bool> isSaved(String id);
  Future<void> save({
    required DownloadedResourceModel metadata,
    required Uint8List bytes,
  });
  Future<Uint8List?> getBytes(String id);
  Future<String?> getFilePath(String id);
  Future<DownloadedResourceModel?> getMetadata(String id);
  Future<List<DownloadedResourceModel>> getAllMetadata();
  Future<void> delete(String id);
}

/// Web storage adapter persisting PDF bytes and metadata in browser IndexedDB.
class WebIndexedDbStorageAdapter implements OfflineStorageAdapter {
  static const String dbName = 'studydeck_offline_db';
  static const int dbVersion = 2;
  static const String storeName = 'saved_resources';
  static const String blobStoreName = 'resource_blobs';

  final IdbFactory _idbFactory;
  Database? _db;

  WebIndexedDbStorageAdapter({IdbFactory? idbFactory})
      : _idbFactory = idbFactory ?? idbFactoryBrowser;

  @override
  Future<void> init() async {
    if (_db != null) return;
    _db = await _idbFactory.open(
      dbName,
      version: dbVersion,
      onUpgradeNeeded: (VersionChangeEvent event) {
        final database = event.database;
        if (!database.objectStoreNames.contains(storeName)) {
          database.createObjectStore(storeName, keyPath: 'id');
        }
        if (!database.objectStoreNames.contains(blobStoreName)) {
          database.createObjectStore(blobStoreName, keyPath: 'id');
        }
      },
    );
  }

  Database get db {
    if (_db == null) {
      throw StateError('IndexedDB adapter not initialized. Call init() first.');
    }
    return _db!;
  }

  @override
  Future<bool> isSaved(String id) async {
    await init();
    final txn = db.transaction(storeName, idbModeReadOnly);
    final store = txn.objectStore(storeName);
    final count = await store.count(id);
    await txn.completed;
    return count > 0;
  }

  @override
  Future<void> save({
    required DownloadedResourceModel metadata,
    required Uint8List bytes,
  }) async {
    await init();
    // Multi-store readwrite transaction atomically persisting metadata and binary blob
    final txn = db.transactionList([storeName, blobStoreName], idbModeReadWrite);
    final metaStore = txn.objectStore(storeName);
    final blobStore = txn.objectStore(blobStoreName);

    // 1. Save metadata into storeName without PDF bytes to prevent memory bloat on listing
    final map = metadata.toMap();
    map.remove('bytes');
    await metaStore.put(map);

    // 2. Save binary bytes into dedicated blobStoreName
    await blobStore.put({
      'id': metadata.id,
      'bytes': bytes,
    });

    await txn.completed;
  }

  @override
  Future<Uint8List?> getBytes(String id) async {
    await init();
    // 1. Fast path: retrieve from dedicated blob store
    try {
      final txn = db.transaction(blobStoreName, idbModeReadOnly);
      final blobStore = txn.objectStore(blobStoreName);
      final blobRecord = await blobStore.getObject(id) as Map?;
      await txn.completed;

      if (blobRecord != null) {
        final dynamic rawBytes = blobRecord['bytes'];
        if (rawBytes is Uint8List) return rawBytes;
        if (rawBytes is List<int>) return Uint8List.fromList(rawBytes);
      }
    } catch (_) {
      // Continue to backward-compatible fallback
    }

    // 2. Backward compatibility fallback: check legacy record in storeName
    try {
      final txn = db.transaction(storeName, idbModeReadOnly);
      final store = txn.objectStore(storeName);
      final record = await store.getObject(id) as Map?;
      await txn.completed;

      if (record != null) {
        final dynamic rawBytes = record['bytes'];
        if (rawBytes is Uint8List) return rawBytes;
        if (rawBytes is List<int>) return Uint8List.fromList(rawBytes);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  @override
  Future<String?> getFilePath(String id) async {
    // Web does not have native filesystem paths
    return null;
  }

  @override
  Future<DownloadedResourceModel?> getMetadata(String id) async {
    await init();
    final txn = db.transaction(storeName, idbModeReadOnly);
    final store = txn.objectStore(storeName);
    final record = await store.getObject(id) as Map?;
    await txn.completed;
    if (record == null) return null;
    final map = Map<String, dynamic>.from(record);
    map.remove('bytes');
    return DownloadedResourceModel.fromMap(map);
  }

  @override
  Future<List<DownloadedResourceModel>> getAllMetadata() async {
    await init();
    final txn = db.transaction(storeName, idbModeReadOnly);
    final store = txn.objectStore(storeName);
    final list = <DownloadedResourceModel>[];
    final cursor = store.openCursor(autoAdvance: true);
    await cursor.listen((cv) {
      final map = Map<String, dynamic>.from(cv.value as Map);
      // Strip any legacy bytes in memory immediately to minimize footprint
      map.remove('bytes');
      list.add(DownloadedResourceModel.fromMap(map));
    }).asFuture();
    await txn.completed;
    return list;
  }

  @override
  Future<void> delete(String id) async {
    await init();
    final txn = db.transactionList([storeName, blobStoreName], idbModeReadWrite);
    final metaStore = txn.objectStore(storeName);
    final blobStore = txn.objectStore(blobStoreName);
    await metaStore.delete(id);
    await blobStore.delete(id);
    await txn.completed;
  }
}

/// Native storage adapter for Android application-private storage with atomic manifest writes.
class IoFileStorageAdapter implements OfflineStorageAdapter {
  static const String folderName = 'studydeck_offline_docs';
  static const String manifestFileName = 'manifest.json';
  static const String manifestTmpFileName = 'manifest.json.tmp';
  static const String manifestBakFileName = 'manifest.json.bak';

  final io.Directory? _customBaseDir;
  io.Directory? _offlineDir;
  io.File? _manifestFile;
  io.File? _manifestTmpFile;
  io.File? _manifestBakFile;
  Map<String, dynamic> _manifest = {};

  IoFileStorageAdapter({io.Directory? baseDirectory})
      : _customBaseDir = baseDirectory;

  @override
  Future<void> init() async {
    if (_offlineDir != null) return;
    final docsDir = _customBaseDir ?? await getApplicationDocumentsDirectory();
    final sep = io.Platform.pathSeparator;
    _offlineDir = io.Directory('${docsDir.path}$sep$folderName');
    if (!await _offlineDir!.exists()) {
      await _offlineDir!.create(recursive: true);
    }

    _manifestFile = io.File('${_offlineDir!.path}$sep$manifestFileName');
    _manifestTmpFile = io.File('${_offlineDir!.path}$sep$manifestTmpFileName');
    _manifestBakFile = io.File('${_offlineDir!.path}$sep$manifestBakFileName');

    // 1. Interrupted write recovery
    await _recoverFromInterruptedWrite();

    // 2. Load manifest with multi-stage recovery
    await _loadManifestWithRecovery();
  }

  Future<void> _recoverFromInterruptedWrite() async {
    try {
      if (await _manifestTmpFile!.exists()) {
        final tmpContent = await _manifestTmpFile!.readAsString();
        final decoded = jsonDecode(tmpContent);
        if (decoded is Map<String, dynamic>) {
          bool manifestValid = false;
          if (await _manifestFile!.exists()) {
            try {
              final manifestContent = await _manifestFile!.readAsString();
              final manifestDecoded = jsonDecode(manifestContent);
              manifestValid = manifestDecoded is Map<String, dynamic>;
            } catch (_) {}
          }

          if (!manifestValid) {
            await _safeReplaceFile(_manifestTmpFile!, _manifestFile!);
            return;
          }
        }
        if (await _manifestTmpFile!.exists()) {
          await _manifestTmpFile!.delete();
        }
      }
    } catch (_) {
      try {
        if (await _manifestTmpFile!.exists()) {
          await _manifestTmpFile!.delete();
        }
      } catch (_) {}
    }
  }

  Future<void> _loadManifestWithRecovery() async {
    _manifest = {};
    if (await _manifestFile!.exists()) {
      try {
        final content = await _manifestFile!.readAsString();
        final decoded = jsonDecode(content);
        if (decoded is Map<String, dynamic>) {
          _manifest = Map<String, dynamic>.from(decoded);
          await _createBackupFile(content);
          return;
        }
      } catch (e) {
        debugPrint('Offline manifest corrupted or interrupted, initiating safe recovery: $e');
      }

      // Manifest exists but was corrupted/unparseable; initiate safe recovery
      await _executeManifestRecovery();
    } else {
      // Manifest does not exist; check if backup is available
      if (await _manifestBakFile!.exists()) {
        try {
          final bakContent = await _manifestBakFile!.readAsString();
          final decoded = jsonDecode(bakContent);
          if (decoded is Map<String, dynamic>) {
            _manifest = Map<String, dynamic>.from(decoded);
            await _writeManifest();
            return;
          }
        } catch (_) {}
      }

      _manifest = {};
      await _writeManifest();
    }
  }

  Future<void> _executeManifestRecovery() async {
    final recoveredEntries = <String, dynamic>{};

    // Stage 1: Try reading known-good backup file
    if (await _manifestBakFile!.exists()) {
      try {
        final bakContent = await _manifestBakFile!.readAsString();
        final decoded = jsonDecode(bakContent);
        if (decoded is Map<String, dynamic>) {
          recoveredEntries.addAll(decoded);
        }
      } catch (_) {}
    }

    // Stage 2: Attempt partial regex-based JSON extraction from corrupted manifest
    try {
      final corruptedRaw = await _manifestFile!.readAsString();
      final entryRegex = RegExp(r'"([^"]+)":\s*(\{[^}]+\})');
      for (final match in entryRegex.allMatches(corruptedRaw)) {
        final key = match.group(1);
        final jsonSnippet = match.group(2);
        if (key != null && jsonSnippet != null && !recoveredEntries.containsKey(key)) {
          try {
            final entryDecoded = jsonDecode(jsonSnippet);
            if (entryDecoded is Map<String, dynamic>) {
              recoveredEntries[key] = entryDecoded;
            }
          } catch (_) {}
        }
      }
    } catch (_) {}

    // Stage 3: Scan directory for existing .pdf files to prevent orphaned downloads
    try {
      final entities = _offlineDir!.listSync();
      for (final entity in entities) {
        if (entity is io.File && entity.path.endsWith('.pdf')) {
          final fileName = entity.uri.pathSegments.last;
          final id = fileName.substring(0, fileName.length - 4);
          if (!recoveredEntries.containsKey(id)) {
            recoveredEntries[id] = {
              'id': id,
              'title': 'Offline Document ($id)',
              'fileName': fileName,
              'fileSize': entity.lengthSync(),
              'fileUrl': '',
              'semesterId': '',
              'semesterTitle': 'Saved Offline',
              'subjectId': '',
              'subjectTitle': 'Local Storage',
              'resourceType': 'notes',
              'localPath': entity.path,
              'savedAt': DateTime.now().toIso8601String(),
            };
          }
        }
      }
    } catch (_) {}

    // Stage 4: Preserve corrupted manifest file with timestamp for audit/diagnostics
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sep = io.Platform.pathSeparator;
      final corruptedPreserveFile = io.File(
        '${_offlineDir!.path}${sep}manifest.corrupted.$timestamp.json',
      );
      await _manifestFile!.copy(corruptedPreserveFile.path);
    } catch (_) {}

    _manifest = recoveredEntries;
    await _writeManifest();
  }

  Future<void> _writeManifest() async {
    final jsonStr = jsonEncode(_manifest);
    // Write atomically to temporary file first with flush
    await _manifestTmpFile!.writeAsString(jsonStr, flush: true);

    // Atomically replace manifest.json
    await _safeReplaceFile(_manifestTmpFile!, _manifestFile!);

    // Update backup file
    await _createBackupFile(jsonStr);
  }

  Future<void> _createBackupFile(String content) async {
    try {
      await _manifestBakFile!.writeAsString(content, flush: true);
    } catch (_) {}
  }

  Future<void> _safeReplaceFile(io.File source, io.File target) async {
    try {
      if (await target.exists()) {
        try {
          await target.delete();
        } catch (_) {}
      }
      await source.rename(target.path);
    } catch (_) {
      // Fallback: copy and delete source
      await source.copy(target.path);
      try {
        await source.delete();
      } catch (_) {}
    }
  }

  @override
  Future<bool> isSaved(String id) async {
    await init();
    if (!_manifest.containsKey(id)) return false;
    final file = io.File('${_offlineDir!.path}${io.Platform.pathSeparator}$id.pdf');
    return await file.exists();
  }

  @override
  Future<void> save({
    required DownloadedResourceModel metadata,
    required Uint8List bytes,
  }) async {
    await init();
    final sep = io.Platform.pathSeparator;
    final filePath = '${_offlineDir!.path}$sep${metadata.id}.pdf';
    final file = io.File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    final updatedModel = metadata.copyWith(localPath: filePath);
    _manifest[metadata.id] = updatedModel.toMap();
    await _writeManifest();
  }

  @override
  Future<Uint8List?> getBytes(String id) async {
    await init();
    final sep = io.Platform.pathSeparator;
    final file = io.File('${_offlineDir!.path}$sep$id.pdf');
    if (!await file.exists()) return null;
    return await file.readAsBytes();
  }

  @override
  Future<String?> getFilePath(String id) async {
    await init();
    final sep = io.Platform.pathSeparator;
    final file = io.File('${_offlineDir!.path}$sep$id.pdf');
    if (!await file.exists()) return null;
    return file.path;
  }

  @override
  Future<DownloadedResourceModel?> getMetadata(String id) async {
    await init();
    final raw = _manifest[id] as Map<String, dynamic>?;
    if (raw == null) return null;
    return DownloadedResourceModel.fromMap(raw);
  }

  @override
  Future<List<DownloadedResourceModel>> getAllMetadata() async {
    await init();
    final list = <DownloadedResourceModel>[];
    for (final entry in _manifest.values) {
      if (entry is Map<String, dynamic>) {
        list.add(DownloadedResourceModel.fromMap(entry));
      }
    }
    return list;
  }

  @override
  Future<void> delete(String id) async {
    await init();
    final sep = io.Platform.pathSeparator;
    final file = io.File('${_offlineDir!.path}$sep$id.pdf');
    if (await file.exists()) {
      await file.delete();
    }
    _manifest.remove(id);
    await _writeManifest();
  }
}

/// In-memory storage adapter for unit and widget testing.
class MemoryOfflineStorageAdapter implements OfflineStorageAdapter {
  final Map<String, DownloadedResourceModel> _metadataMap = {};
  final Map<String, Uint8List> _bytesMap = {};

  @override
  Future<void> init() async {}

  @override
  Future<bool> isSaved(String id) async {
    return _metadataMap.containsKey(id) && _bytesMap.containsKey(id);
  }

  @override
  Future<void> save({
    required DownloadedResourceModel metadata,
    required Uint8List bytes,
  }) async {
    _metadataMap[metadata.id] = metadata;
    _bytesMap[metadata.id] = bytes;
  }

  @override
  Future<Uint8List?> getBytes(String id) async {
    return _bytesMap[id];
  }

  @override
  Future<String?> getFilePath(String id) async {
    return null;
  }

  @override
  Future<DownloadedResourceModel?> getMetadata(String id) async {
    return _metadataMap[id];
  }

  @override
  Future<List<DownloadedResourceModel>> getAllMetadata() async {
    return _metadataMap.values.toList();
  }

  @override
  Future<void> delete(String id) async {
    _metadataMap.remove(id);
    _bytesMap.remove(id);
  }
}

/// High-level service managing offline resource downloads, deduplication,
/// offline viewing retrieval, and device file export.
class OfflineStorageService {
  OfflineStorageService({OfflineStorageAdapter? adapter})
      : _adapter = adapter ?? (kIsWeb ? WebIndexedDbStorageAdapter() : IoFileStorageAdapter());

  final OfflineStorageAdapter _adapter;

  static OfflineStorageService? _instance;
  static OfflineStorageService get instance => _instance ??= OfflineStorageService();

  @visibleForTesting
  static void setMockInstance(OfflineStorageService service) {
    _instance = service;
  }

  Future<void> init() => _adapter.init();

  /// Check whether a resource is already stored locally for offline viewing.
  Future<bool> isResourceSaved(String id) => _adapter.isSaved(id);

  /// Save resource PDF bytes and metadata locally for offline access.
  /// Prevents duplication by overwriting matching ID.
  Future<void> saveResource({
    required DownloadedResourceModel metadata,
    required Uint8List bytes,
  }) => _adapter.save(metadata: metadata, bytes: bytes);

  /// Retrieve locally stored PDF bytes for offline rendering.
  Future<Uint8List?> getResourceBytes(String id) => _adapter.getBytes(id);

  /// Retrieve locally stored native file path (Android only).
  Future<String?> getResourceFilePath(String id) => _adapter.getFilePath(id);

  /// Retrieve metadata for a single offline document.
  Future<DownloadedResourceModel?> getMetadata(String id) => _adapter.getMetadata(id);

  /// Retrieve all locally downloaded academic resources metadata.
  Future<List<DownloadedResourceModel>> getAllDownloadedResources() => _adapter.getAllMetadata();

  /// Delete the local offline copy and metadata.
  /// NEVER deletes or affects the remote Firestore document or Cloudinary asset.
  Future<void> deleteResource(String id) => _adapter.delete(id);

  /// Export or save PDF directly to user-accessible device storage.
  /// Confirms success only when the system operation completes and returns a valid Uri.
  Future<bool> exportToDevice({
    required String fileName,
    required Uint8List bytes,
  }) async {
    try {
      final safeName = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';
      final result = await FilePicker.saveFile(
        fileName: safeName,
        bytes: bytes,
        mimeType: 'application/pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      // Confirm operation success
      return result != null;
    } catch (e) {
      debugPrint('Export to device failed: $e');
      return false;
    }
  }
}
