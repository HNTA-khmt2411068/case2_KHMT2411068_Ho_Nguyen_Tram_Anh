class Task {
  final String id;
  final String title;
  final String description;
  final String priority;
  final String status;
  final String? createdBy;
  final DateTime? dueDate;
  final DateTime? startDate;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.createdBy,
    this.dueDate,
    this.startDate,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'todo',
      createdBy: json['createdBy'] is Map ? json['createdBy']['_id'] : json['createdBy'],
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'].toString()) : null,
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'].toString()) : null,
    );
  }
}