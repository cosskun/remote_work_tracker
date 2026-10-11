class WorkLog {
  final String id;
  final String title;
  final DateTime date;
  final int durationMinutes;
  final String category;
  final double hourlyRate;

  WorkLog({
    required this.id,
    required this.title,
    required this.date,
    required this.durationMinutes,
    required this.category,
    required this.hourlyRate,
  });

  double get durationHours => durationMinutes / 60.0;

  String get formattedDuration {
    final hrs = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (hrs > 0 && mins > 0) {
      return '$hrs sa $mins dk';
    } else if (hrs > 0) {
      return '$hrs sa';
    } else {
      return '$mins dk';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'durationMinutes': durationMinutes,
      'category': category,
      'hourlyRate': hourlyRate,
    };
  }

  factory WorkLog.fromJson(Map<String, dynamic> json) {
    return WorkLog(
      id: json['id'] as String,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      durationMinutes: json['durationMinutes'] as int,
      category: json['category'] as String? ?? 'Diğer',
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 150.0,
    );
  }
}
