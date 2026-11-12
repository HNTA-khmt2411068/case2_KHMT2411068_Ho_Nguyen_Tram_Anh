class DateFormatter {
  static DateTime? _parse(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }

  static String formatDate(dynamic value) {
    final dt = _parse(value);
    if (dt == null) return 'Chưa đặt hạn';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day/$month/${dt.year}';
  }

  static String formatDateTime(dynamic value) {
    final dt = _parse(value);
    if (dt == null) return '';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/${dt.year} $hour:$minute';
  }

  static bool isOverdue(dynamic dueDate, {String? status}) {
    if (status == 'completed') return false;
    final dt = _parse(dueDate);
    if (dt == null) return false;
    return dt.isBefore(DateTime.now());
  }
}