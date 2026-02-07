import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/admin/models/user_model.dart';

class UserListTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const UserListTile({
    super.key,
    required this.user,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.role.color.withValues(alpha:0.2),
          // 1. Cek apakah photoUrl ada datanya
          backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
              ? NetworkImage(user.photoUrl!)
              : null,
          // 2. Jika tidak ada foto, tampilkan Icon sebagai fallback
          child: (user.photoUrl == null || user.photoUrl!.isEmpty)
              ? Icon(Icons.person, color: user.role.color)
              : null,
        ),
        title: Text(
          user.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: user.role.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: user.role.color.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                user.role.label,
                style: TextStyle(
                  fontSize: 12,
                  color: user.role.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: user.role == UserRole.admin
            ? null 
            : IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: onDelete,
              ),
        onTap: onTap,
      ),
    );
  }
}
