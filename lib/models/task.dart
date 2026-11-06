class Task {
  final String id;
  final String title;
  final String? description;
  final String priority;
  final String status;
  final DateTime? startDate;
  final DateTime? dueDate;
  final dynamic rawCreatedBy;
  final String? createdByName;
  final List<dynamic>? assigneeIds;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    this.startDate,
    this.dueDate,
    this.rawCreatedBy,
    this.createdByName,
    this.assigneeIds,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    String? cName;
    if (json['createdBy'] is Map) {
      cName = json['createdBy']['fullName'] ?? json['createdBy']['name'];
    } else if (json['createdBy'] is String) {
      cName = json['createdBy'];
    }

    return Task(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: json['title'] ?? '',
      description: json['description'],
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'todo',
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      rawCreatedBy: json['createdBy'],
      createdByName: cName,
      assigneeIds: json['assigneeIds'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'startDate': startDate?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
    };
  }
}