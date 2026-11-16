import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/statistics_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String token;
  final List<Task> tasks;

  const ProfileScreen({
    super.key,
    required this.token,
    this.tasks = const [],
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final StatisticsService _statisticsService = StatisticsService();

  String _email = '';
  bool _isLoading = true;

  Map<String, dynamic> _taskStats = {};
  Map<String, dynamic> _assignmentStats = {};
  Map<String, dynamic> _deadlineStats = {};

  static const Color _bgTaroMilk = Color(0xFFF5F0FF);
  static const Color _taroLight = Color(0xFFEBE0FF);
  static const Color _taroPrimary = Color(0xFF8367D8);
  static const Color _taroDark = Color(0xFF3E2D6B);
  static const Color _taroMuted = Color(0xFF7B6F99);
  static const Color _taroBorder = Color(0xFFE2D7FA);

  @override
  void initState() {
    super.initState();
    ApiClient.token = widget.token;
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await AuthService.getMe(widget.token);
      final userData = res['user'] is Map<String, dynamic>
          ? res['user'] as Map<String, dynamic>
          : (res['data'] is Map<String, dynamic>
          ? res['data'] as Map<String, dynamic>
          : res);

      if (userData['_id'] != null ||
          userData['id'] != null ||
          userData['email'] != null) {
        _nameController.text = userData['fullName'] ?? '';
        _email = userData['email'] ?? '';
      }

      final results = await Future.wait([
        _statisticsService
            .getTaskStatistics()
            .catchError((_) => <String, dynamic>{}),
        _statisticsService
            .getAssignmentStatistics()
            .catchError((_) => <String, dynamic>{}),
        _statisticsService
            .getDeadlineStatistics()
            .catchError((_) => <String, dynamic>{}),
      ]);

      if (mounted) {
        setState(() {
          _taskStats = results[0];
          _assignmentStats = results[1];
          _deadlineStats = results[2];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int _pickInt(Map<String, dynamic> map, List<String> keys, int fallback) {
    for (final k in keys) {
      final val = map[k];
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String && int.tryParse(val) != null) return int.parse(val);
    }
    if (map['data'] is Map<String, dynamic>) {
      return _pickInt(map['data'] as Map<String, dynamic>, keys, fallback);
    }
    return fallback;
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Cập nhật hồ sơ',
          style: TextStyle(color: _taroDark, fontWeight: FontWeight.bold),
        ),
        content: TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Họ và tên',
            prefixIcon: const Icon(Icons.person_outline_rounded, color: _taroPrimary),
            filled: true,
            fillColor: const Color(0xFFFAF8FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _taroBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _taroBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _taroPrimary, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
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
              Navigator.pop(ctx);
              final res = await AuthService.updateMe(
                widget.token,
                _nameController.text.trim(),
                null,
              );
              if (mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'Cập nhật thành công!'),
                  ),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    _currentPassController.clear();
    _newPassController.clear();
    bool obscureCurrent = true;
    bool obscureNew = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Đổi mật khẩu',
            style: TextStyle(color: _taroDark, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _currentPassController,
                obscureText: obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color: _taroPrimary,
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureCurrent
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _taroMuted,
                      size: 19,
                    ),
                    onPressed: () =>
                        setDialogState(() => obscureCurrent = !obscureCurrent),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFAF8FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newPassController,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                  prefixIcon: const Icon(
                    Icons.lock_reset_rounded,
                    color: _taroPrimary,
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNew
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _taroMuted,
                      size: 19,
                    ),
                    onPressed: () =>
                        setDialogState(() => obscureNew = !obscureNew),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFAF8FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
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
                if (_currentPassController.text.isEmpty ||
                    _newPassController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập đầy đủ mật khẩu!'),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                final res = await AuthService.changePassword(
                  widget.token,
                  _currentPassController.text,
                  _newPassController.text,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'Đổi mật khẩu thất bại!'),
                    ),
                  );
                  if (res['message'] == 'Đổi mật khẩu thành công!') {
                    _currentPassController.clear();
                    _newPassController.clear();
                  }
                }
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(color: _taroDark, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất không?',
          style: TextStyle(color: _taroMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: _taroMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    ApiClient.token = null;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required Color color,
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
              child: Icon(icon, color: color, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusMiniCard({
    required String count,
    required String label,
    required Color circleColor,
    required Color textColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEDE6FC)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D8367D8),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                count,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _taroDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEDE6FC)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D8367D8),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _taroMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int fallbackTotal = widget.tasks.length;
    final int fallbackTodo =
        widget.tasks.where((t) => t.status == 'todo').length;
    final int fallbackInProgress =
        widget.tasks.where((t) => t.status == 'in_progress').length;
    final int fallbackCompleted =
        widget.tasks.where((t) => t.status == 'completed').length;

    final int total =
    _pickInt(_taskStats, ['total', 'totalTasks'], fallbackTotal);
    final int todo = _pickInt(_taskStats, ['todo'], fallbackTodo);
    final int inProgress = _pickInt(
      _taskStats,
      ['in_progress', 'inProgress'],
      fallbackInProgress,
    );
    final int completed =
    _pickInt(_taskStats, ['completed'], fallbackCompleted);

    final int assigned = _pickInt(
      _assignmentStats,
      ['assignedToMe', 'assigned', 'myTasks', 'totalAssigned'],
      0,
    );
    final int shared = _pickInt(
      _assignmentStats,
      ['sharedWithMe', 'shared', 'totalShared'],
      0,
    );
    final int upcoming = _pickInt(
      _deadlineStats,
      ['upcoming', 'dueSoon', 'dueIn24h'],
      0,
    );
    final int overdue =
    _pickInt(_deadlineStats, ['overdue', 'expired'], 0);

    final double progressRatio = total > 0 ? (completed / total) : 0.0;
    final int progressPercent = (progressRatio * 100).round();
    final String displayName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Người dùng';

    return Scaffold(
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Hồ sơ & Thống kê',
          style: TextStyle(
            color: _taroDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          _buildHeaderButton(
            icon: Icons.refresh_rounded,
            color: _taroDark,
            tooltip: 'Làm mới dữ liệu',
            onTap: _loadData,
          ),
          _buildHeaderButton(
            icon: Icons.logout_rounded,
            color: Colors.redAccent,
            tooltip: 'Đăng xuất',
            onTap: _logout,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: _taroPrimary),
      )
          : RefreshIndicator(
        color: _taroPrimary,
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFEDE6FC)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x148367D8),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: _taroLight,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _getInitials(displayName),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _taroPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: _taroDark,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _email,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _taroMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showEditProfileDialog,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _taroPrimary,
                              side: const BorderSide(color: _taroBorder),
                              padding: const EdgeInsets.symmetric(
                                vertical: 11,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.edit_rounded, size: 17),
                            label: const Text(
                              'Sửa hồ sơ',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showChangePasswordDialog,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFD97706),
                              side: const BorderSide(
                                color: Color(0xFFFCD34D),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 11,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(
                              Icons.lock_outline_rounded,
                              size: 17,
                            ),
                            label: const Text(
                              'Đổi mật khẩu',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Tiến độ công việc',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _taroDark,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF967AE6), Color(0xFF7253CC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x388367D8),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.assignment_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Tổng số công việc',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '$total',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progressRatio,
                        minHeight: 8,
                        backgroundColor:
                        Colors.white.withValues(alpha: 0.25),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF4ADE80),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tỷ lệ hoàn thành: $progressPercent% ($completed/$total việc)',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatusMiniCard(
                    count: '$todo',
                    label: 'Chưa làm',
                    circleColor: const Color(0xFFF1EEF8),
                    textColor: _taroMuted,
                  ),
                  const SizedBox(width: 10),
                  _buildStatusMiniCard(
                    count: '$inProgress',
                    label: 'Đang làm',
                    circleColor: _taroLight,
                    textColor: _taroPrimary,
                  ),
                  const SizedBox(width: 10),
                  _buildStatusMiniCard(
                    count: '$completed',
                    label: 'Hoàn thành',
                    circleColor: const Color(0xFFE6F7F2),
                    textColor: const Color(0xFF13795B),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Phân công & Thời hạn',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _taroDark,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMetricCard(
                    icon: Icons.assignment_ind_rounded,
                    iconBg: _taroLight,
                    iconColor: _taroPrimary,
                    value: '$assigned',
                    label: 'Được giao',
                  ),
                  const SizedBox(width: 10),
                  _buildMetricCard(
                    icon: Icons.folder_shared_rounded,
                    iconBg: const Color(0xFFE6F7F2),
                    iconColor: const Color(0xFF13795B),
                    value: '$shared',
                    label: 'Được chia sẻ',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildMetricCard(
                    icon: Icons.access_time_filled_rounded,
                    iconBg: const Color(0xFFFFF4DB),
                    iconColor: const Color(0xFFD97706),
                    value: '$upcoming',
                    label: 'Sắp đến hạn',
                  ),
                  const SizedBox(width: 10),
                  _buildMetricCard(
                    icon: Icons.warning_amber_rounded,
                    iconBg: const Color(0xFFFEE2E2),
                    iconColor: const Color(0xFFDC2626),
                    value: '$overdue',
                    label: 'Quá hạn',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}