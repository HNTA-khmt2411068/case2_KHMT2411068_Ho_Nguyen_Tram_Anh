import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/task.dart';
import '../../models/task_share.dart';
import '../../services/task_service.dart';
import '../../services/task_share_service.dart';
import '../../utils/constants.dart';
import '../assignment/assign_task_screen.dart';
import '../sharing/task_sharing_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final String token;
  final Task task;

  const TaskDetailScreen({
    super.key,
    required this.token,
    required this.task,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late String _title;
  late String _description;
  late String _priority;
  late String _status;
  DateTime? _startDate;
  DateTime? _dueDate;

  bool _isLoadingMeta = true;
  bool _hasChanged = false;
  bool _isUpdatingStatus = false;

  String? _currentUserId;
  String? _creatorId;
  String _creatorName = '';
  String? _primaryAssigneeId;
  List<dynamic> _assignees = [];
  List<TaskShare> _shares = [];

  static const Color _bgTaroMilk = Color(0xFFF5F0FF);
  static const Color _taroLight = Color(0xFFEBE0FF);
  static const Color _taroPrimary = Color(0xFF8367D8);
  static const Color _taroDark = Color(0xFF3E2D6B);
  static const Color _taroMuted = Color(0xFF7B6F99);
  static const Color _taroBorder = Color(0xFFE2D7FA);

  @override
  void initState() {
    super.initState();
    _title = widget.task.title;
    _description = widget.task.description;
    _priority = widget.task.priority;
    _status = widget.task.status;
    _startDate = widget.task.startDate;
    _dueDate = widget.task.dueDate;
    _loadTaskContext();
  }

  Future<void> _loadTaskContext() async {
    setState(() => _isLoadingMeta = true);

    String? currentUserId;
    String? creatorId;
    String creatorName = '';
    String? primaryId;
    List<dynamic> assignees = [];
    List<TaskShare> shares = [];

    try {
      final meRes = await http.get(
        Uri.parse('${AppConstants.baseUrl}/auth/me'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (meRes.statusCode == 200) {
        final meData = jsonDecode(meRes.body);
        final userObj = meData['user'] ?? meData;
        currentUserId = (userObj['_id'] ?? userObj['id'])?.toString();
      }

      final taskRes = await http.get(
        Uri.parse('${AppConstants.baseUrl}/tasks/${widget.task.id}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (taskRes.statusCode == 200) {
        final data = jsonDecode(taskRes.body);
        _title = data['title'] ?? _title;
        _description = data['description'] ?? _description;
        _priority = data['priority'] ?? _priority;
        _status = data['status'] ?? _status;
        if (data['startDate'] != null) {
          _startDate = DateTime.tryParse(data['startDate'].toString());
        }
        if (data['dueDate'] != null) {
          _dueDate = DateTime.tryParse(data['dueDate'].toString());
        }

        final rawCreator = data['createdBy'];
        if (rawCreator is Map) {
          creatorId = (rawCreator['_id'] ?? rawCreator['id'])?.toString();
          creatorName =
              rawCreator['fullName'] ?? rawCreator['email'] ?? 'Người tạo';
        } else if (rawCreator != null) {
          creatorId = rawCreator.toString();
        }

        final rawPrimary = data['primaryAssigneeId'];
        if (rawPrimary is Map) {
          primaryId = (rawPrimary['_id'] ?? rawPrimary['id'])?.toString();
        } else if (rawPrimary != null) {
          primaryId = rawPrimary.toString();
        }

        if (data['assigneeIds'] is List) {
          for (var item in data['assigneeIds']) {
            if (item is Map) {
              assignees.add(Map<String, dynamic>.from(item));
            } else if (item != null) {
              assignees.add({'_id': item.toString(), 'fullName': 'Thành viên'});
            }
          }
        }
      }

      shares = await TaskShareService.getTaskShares(widget.token, widget.task.id);
    } catch (e) {
      debugPrint('Lỗi tải thông tin phân quyền task: $e');
    }

    if (mounted) {
      setState(() {
        _currentUserId = currentUserId;
        _creatorId = creatorId;
        _creatorName = creatorName;
        _primaryAssigneeId = primaryId;
        _assignees = assignees;
        _shares = shares;
        _isLoadingMeta = false;
      });
    }
  }

  bool get _isOwner =>
      _currentUserId != null &&
          _creatorId != null &&
          _currentUserId == _creatorId;

  bool get _isPrimaryAssignee =>
      !_isOwner &&
          _currentUserId != null &&
          _primaryAssigneeId != null &&
          _currentUserId == _primaryAssigneeId;

  bool get _isAssignee =>
      !_isOwner &&
          _currentUserId != null &&
          _assignees.any((u) => (u['_id'] ?? u['id'])?.toString() == _currentUserId);

  String? get _sharePermission {
    if (_isOwner || _currentUserId == null) return null;
    for (final s in _shares) {
      final uid = (s.user?['_id'] ?? s.user?['id'])?.toString();
      if (uid == _currentUserId) return s.permission;
    }
    return null;
  }

  bool get _canEditDetails => _isOwner || _sharePermission == 'editor';
  bool get _canUpdateStatus =>
      _isOwner || _isAssignee || _sharePermission == 'editor';
  bool get _canAssign => _isOwner;
  bool get _canShare => _isOwner;
  bool get _canDelete => _isOwner;
  bool get _hasMenuActions =>
      _canEditDetails || _canAssign || _canShare || _canDelete;

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.amber.shade800;
      default:
        return Colors.teal;
    }
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'high':
        return 'Ưu tiên: Cao';
      case 'medium':
        return 'Ưu tiên: Trung bình';
      default:
        return 'Ưu tiên: Thấp';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF13795B);
      case 'in_progress':
        return _taroPrimary;
      default:
        return _taroMuted;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Đã hoàn thành';
      case 'in_progress':
        return 'Đang thực hiện';
      default:
        return 'Chưa thực hiện';
    }
  }

  Future<void> _quickChangeStatus(String newStatus) async {
    if (!_canUpdateStatus || _isUpdatingStatus || _status == newStatus) return;

    final String label = _getStatusText(newStatus);
    final bool isCompleted = newStatus == 'completed';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Xác nhận đổi trạng thái',
          style: TextStyle(color: _taroDark, fontWeight: FontWeight.bold),
        ),
        content: Text(
          isCompleted
              ? 'Chuyển sang "$label" sẽ gửi email thông báo hoàn thành công việc. Bạn có chắc chắn không?'
              : 'Bạn có chắc muốn chuyển trạng thái công việc sang "$label" không?',
          style: const TextStyle(color: _taroMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: _taroMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _taroPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isUpdatingStatus = true);
    try {
      final res = await http.patch(
        Uri.parse('${AppConstants.baseUrl}/tasks/${widget.task.id}/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'status': newStatus}),
      );
      final data = jsonDecode(res.body);
      if (mounted) {
        if (res.statusCode == 200) {
          setState(() {
            _status = newStatus;
            _hasChanged = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Đã cập nhật trạng thái!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Không thể đổi trạng thái!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  void _showActivitiesDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return FutureBuilder<List<dynamic>>(
          future: TaskService.getTaskActivities(widget.token, widget.task.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 300,
                child: Center(
                  child: CircularProgressIndicator(color: _taroPrimary),
                ),
              );
            }

            final activities = snapshot.data ?? [];

            return Container(
              height: 420,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: _taroBorder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const Row(
                    children: [
                      Icon(Icons.history_rounded, color: _taroPrimary, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Lịch sử hoạt động',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _taroDark,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFF0E8FF), height: 22),
                  Expanded(
                    child: activities.isEmpty
                        ? const Center(
                      child: Text(
                        'Chưa có lịch sử hoạt động.',
                        style: TextStyle(color: _taroMuted),
                      ),
                    )
                        : ListView.builder(
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        final item = activities[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF8FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _taroBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _taroLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.history_toggle_off_rounded,
                                  color: _taroPrimary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['action'] ?? 'Thao tác',
                                      style: const TextStyle(
                                        color: _taroDark,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item['createdAt'] != null
                                          ? item['createdAt']
                                          .toString()
                                          .split('T')[0]
                                          : '',
                                      style: const TextStyle(
                                        color: _taroMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDialog() {
    if (!_canEditDetails) return;
    final titleController = TextEditingController(text: _title);
    final descController = TextEditingController(text: _description);
    String editPriority = _priority;
    String editStatus = _status;
    DateTime? editStartDate = _startDate;
    DateTime? editDueDate = _dueDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Chỉnh sửa công việc',
                style: TextStyle(
                  color: _taroDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Tên công việc',
                        filled: true,
                        fillColor: const Color(0xFFFAF8FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Mô tả',
                        filled: true,
                        fillColor: const Color(0xFFFAF8FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: editPriority,
                      decoration: InputDecoration(
                        labelText: 'Mức độ ưu tiên',
                        filled: true,
                        fillColor: const Color(0xFFFAF8FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'low',
                          child: Text('Thấp (Low)'),
                        ),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Text('Trung bình (Medium)'),
                        ),
                        DropdownMenuItem(
                          value: 'high',
                          child: Text('Cao (High)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => editPriority = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: editStatus,
                      decoration: InputDecoration(
                        labelText: 'Trạng thái',
                        filled: true,
                        fillColor: const Color(0xFFFAF8FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'todo',
                          child: Text('Chưa thực hiện'),
                        ),
                        DropdownMenuItem(
                          value: 'in_progress',
                          child: Text('Đang thực hiện'),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text('Đã hoàn thành'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => editStatus = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _taroPrimary,
                              side: const BorderSide(color: _taroBorder),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.calendar_today, size: 15),
                            label: Text(
                              editStartDate == null
                                  ? 'Bắt đầu'
                                  : '${editStartDate!.year}-${editStartDate!.month.toString().padLeft(2, '0')}-${editStartDate!.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: editStartDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setDialogState(() => editStartDate = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _taroPrimary,
                              side: const BorderSide(color: _taroBorder),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.event, size: 15),
                            label: Text(
                              editDueDate == null
                                  ? 'Hạn chót'
                                  : '${editDueDate!.year}-${editDueDate!.month.toString().padLeft(2, '0')}-${editDueDate!.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: editDueDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setDialogState(() => editDueDate = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: _taroMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _taroPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng nhập tên công việc!'),
                        ),
                      );
                      return;
                    }

                    final res = await TaskService.updateTask(
                      widget.token,
                      widget.task.id,
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      priority: editPriority,
                      status: editStatus,
                      startDate: editStartDate,
                      dueDate: editDueDate,
                    );

                    if (mounted) {
                      Navigator.pop(context);
                      if (res['success'] == true) {
                        setState(() {
                          _title = titleController.text.trim();
                          _description = descController.text.trim();
                          _priority = editPriority;
                          _status = editStatus;
                          _startDate = editStartDate;
                          _dueDate = editDueDate;
                          _hasChanged = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cập nhật công việc thành công!'),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              res['message'] ?? 'Cập nhật thất bại',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete() {
    if (!_canDelete) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Xác nhận xóa',
          style: TextStyle(color: _taroDark, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn xóa công việc này không?',
          style: TextStyle(color: _taroMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy', style: TextStyle(color: _taroMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final res =
              await TaskService.deleteTask(widget.token, widget.task.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(res['message'] ?? 'Đã xóa công việc')),
              );
              Navigator.pop(context, true);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBanner() {
    if (_isLoadingMeta) return const SizedBox.shrink();

    IconData icon;
    String text;
    Color bgColor;
    Color borderColor;
    Color textColor;

    if (_isOwner) {
      icon = Icons.verified_user_rounded;
      text = 'Bạn là người tạo công việc này (Toàn quyền quản lý)';
      bgColor = const Color(0xFFE6F7F2);
      borderColor = const Color(0xFFB7EAD9);
      textColor = const Color(0xFF13795B);
    } else if (_isPrimaryAssignee) {
      icon = Icons.star_rounded;
      text = 'Bạn là người phụ trách chính công việc này';
      bgColor = const Color(0xFFFFF4DB);
      borderColor = const Color(0xFFF7DC99);
      textColor = const Color(0xFF9A6700);
    } else if (_isAssignee) {
      icon = Icons.engineering_rounded;
      text = 'Bạn được giao thực hiện công việc này';
      bgColor = const Color(0xFFE8F1FF);
      borderColor = const Color(0xFFC2DAFF);
      textColor = const Color(0xFF1D5BBF);
    } else if (_sharePermission == 'editor') {
      icon = Icons.edit_note_rounded;
      text = 'Được chia sẻ với bạn • Quyền: Chỉnh sửa';
      bgColor = _taroLight;
      borderColor = _taroBorder;
      textColor = _taroDark;
    } else {
      icon = Icons.visibility_rounded;
      text =
      'Chế độ chỉ xem • Được chia sẻ bởi ${_creatorName.isNotEmpty ? _creatorName : 'người tạo'}';
      bgColor = Colors.white;
      borderColor = _taroBorder;
      textColor = _taroMuted;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDE6FC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x128367D8),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDatePill({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _taroBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _taroLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: _taroPrimary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: _taroMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _taroDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(_priority);
    final statusColor = _getStatusColor(_status);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _hasChanged);
        }
      },
      child: Scaffold(
        backgroundColor: _bgTaroMilk,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _taroDark,
            ),
            onPressed: () => Navigator.pop(context, _hasChanged),
          ),
          title: const Text(
            'Chi tiết công việc',
            style: TextStyle(
              color: _taroDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _showActivitiesDialog,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _taroBorder),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: _taroPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            if (!_isLoadingMeta && _hasMenuActions)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _taroBorder),
                  ),
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: _taroDark,
                      size: 20,
                    ),
                    tooltip: 'Thao tác',
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _showEditDialog();
                      } else if (value == 'assign') {
                        final changed = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AssignTaskScreen(
                              token: widget.token,
                              taskId: widget.task.id,
                              taskTitle: _title,
                            ),
                          ),
                        );
                        if (changed == true) {
                          _hasChanged = true;
                          _loadTaskContext();
                        }
                      } else if (value == 'share') {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskSharingScreen(
                              token: widget.token,
                              taskId: widget.task.id,
                              taskTitle: _title,
                            ),
                          ),
                        );
                        _loadTaskContext();
                      } else if (value == 'delete') {
                        _confirmDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      if (_canEditDetails)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, color: _taroPrimary, size: 20),
                              SizedBox(width: 10),
                              Text('Chỉnh sửa'),
                            ],
                          ),
                        ),
                      if (_canAssign)
                        const PopupMenuItem(
                          value: 'assign',
                          child: Row(
                            children: [
                              Icon(Icons.person_add_alt_1_rounded, color: Colors.blue, size: 20),
                              SizedBox(width: 10),
                              Text('Giao việc'),
                            ],
                          ),
                        ),
                      if (_canShare)
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share_rounded, color: Colors.teal, size: 20),
                              SizedBox(width: 10),
                              Text('Chia sẻ'),
                            ],
                          ),
                        ),
                      if (_canDelete) ...[
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Xóa công việc',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
          children: [
            _buildRoleBanner(),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _taroDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getPriorityText(_priority),
                          style: TextStyle(
                            color: priorityColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(_status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!_isLoadingMeta && _canUpdateStatus) ...[
                    const Divider(color: Color(0xFFF0E8FF), height: 26),
                    const Text(
                      'Cập nhật tiến độ nhanh',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _taroMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final item in [
                          {'key': 'todo', 'label': 'Chưa làm'},
                          {'key': 'in_progress', 'label': 'Đang làm'},
                          {'key': 'completed', 'label': 'Hoàn thành'},
                        ])
                          ChoiceChip(
                            label: Text(item['label']!),
                            selected: _status == item['key'],
                            selectedColor: _taroLight,
                            backgroundColor: const Color(0xFFFAF8FF),
                            checkmarkColor: _taroPrimary,
                            labelStyle: TextStyle(
                              color: _status == item['key']
                                  ? _taroDark
                                  : _taroMuted,
                              fontWeight: _status == item['key']
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                            side: BorderSide(
                              color: _status == item['key']
                                  ? _taroPrimary
                                  : _taroBorder,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (_) => _quickChangeStatus(item['key']!),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        color: _taroPrimary,
                        size: 19,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Mô tả & Thời hạn',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _taroDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _description.isEmpty ? 'Không có mô tả.' : _description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _taroMuted,
                      height: 1.45,
                    ),
                  ),
                  if (_startDate != null || _dueDate != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (_startDate != null)
                          Expanded(
                            child: _buildDatePill(
                              icon: Icons.calendar_today_rounded,
                              label: 'Ngày bắt đầu',
                              value: _startDate.toString().split(' ')[0],
                            ),
                          ),
                        if (_startDate != null && _dueDate != null)
                          const SizedBox(width: 10),
                        if (_dueDate != null)
                          Expanded(
                            child: _buildDatePill(
                              icon: Icons.event_available_rounded,
                              label: 'Hạn hoàn thành',
                              value: _dueDate.toString().split(' ')[0],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (!_isLoadingMeta)
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.groups_rounded,
                          color: _taroPrimary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Thành viên tham gia',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _taroDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_creatorName.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF8FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _taroBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.workspace_premium_rounded,
                              color: _taroPrimary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Người tạo: ',
                              style: TextStyle(fontSize: 13, color: _taroMuted),
                            ),
                            Expanded(
                              child: Text(
                                _creatorName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _taroDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Text(
                      'Người thực hiện',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _taroDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_assignees.isEmpty)
                      const Text(
                        'Chưa giao cho thành viên nào.',
                        style: TextStyle(color: _taroMuted, fontSize: 13),
                      )
                    else
                      ..._assignees.map((u) {
                        final uid = (u['_id'] ?? u['id'])?.toString();
                        final isPrim = uid == _primaryAssigneeId;
                        final name = u['fullName'] ?? u['email'] ?? 'Thành viên';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: _taroLight,
                                child: Text(
                                  name.toString().isNotEmpty
                                      ? name.toString()[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _taroPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  name.toString(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isPrim
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: _taroDark,
                                  ),
                                ),
                              ),
                              if (isPrim)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF4DB),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Phụ trách chính ⭐',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF9A6700),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    if (_shares.isNotEmpty) ...[
                      const Divider(color: Color(0xFFF0E8FF), height: 22),
                      const Text(
                        'Người được chia sẻ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _taroDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._shares.map((s) {
                        final name = s.user?['fullName'] ??
                            s.user?['email'] ??
                            'Thành viên';
                        final isEditor = s.permission == 'editor';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: const Color(0xFFF1EEF8),
                                child: Text(
                                  name.toString().isNotEmpty
                                      ? name.toString()[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _taroMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  name.toString(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: _taroDark,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isEditor
                                      ? _taroLight
                                      : const Color(0xFFF1EEF8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isEditor ? 'Chỉnh sửa' : 'Chỉ xem',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isEditor ? _taroDark : _taroMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}