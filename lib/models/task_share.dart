class TaskShare {
  final String id;
  final String taskId;
  final Map<String, dynamic>? user;
  final String permission;

  TaskShare({
    required this.id,
    required this.taskId,
    this.user,
    required this.permission,
  });

  factory TaskShare.fromJson(Map<String, dynamic> json) {
    return TaskShare(
      id: json['_id'] ?? '',
      taskId: json['taskId'] ?? '',
      user: json['userId'] is Map ? json['userId'] : null,
      permission: json['permission'] ?? 'viewer',
    );
  }
}