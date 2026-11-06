import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import '../profile/profile_screen.dart';
import '../assignment/assign_task_screen.dart';
import 'task_create_screen.dart';

class TaskListScreen extends StatefulWidget {
  final String token;
  const TaskListScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  void _fetchTasks() async {
    setState(() => _isLoading = true);
    final tasks = await TaskService.getTasks(widget.token);
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  void _deleteTask(String taskId) async {
    final res = await TaskService.deleteTask(widget.token, taskId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Đã xóa công việc')),
      );
      _fetchTasks();
    }
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
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen(token: widget.token)),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
          ? const Center(child: Text('Chưa có công việc nào!'))
          : RefreshIndicator(
        onRefresh: () async => _fetchTasks(),
        child: ListView.builder(
          itemCount: _tasks.length,
          itemBuilder: (context, index) {
            final task = _tasks[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(task.description),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(task.priority, style: const TextStyle(color: Colors.white)),
                      backgroundColor: _getPriorityColor(task.priority),
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_add, color: Colors.blue),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AssignTaskScreen(
                              token: widget.token,
                              taskId: task.id,
                              taskTitle: task.title,
                            ),
                          ),
                        );
                        if (result == true) _fetchTasks();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteTask(task.id),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
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