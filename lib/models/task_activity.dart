class TaskActivity {
  final String id;
  final String taskId;
  final String userName;
  final String action;
  final String details;
  final DateTime createdAt;

  TaskActivity({
    required this.id,
    required this.taskId,
    required this.userName,
    required this.action,
    required this.details,
    required this.createdAt,
  });

  factory TaskActivity.fromJson(Map<String, dynamic> json) {
    String uName = 'Người dùng';
    if (json['userId'] != null && json['userId'] is Map) {
      uName = json['userId']['fullName'] ?? json['userId']['email'] ?? 'Người dùng';
    }

    return TaskActivity(
      id: json['_id'] ?? '',
      taskId: json['taskId'] ?? '',
      userName: uName,
      action: json['action'] ?? '',
      details: json['details'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}