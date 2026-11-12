import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import '../profile/profile_screen.dart';
import '../notifications/notification_screen.dart';
import 'task_create_screen.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  final String token;
  const TaskListScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  void _fetchTasks() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final tasks = await TaskService.getTasks(widget.token);
      if (mounted) {
        setState(() {
          _tasks = tasks;
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
        final matchesSearch = task.title.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesStatus = _selectedFilterStatus == 'all' || task.status == _selectedFilterStatus;
        return matchesSearch && matchesStatus;
      }).toList();
    });
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

  @override
  Widget build(BuildContext context) {
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
                  builder: (context) => ProfileScreen(token: widget.token, tasks: _tasks),
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
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm công việc...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
              onChanged: (val) {
                _searchQuery = val;
                _applyFilter();
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tất cả'),
                  selected: _selectedFilterStatus == 'all',
                  onSelected: (selected) {
                    if (selected) {
                      _selectedFilterStatus = 'all';
                      _applyFilter();
                    }
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Chưa làm'),
                  selected: _selectedFilterStatus == 'todo',
                  onSelected: (selected) {
                    if (selected) {
                      _selectedFilterStatus = 'todo';
                      _applyFilter();
                    }
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Đang làm'),
                  selected: _selectedFilterStatus == 'in_progress',
                  onSelected: (selected) {
                    if (selected) {
                      _selectedFilterStatus = 'in_progress';
                      _applyFilter();
                    }
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Hoàn thành'),
                  selected: _selectedFilterStatus == 'completed',
                  onSelected: (selected) {
                    if (selected) {
                      _selectedFilterStatus = 'completed';
                      _applyFilter();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filteredTasks.isEmpty
                ? const Center(child: Text('Không tìm thấy công việc phù hợp!'))
                : RefreshIndicator(
              onRefresh: () async => _fetchTasks(),
              child: ListView.builder(
                itemCount: _filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = _filteredTasks[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        task.description.isEmpty ? 'Chưa có mô tả' : task.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(
                            label: Text(task.priority, style: const TextStyle(color: Colors.white, fontSize: 12)),
                            backgroundColor: _getPriorityColor(task.priority),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, color: Colors.grey),
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
            MaterialPageRoute(builder: (context) => TaskCreateScreen(token: widget.token)),
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