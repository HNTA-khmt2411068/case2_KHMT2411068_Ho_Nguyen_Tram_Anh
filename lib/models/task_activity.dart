class TaskActivity {
  final String id;
  final String taskId;
  final String userId;
  final String userName;
  final String action;
  final Map<String, dynamic> details;
  final DateTime? createdAt;

  TaskActivity({
    required this.id,
    required this.taskId,
    required this.userId,
    this.userName = '',
    required this.action,
    this.details = const {},
    this.createdAt,
  });

  factory TaskActivity.fromJson(Map<String, dynamic> json) {
    final userObj = json['userId'];
    String parsedUserId = '';
    String parsedUserName = '';

    if (userObj is Map<String, dynamic>) {
      parsedUserId = (userObj['_id'] ?? userObj['id'] ?? '').toString();
      parsedUserName = (userObj['fullName'] ?? '').toString();
    } else if (userObj != null) {
      parsedUserId = userObj.toString();
    }

    return TaskActivity(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      taskId: (json['taskId'] ?? '').toString(),
      userId: parsedUserId,
      userName: parsedUserName,
      action: (json['action'] ?? '').toString(),
      details: json['details'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['details'])
          : {},
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}