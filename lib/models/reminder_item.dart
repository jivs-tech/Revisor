import 'dart:convert';

enum ReminderType { task, date }

class ReminderItem {
  final String id;
  final String title;
  final ReminderType type;
  final DateTime? dateTime; // Null for tasks without specific time
  bool isCompleted;
  bool isImportant;
  final DateTime createdAt;

  ReminderItem({
    required this.id,
    required this.title,
    required this.type,
    this.dateTime,
    this.isCompleted = false,
    this.isImportant = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.index,
      'dateTime': dateTime?.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'isImportant': isImportant ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReminderItem.fromMap(Map<String, dynamic> map) {
    return ReminderItem(
      id: map['id'],
      title: map['title'],
      type: ReminderType.values[map['type']],
      dateTime: map['dateTime'] != null ? DateTime.parse(map['dateTime']) : null,
      isCompleted: (map['isCompleted'] ?? 0) == 1,
      isImportant: (map['isImportant'] ?? 0) == 1,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  String toJson() => json.encode(toMap());

  factory ReminderItem.fromJson(String source) => ReminderItem.fromMap(json.decode(source));
}
