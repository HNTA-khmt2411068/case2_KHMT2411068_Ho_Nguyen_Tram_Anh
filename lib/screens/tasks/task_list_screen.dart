import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../utils/constants.dart';
import '../../widgets/priority_badge.dart';
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

  static const Color _bgTaroMilk = Color(0xFFF5F0FF);
  static const Color _taroLight = Color(0xFFEBE0FF);
  static const Color _taroPrimary = Color(0xFF8367D8);
  static const Color _taroDark = Color(0xFF3E2D6B);
  static const Color _taroMuted = Color(0xFF7B6F99);
  static const Color _taroBorder = Color(0xFFE2D7FA);

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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  14,
                  20,
                  MediaQuery.of(ctx).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: _taroBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bộ lọc công việc',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _taroDark,
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
                            child: const Text(
                              'Đặt lại',
                              style: TextStyle(
                                color: _taroPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Divider(color: Color(0xFFF0E8FF)),
                    const SizedBox(height: 8),
                    const Text(
                      'Vai trò của bạn',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _taroDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final role in ['all', 'owner', 'assigned', 'shared'])
                          ChoiceChip(
                            label: Text(_getRoleLabel(role)),
                            selected: _selectedRoleScope == role,
                            selectedColor: _taroLight,
                            backgroundColor: const Color(0xFFFAF8FF),
                            checkmarkColor: _taroPrimary,
                            labelStyle: TextStyle(
                              color: _selectedRoleScope == role
                                  ? _taroDark
                                  : _taroMuted,
                              fontWeight: _selectedRoleScope == role
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: _selectedRoleScope == role
                                  ? _taroPrimary
                                  : _taroBorder,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setSheetState(() => _selectedRoleScope = role);
                                _applyFilter();
                              }
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Trạng thái thực hiện',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _taroDark,
                      ),
                    ),
                    const SizedBox(height: 10),
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
                            selectedColor: _taroLight,
                            backgroundColor: const Color(0xFFFAF8FF),
                            checkmarkColor: _taroPrimary,
                            labelStyle: TextStyle(
                              color: _selectedFilterStatus == st
                                  ? _taroDark
                                  : _taroMuted,
                              fontWeight: _selectedFilterStatus == st
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: _selectedFilterStatus == st
                                  ? _taroPrimary
                                  : _taroBorder,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setSheetState(() => _selectedFilterStatus = st);
                                _applyFilter();
                              }
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _taroPrimary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: const Color(0x448367D8),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Xem ${_filteredTasks.length} công việc',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  Widget _buildRoleBadge(String taskId) {
    final role = _taskRoles[taskId];
    if (role == null) return const SizedBox.shrink();

    String label;
    Color bg;
    Color fg;

    switch (role) {
      case 'owner':
        label = 'Của tôi';
        bg = const Color(0xFFE6F7F2);
        fg = const Color(0xFF13795B);
        break;
      case 'primary_assignee':
        label = 'Phụ trách chính ⭐';
        bg = const Color(0xFFFFF4DB);
        fg = const Color(0xFF9A6700);
        break;
      case 'assignee':
        label = 'Được giao';
        bg = const Color(0xFFE8F1FF);
        fg = const Color(0xFF1D5BBF);
        break;
      case 'editor':
        label = 'Chia sẻ • Sửa';
        bg = _taroLight;
        fg = _taroDark;
        break;
      default:
        label = 'Chia sẻ • Xem';
        bg = const Color(0xFFF1EEF8);
        fg = _taroMuted;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
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

  Widget _buildHeaderAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _taroBorder),
              ),
              child: Icon(icon, color: _taroDark, size: 20),
            ),
          ),
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
      backgroundColor: _bgTaroMilk,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Danh sách công việc',
          style: TextStyle(
            color: _taroDark,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          _buildHeaderAction(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Thông báo',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationScreen(token: widget.token),
                ),
              );
            },
          ),
          _buildHeaderAction(
            icon: Icons.person_outline_rounded,
            tooltip: 'Hồ sơ',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProfileScreen(token: widget.token, tasks: _tasks),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: _taroPrimary),
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D8367D8),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        color: _taroDark,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm công việc...',
                        hintStyle: const TextStyle(
                          color: _taroMuted,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: _taroPrimary,
                          size: 22,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: _taroMuted,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _searchQuery = '';
                            _applyFilter();
                          },
                        )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: _taroBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: _taroBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: _taroPrimary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 13,
                          horizontal: 14,
                        ),
                      ),
                      onChanged: (val) {
                        _searchQuery = val;
                        _applyFilter();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Material(
                      color: _activeFilterCount > 0
                          ? _taroLight
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _showFilterBottomSheet,
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _activeFilterCount > 0
                                  ? _taroPrimary
                                  : _taroBorder,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0D8367D8),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: _activeFilterCount > 0
                                ? _taroPrimary
                                : _taroDark,
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
                          backgroundColor: _taroPrimary,
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _taroLight.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.filter_alt_rounded,
                      size: 15,
                      color: _taroPrimary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Đang lọc: ${activeLabels.join(' • ')}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _taroDark,
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
                          color: _taroPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _filteredTasks.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _taroLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.inbox_rounded,
                      size: 32,
                      color: _taroPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Không tìm thấy công việc phù hợp!',
                    style: TextStyle(
                      color: _taroMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              color: _taroPrimary,
              onRefresh: () async => _fetchTasks(),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                itemCount: _filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = _filteredTasks[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFEDE6FC),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x128367D8),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  TaskDetailScreen(
                                    token: widget.token,
                                    task: task,
                                  ),
                            ),
                          );
                          if (result == true) {
                            _fetchTasks();
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: _taroDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      task.description.isEmpty
                                          ? 'Chưa có mô tả'
                                          : task.description,
                                      maxLines: 1,
                                      overflow:
                                      TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: _taroMuted,
                                      ),
                                    ),
                                    _buildRoleBadge(task.id),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              PriorityBadge(
                                priority: task.priority,
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFFA799C7),
                              ),
                            ],
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: _taroPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskCreateScreen(token: widget.token),
            ),
          );
          if (result == true) {
            _fetchTasks();
          }
        },
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}