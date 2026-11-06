class TaskShare {
  final String id;
  final String taskId;
  final String userId;
  final String userName;
  final String userEmail;
  final String permission;

  TaskShare({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.permission,
  });

  factory TaskShare.fromJson(Map<String, dynamic> json) {
    String uId = '';
    String name = '';
    String email = '';

    if (json['userId'] is Map) {
      final userMap = json['userId'] as Map<String, dynamic>;
      uId = userMap['_id']?.toString() ?? '';
      name = userMap['fullName']?.toString() ?? '';
      email = userMap['email']?.toString() ?? '';
    } else {
      uId = json['userId']?.toString() ?? '';
    }

    return TaskShare(
      id: json['_id']?.toString() ?? '',
      taskId: json['taskId']?.toString() ?? '',
      userId: uId,
      userName: name,
      userEmail: email,
      permission: json['permission']?.toString() ?? 'viewer',
    );
  }
}