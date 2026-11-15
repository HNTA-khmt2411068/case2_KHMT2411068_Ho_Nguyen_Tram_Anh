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
      _currentUserId != null && _creatorId != null && _currentUserId == _creatorId;

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
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      default:
        return Colors.grey;
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
        title: const Text('Xác nhận đổi trạng thái'),
        content: Text(
          isCompleted
              ? 'Chuyển sang "$label" sẽ gửi email thông báo hoàn thành công việc. Bạn có chắc chắn không?'
              : 'Bạn có chắc muốn chuyển trạng thái công việc sang "$label" không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FutureBuilder<List<dynamic>>(
          future: TaskService.getTaskActivities(widget.token, widget.task.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final activities = snapshot.data ?? [];

            return Container(
              height: 400,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📜 Lịch sử hoạt động',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  Expanded(
                    child: activities.isEmpty
                        ? const Center(child: Text('Chưa có lịch sử hoạt động.'))
                        : ListView.builder(
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        final item = activities[index];
                        return ListTile(
                          leading: const Icon(Icons.history_toggle_off,
                              color: Colors.teal),
                          title: Text(item['action'] ?? 'Thao tác'),
                          subtitle: Text(
                            item['createdAt'] != null
                                ? item['createdAt']
                                .toString()
                                .split('T')[0]
                                : '',
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
              title: const Text('Chỉnh sửa công việc'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration:
                      const InputDecoration(labelText: 'Tên công việc'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Mô tả'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: editPriority,
                      decoration:
                      const InputDecoration(labelText: 'Mức độ ưu tiên'),
                      items: const [
                        DropdownMenuItem(
                            value: 'low', child: Text('Thấp (Low)')),
                        DropdownMenuItem(
                            value: 'medium',
                            child: Text('Trung bình (Medium)')),
                        DropdownMenuItem(
                            value: 'high', child: Text('Cao (High)')),
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
                      decoration:
                      const InputDecoration(labelText: 'Trạng thái'),
                      items: const [
                        DropdownMenuItem(
                            value: 'todo', child: Text('Chưa thực hiện')),
                        DropdownMenuItem(
                            value: 'in_progress',
                            child: Text('Đang thực hiện')),
                        DropdownMenuItem(
                            value: 'completed', child: Text('Đã hoàn thành')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => editStatus = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
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
                            icon: const Icon(Icons.event, size: 16),
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
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Vui lòng nhập tên công việc!')),
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
                              content: Text('Cập nhật công việc thành công!')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                              Text(res['message'] ?? 'Cập nhật thất bại')),
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
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa công việc này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
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
      icon = Icons.verified_user;
      text = 'Bạn là người tạo công việc này (Toàn quyền quản lý)';
      bgColor = Colors.teal.shade50;
      borderColor = Colors.teal.shade200;
      textColor = Colors.teal.shade900;
    } else if (_isPrimaryAssignee) {
      icon = Icons.star;
      text = 'Bạn là người phụ trách chính công việc này';
      bgColor = Colors.amber.shade50;
      borderColor = Colors.amber.shade300;
      textColor = Colors.amber.shade900;
    } else if (_isAssignee) {
      icon = Icons.engineering;
      text = 'Bạn được giao thực hiện công việc này';
      bgColor = Colors.blue.shade50;
      borderColor = Colors.blue.shade200;
      textColor = Colors.blue.shade900;
    } else if (_sharePermission == 'editor') {
      icon = Icons.edit_note;
      text = 'Được chia sẻ với bạn • Quyền: Chỉnh sửa';
      bgColor = Colors.purple.shade50;
      borderColor = Colors.purple.shade200;
      textColor = Colors.purple.shade900;
    } else {
      icon = Icons.visibility;
      text =
      'Chế độ chỉ xem • Được chia sẻ bởi ${_creatorName.isNotEmpty ? _creatorName : 'người tạo'}';
      bgColor = Colors.grey.shade100;
      borderColor = Colors.grey.shade300;
      textColor = Colors.grey.shade800;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: 8),
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _hasChanged);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết công việc'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasChanged),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.history, color: Colors.teal),
              tooltip: 'Lịch sử hoạt động',
              onPressed: _showActivitiesDialog,
            ),
            if (!_isLoadingMeta && _hasMenuActions)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
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
                          Icon(Icons.edit, color: Colors.orange, size: 20),
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
                          Icon(Icons.person_add, color: Colors.blue, size: 20),
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
                          Icon(Icons.share, color: Colors.purple, size: 20),
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
                          Icon(Icons.delete, color: Colors.red, size: 20),
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
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              _buildRoleBanner(),
              Text(
                _title,
                style:
                const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Chip(
                    label: Text(
                      'Ưu tiên: ${_priority.toUpperCase()}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: _getPriorityColor(_priority),
                  ),
                  Chip(
                    label: Text(
                      _getStatusText(_status),
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: _getStatusColor(_status),
                  ),
                ],
              ),
              if (!_isLoadingMeta && _canUpdateStatus) ...[
                const SizedBox(height: 16),
                const Text(
                  'Cập nhật tiến độ nhanh:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Chưa làm'),
                      selected: _status == 'todo',
                      onSelected: (_) => _quickChangeStatus('todo'),
                    ),
                    ChoiceChip(
                      label: const Text('Đang làm'),
                      selected: _status == 'in_progress',
                      onSelected: (_) => _quickChangeStatus('in_progress'),
                    ),
                    ChoiceChip(
                      label: const Text('Hoàn thành'),
                      selected: _status == 'completed',
                      onSelected: (_) => _quickChangeStatus('completed'),
                    ),
                  ],
                ),
              ],
              const Divider(height: 30),
              const Text(
                'Mô tả công việc:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                _description.isEmpty ? 'Không có mô tả.' : _description,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 20),
              if (_startDate != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    '📅 Ngày bắt đầu: ${_startDate.toString().split(' ')[0]}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              if (_dueDate != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    '⏰ Hạn hoàn thành: ${_dueDate.toString().split(' ')[0]}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              if (!_isLoadingMeta) ...[
                const Divider(height: 28),
                if (_creatorName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      '👑 Người tạo: $_creatorName',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                const Text(
                  '👥 Người thực hiện:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 6),
                if (_assignees.isEmpty)
                  const Text('Chưa giao cho thành viên nào.',
                      style: TextStyle(color: Colors.grey))
                else
                  ..._assignees.map((u) {
                    final uid = (u['_id'] ?? u['id'])?.toString();
                    final isPrim = uid == _primaryAssigneeId;
                    final name = u['fullName'] ?? u['email'] ?? 'Thành viên';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0, left: 8.0),
                      child: Text(
                        isPrim
                            ? '• $name (Phụ trách chính ⭐)'
                            : '• $name',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                          isPrim ? FontWeight.w600 : FontWeight.normal,
                          color: isPrim ? Colors.amber[900] : Colors.black87,
                        ),
                      ),
                    );
                  }),
                if (_shares.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    '🔗 Người được chia sẻ:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  ..._shares.map((s) {
                    final name = s.user?['fullName'] ??
                        s.user?['email'] ??
                        'Thành viên';
                    final permLabel =
                    s.permission == 'editor' ? 'Chỉnh sửa' : 'Chỉ xem';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0, left: 8.0),
                      child: Text(
                        '• $name ($permLabel)',
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}