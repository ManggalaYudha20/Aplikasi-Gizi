// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\admin\widgets\user_list_tile.dart

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
      // 1. Ubah margin menjadi zero karena GridView sudah mengatur spacing
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // 2. Bungkus ListTile dengan Center
      child: Center(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: user.role.color.withValues(alpha: 0.2),
            backgroundImage:
                (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                ? NetworkImage(user.photoUrl!)
                : null,
            child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                ? Icon(Icons.person, color: user.role.color)
                : null,
          ),
          title: Text(
            user.displayName,
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1, // Opsional: Mencegah nama panjang merusak layout
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Penting agar Column tidak melebar
            children: [
              Text(user.email, maxLines: 1, overflow: TextOverflow.ellipsis),
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
      ),
    );
  }
}
