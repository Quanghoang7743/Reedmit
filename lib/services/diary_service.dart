import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

import '../models/diary_entry.dart';

class DiaryService {
  DiaryService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _diaries =>
      _firestore.collection('diaries');

  Stream<List<DiaryEntry>> watchDiaries(String userId) {
    return _diaries.where('userId', isEqualTo: userId).snapshots().map((event) {
      final items = event.docs
          .map((doc) => DiaryEntry.fromMap(doc.id, doc.data()))
          .toList();
      items.sort((a, b) => b.eventTime.compareTo(a.eventTime));
      return items;
    });
  }

  Stream<DiaryEntry?> watchDiary(String diaryId) {
    return _diaries.doc(diaryId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return DiaryEntry.fromMap(doc.id, doc.data()!);
    });
  }

  Future<String> createDiary(DiaryEntry draft) async {
    final now = DateTime.now();
    final doc = _diaries.doc();
    final item = draft.copyWith(id: doc.id, createdAt: now, updatedAt: now);
    await doc.set(item.toMap());
    return doc.id;
  }

  Future<void> updateDiary(DiaryEntry diary) async {
    final item = diary.copyWith(updatedAt: DateTime.now());
    await _diaries.doc(item.id).update(item.toMap());
  }

  Future<String> uploadDiaryImage({
    required File file,
    required String userId,
  }) async {
    final ext = path.extension(file.path).replaceFirst('.', '');
    final safeExt = ext.isEmpty ? 'jpg' : ext;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$safeExt';
    final ref = _storage.ref().child('diary_images/$userId/$fileName');

    final bytes = await file.readAsBytes();
    final metadata = SettableMetadata(
      contentType: _contentTypeFromExtension(safeExt),
    );

    final task = ref.putData(bytes, metadata);
    await task.whenComplete(() {});

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        return await ref.getDownloadURL();
      } catch (_) {
        if (attempt == 2) {
          rethrow;
        }
        await Future<void>.delayed(const Duration(milliseconds: 450));
      }
    }

    throw StateError('Không thể lấy đường dẫn ảnh sau khi tải lên.');
  }

  String _contentTypeFromExtension(String extension) {
    final value = extension.toLowerCase();
    switch (value) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'application/octet-stream';
    }
  }
}
