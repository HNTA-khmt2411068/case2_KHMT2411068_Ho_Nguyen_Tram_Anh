import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../auth/login_screen.dart';
import 'task_create_screen.dart';
import 'task_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notification_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Task> _tasks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchCurrentUser();
    await _loadTasks();
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final response = await ApiClient.get('/auth/me');
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final id = (data['_id'] ?? data['id'] ?? data['userId'] ?? data['user']?['_id'] ?? data['user']?['id'] ?? '').toString();
        setState(() {
          _currentUserId = id;
        });
      }
    } catch (_) {
      try {
        final response = await ApiClient.get('/users/profile');
        if (response.statusCode == 200 && mounted) {
          final data = jsonDecode(response.body);
          final id = (data['_id'] ?? data['id'] ?? data['userId'] ?? '').toString();
          setState(() {
            _currentUserId = id;
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await TaskService.getTasks();
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Task> get _filteredTasks {
    if (_searchQuery.isEmpty) return _tasks;
    return _tasks.where((task) {
      final titleLower = task.title.toLowerCase();
      final descLower = (task.description ?? '').toLowerCase();
      final queryLower = _searchQuery.toLowerCase();
      return titleLower.contains(queryLower) || descLower.contains(queryLower);
    }).toList();
  }

  Widget _buildTaskTag(Task task) {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      return const SizedBox.shrink();
    }

    String creatorId = '';
    final raw = task.rawCreatedBy;
    if (raw is Map) {
      creatorId = (raw['_id'] ?? raw['id'] ?? '').toString();
    } else if (raw != null) {
      creatorId = raw.toString();
    }

    bool isCreator = (creatorId.isNotEmpty && creatorId == _currentUserId);

    bool hasAssignees = false;
    bool amIAssigned = false;

    if (task.assigneeIds != null && task.assigneeIds!.isNotEmpty) {
      hasAssignees = true;
      amIAssigned = task.assigneeIds!.any((assignee) {
        String aId = '';
        if (assignee is Map) {
          aId = (assignee['_id'] ?? assignee['id'] ?? '').toString();
        } else if (assignee != null) {
          aId = assignee.toString();
        }
        return aId == _currentUserId;
      });
    }

    if (isCreator) {
      if (hasAssignees) {
        return Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.indigo.shade200),
          ),
          child: Text(
            'ĐÃ GIAO',
            style: TextStyle(
              color: Colors.indigo.shade700,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    if (amIAssigned) {
      return Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Text(
          'ĐƯỢC GIAO',
          style: TextStyle(
            color: Colors.purple.shade700,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (creatorId.isNotEmpty && creatorId != _currentUserId) {
      return Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.teal.shade200),
        ),
        child: Text(
          'CHIA SẺ',
          style: TextStyle(
            color: Colors.teal.shade700,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final displayTasks = _filteredTasks;

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF1976D2),
              ),
              accountName: const Text('Task Manager', style: TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: const Text('Quản lý công việc nhóm'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.pink.shade50,
                child: Icon(Icons.spa_rounded, color: Colors.pink.shade300, size: 36),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.task_alt, color: Color(0xFF1976D2)),
              title: const Text('Danh sách công việc'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Thông báo'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Cá nhân & Thống kê'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await AuthService.logout();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: const Text('Danh sách công việc'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm công việc...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayTasks.isEmpty
                  ? const Center(
                child: Text('Không tìm thấy công việc phù hợp!'),
              )
                  : RefreshIndicator(
                onRefresh: _loadTasks,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: displayTasks.length,
                  itemBuilder: (context, index) {
                    final task = displayTasks[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: ListTile(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskDetailScreen(task: task),
                            ),
                          );
                          if (result == true) {
                            _loadTasks();
                          }
                        },
                        contentPadding: const EdgeInsets.all(12),
                        title: Row(
                          children: [
                            _buildTaskTag(task),
                            Expanded(
                              child: Text(
                                task.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            task.description != null && task.description!.isNotEmpty
                                ? task.description!
                                : 'Không có mô tả',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: task.priority == 'high'
                                ? Colors.red.shade100
                                : task.priority == 'medium'
                                ? Colors.orange.shade100
                                : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            task.priority.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: task.priority == 'high'
                                  ? Colors.red.shade800
                                  : task.priority == 'medium'
                                  ? Colors.orange.shade900
                                  : Colors.green.shade800,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFE082),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TaskCreateScreen()),
          );
          if (result == true) {
            _loadTasks();
          }
        },
        child: const Icon(Icons.add, color: Colors.black87),
      ),
    );
  }
}