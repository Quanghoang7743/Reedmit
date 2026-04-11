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
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
