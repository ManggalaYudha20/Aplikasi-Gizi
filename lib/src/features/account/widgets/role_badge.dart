import 'package:flutter/material.dart';

class RoleBadge extends StatelessWidget {
  final String roleName;

  const RoleBadge({super.key, required this.roleName});

  // Helper untuk menentukan warna berdasarkan role
  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.redAccent;
      case 'ahli gizi':
        return Colors.green;
      case 'tamu':
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color roleColor = _getRoleColor(roleName);

    return Semantics(
      label: 'badge_role_$roleName',
      container: true,
      child: Container(
        key: Key('role_badge_$roleName'), // Memudahkan QA mencari berdasarkan role tertentu
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          // Menggunakan withValues (Flutter terbaru) atau withOpacity
          color: roleColor.withValues(alpha: 0.1), 
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: roleColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          roleName,
          style: TextStyle(
            color: roleColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}