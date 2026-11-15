import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../utils/constants.dart';
import '../profile/profile_screen.dart';
import '../notifications/notification_screen.dart';
import 'task_create_screen.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  final String token;
  const TaskListScreen({super.key, required this.token});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  Map<String, String> _taskRoles = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilterStatus = 'all';
  String _selectedRoleScope = 'all';

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedRoleScope != 'all') count++;
    if (_selectedFilterStatus != 'all') count++;
    return count;
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'owner':
        return 'Của tôi';
      case 'assigned':
        return 'Được giao';
      case 'shared':
        return 'Được chia sẻ';
      default:
        return 'Tất cả vai trò';
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'todo':
        return 'Chưa làm';
      case 'in_progress':
        return 'Đang làm';
      case 'completed':
        return 'Hoàn thành';
      default:
        return 'Tất cả trạng thái';
    }
  }

  void _fetchTasks() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final tasks = await TaskService.getTasks(widget.token);
      final Map<String, String> roleMap = {};

      try {
        final rawRes = await http.get(
          Uri.parse('${AppConstants.baseUrl}/tasks'),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );
        if (rawRes.statusCode == 200) {
          final List<dynamic> rawList = jsonDecode(rawRes.body);
          for (var item in rawList) {
            if (item is Map) {
              final id = (item['_id'] ?? item['id'])?.toString();
              final role = item['userRole']?.toString();
              if (id != null && role != null) {
                roleMap[id] = role;
              }
            }
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _tasks = tasks;
          _taskRoles = roleMap;
          _applyFilter();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải công việc: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilter() {
    setState(() {
      _filteredTasks = _tasks.where((task) {
        final matchesSearch =
        task.title.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesStatus = _selectedFilterStatus == 'all' ||
            task.status == _selectedFilterStatus;

        final role = _taskRoles[task.id] ?? 'owner';
        bool matchesRole = true;
        if (_selectedRoleScope == 'owner') {
          matchesRole = role == 'owner';
        } else if (_selectedRoleScope == 'assigned') {
          matchesRole = role == 'primary_assignee' || role == 'assignee';
        } else if (_selectedRoleScope == 'shared') {
          matchesRole = role == 'editor' || role == 'viewer';
        }

        return matchesSearch && matchesStatus && matchesRole;
      }).toList();
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  MediaQuery.of(ctx).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bộ lọc công việc',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_activeFilterCount > 0)
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                _selectedRoleScope = 'all';
                                _selectedFilterStatus = 'all';
                              });
                              _applyFilter();
                            },
                            child: const Text('Đặt lại'),
                          ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Vai trò của bạn',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final role in ['all', 'owner', 'assigned', 'shared'])
                          ChoiceChip(
                            label: Text(_getRoleLabel(role)),
                            selected: _selectedRoleScope == role,
                            onSelected: (selected) {
                              if (selected) {
                                setSheetState(() => _selectedRoleScope = role);
                                _applyFilter();
                              }
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Trạng thái thực hiện',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final st in [
                          'all',
                          'todo',
                          'in_progress',
                          'completed'
                        ])
                          FilterChip(
                            label: Text(_getStatusLabel(st)),
                            selected: _selectedFilterStatus == st,
                            onSelected: (selected) {
                              if (selected) {
                                setSheetState(() => _selectedFilterStatus = st);
                                _applyFilter();
                              }
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Xem ${_filteredTasks.length} công việc'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

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

  Widget _buildRoleBadge(String taskId) {
    final role = _taskRoles[taskId];
    if (role == null) return const SizedBox.shrink();

    String label;
    Color bg;
    Color fg;

    switch (role) {
      case 'owner':
        label = 'Của tôi';
        bg = Colors.teal.shade50;
        fg = Colors.teal.shade800;
        break;
      case 'primary_assignee':
        label = 'Phụ trách chính ⭐';
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        break;
      case 'assignee':
        label = 'Được giao';
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        break;
      case 'editor':
        label = 'Chia sẻ • Sửa';
        bg = Colors.purple.shade50;
        fg = Colors.purple.shade800;
        break;
      default:
        label = 'Chia sẻ • Xem';
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
    }

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> activeLabels = [];
    if (_selectedRoleScope != 'all') {
      activeLabels.add(_getRoleLabel(_selectedRoleScope));
    }
    if (_selectedFilterStatus != 'all') {
      activeLabels.add(_getStatusLabel(_selectedFilterStatus));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách công việc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: 'Thông báo',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationScreen(token: widget.token),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Hồ sơ',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProfileScreen(token: widget.token, tasks: _tasks),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm công việc...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _searchQuery = '';
                          _applyFilter();
                        },
                      )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),
                    ),
                    onChanged: (val) {
                      _searchQuery = val;
                      _applyFilter();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Material(
                      color: _activeFilterCount > 0
                          ? Colors.indigo.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _showFilterBottomSheet,
                        child: Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _activeFilterCount > 0
                                  ? Colors.indigo
                                  : Colors.grey.shade400,
                            ),
                          ),
                          child: Icon(
                            Icons.tune,
                            color: _activeFilterCount > 0
                                ? Colors.indigo
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    if (_activeFilterCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: CircleAvatar(
                          radius: 9,
                          backgroundColor: Colors.indigo,
                          child: Text(
                            '$_activeFilterCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (activeLabels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
              child: Row(
                children: [
                  Icon(Icons.filter_alt,
                      size: 15, color: Colors.indigo.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Đang lọc: ${activeLabels.join(' • ')}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _selectedRoleScope = 'all';
                      _selectedFilterStatus = 'all';
                      _applyFilter();
                    },
                    child: const Text(
                      'Xóa lọc',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _filteredTasks.isEmpty
                ? const Center(
                child: Text('Không tìm thấy công việc phù hợp!'))
                : RefreshIndicator(
              onRefresh: () async => _fetchTasks(),
              child: ListView.builder(
                itemCount: _filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = _filteredTasks[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: ListTile(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskDetailScreen(
                              token: widget.token,
                              task: task,
                            ),
                          ),
                        );
                        if (result == true) {
                          _fetchTasks();
                        }
                      },
                      title: Text(task.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.description.isEmpty
                                ? 'Chưa có mô tả'
                                : task.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          _buildRoleBadge(task.id),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(
                            label: Text(task.priority,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12)),
                            backgroundColor:
                            _getPriorityColor(task.priority),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right,
                              color: Colors.grey),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => TaskCreateScreen(token: widget.token)),
          );
          if (result == true) {
            _fetchTasks();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}