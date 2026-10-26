class TaskShare {
  final String id;
  final String taskId;
  final String userId;
  final String permission;

  TaskShare({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.permission,
  });

  factory TaskShare.fromJson(Map<String, dynamic> json) {
    return TaskShare(
      id: json['_id'] ?? '',
      taskId: json['taskId'] is Map ? json['taskId']['_id'] : (json['taskId'] ?? ''),
      userId: json['userId'] is Map ? json['userId']['_id'] : (json['userId'] ?? ''),
      permission: json['permission'] ?? 'viewer',
    );
  }
}