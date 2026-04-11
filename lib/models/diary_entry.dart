import 'package:cloud_firestore/cloud_firestore.dart';

class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.eventTime,
    required this.reminderEnabled,
    required this.reminderMethods,
    required this.reminderLeadDays,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String content;
  final DateTime eventTime;
  final bool reminderEnabled;
  final List<String> reminderMethods;
  final int reminderLeadDays;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  DiaryEntry copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    DateTime? eventTime,
    bool? reminderEnabled,
    List<String>? reminderMethods,
    int? reminderLeadDays,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      eventTime: eventTime ?? this.eventTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderMethods: reminderMethods ?? this.reminderMethods,
      reminderLeadDays: reminderLeadDays ?? this.reminderLeadDays,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'content': content,
      'eventTime': Timestamp.fromDate(eventTime),
      'reminderEnabled': reminderEnabled,
      'reminderMethods': reminderMethods,
      'reminderLeadDays': reminderLeadDays,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory DiaryEntry.fromMap(String id, Map<String, dynamic> map) {
    DateTime readDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      return DateTime.now();
    }

    return DiaryEntry(
      id: id,
      userId: (map['userId'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      content: (map['content'] ?? '') as String,
      eventTime: readDate(map['eventTime']),
      reminderEnabled: (map['reminderEnabled'] ?? false) as bool,
      reminderMethods: List<String>.from(map['reminderMethods'] ?? const []),
      reminderLeadDays: (map['reminderLeadDays'] ?? 0) as int,
      imageUrl: map['imageUrl'] as String?,
      createdAt: readDate(map['createdAt']),
      updatedAt: readDate(map['updatedAt']),
    );
  }
}
