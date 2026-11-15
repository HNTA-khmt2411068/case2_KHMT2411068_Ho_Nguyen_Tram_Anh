import 'package:flutter/material.dart';

class UserSelector extends StatelessWidget {
  final List<dynamic> users;
  final List<String> selectedUserIds;
  final ValueChanged<List<String>> onChanged;

  const UserSelector({
    super.key,
    required this.users,
    required this.selectedUserIds,
    required this.onChanged,
  });

  String _getId(dynamic user) {
    if (user is Map) return (user['_id'] ?? user['id'] ?? '').toString();
    return user.id.toString();
  }

  String _getName(dynamic user) {
    if (user is Map) return (user['fullName'] ?? '').toString();
    return user.fullName.toString();
  }

  String _getEmail(dynamic user) {
    if (user is Map) return (user['email'] ?? '').toString();
    return user.email.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Không tìm thấy người dùng phù hợp'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final id = _getId(user);
        final isSelected = selectedUserIds.contains(id);

        return CheckboxListTile(
          value: isSelected,
          title: Text(_getName(user)),
          subtitle: Text(_getEmail(user)),
          onChanged: (checked) {
            final updated = List<String>.from(selectedUserIds);
            if (checked == true) {
              if (!updated.contains(id)) updated.add(id);
            } else {
              updated.remove(id);
            }
            onChanged(updated);
          },
        );
      },
    );
  }
}