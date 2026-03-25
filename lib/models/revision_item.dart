class ItemStats {
  int attempts;
  int successfulRecalls;

  ItemStats({this.attempts = 0, this.successfulRecalls = 0});

  Map<String, dynamic> toMap() => {
    'attempts': attempts,
    'successfulRecalls': successfulRecalls,
  };

  factory ItemStats.fromMap(Map<String, dynamic> map) => ItemStats(
    attempts: map['attempts'] ?? 0,
    successfulRecalls: map['successfulRecalls'] ?? 0,
  );
}

class RevisionHistoryEntry {
  final DateTime date;
  final bool isSuccess;

  RevisionHistoryEntry({required this.date, required this.isSuccess});

  Map<String, dynamic> toMap() => {
    'date': date.toIso8601String(),
    'isSuccess': isSuccess,
  };

  factory RevisionHistoryEntry.fromMap(Map<String, dynamic> map) {
    return RevisionHistoryEntry(
      date: DateTime.parse(map['date']),
      isSuccess: map['isSuccess'] ?? true,
    );
  }
}

class RevisionItem {
  String id;
  String title;
  String? description; // null for simple topics
  String type; // 'flashcard' or 'topic'
  String? folder; // 'null' implies root/uncategorized
  DateTime createdAt;
  DateTime nextRevisionDate;
  int intervalIndex;
  ItemStats stats;
  List<RevisionHistoryEntry> revisionHistory;

  RevisionItem({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.folder,
    required this.createdAt,
    required this.nextRevisionDate,
    this.intervalIndex = 0,
    ItemStats? stats,
    List<RevisionHistoryEntry>? revisionHistory,
  }) : stats = stats ?? ItemStats(),
       revisionHistory = revisionHistory ?? [];

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type,
    'folder': folder,
    'createdAt': createdAt.toIso8601String(),
    'nextRevisionDate': nextRevisionDate.toIso8601String(),
    'intervalIndex': intervalIndex,
    'stats': stats.toMap(),
    'revisionHistory': revisionHistory.map((e) => e.toMap()).toList(),
  };

  factory RevisionItem.fromMap(Map<String, dynamic> map) => RevisionItem(
    id: map['id'],
    title: map['title'],
    description: map['description'],
    type: map['type'] ?? 'flashcard',
    folder: map['folder'],
    createdAt: DateTime.parse(map['createdAt']),
    nextRevisionDate: DateTime.parse(map['nextRevisionDate']),
    intervalIndex: map['intervalIndex'] ?? 0,
    stats: ItemStats.fromMap(map['stats'] ?? {}),
    revisionHistory: (map['revisionHistory'] as List?)?.map((e) {
      if (e is Map<String, dynamic>) return RevisionHistoryEntry.fromMap(e);
      // Legacy support for plain strings
      return RevisionHistoryEntry(date: DateTime.parse(e.toString()), isSuccess: true);
    }).toList() ?? [],
  );
}
