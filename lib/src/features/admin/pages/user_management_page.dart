import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/admin/models/user_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/admin/repositories/user_repository.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/admin/logic/user_management_logic.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/admin/widgets/user_search_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/admin/widgets/user_list_tile.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/admin/widgets/fading_snackbar_content.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart'; // Import App Bar Anda

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  // Dependencies
  final UserRepository _repository = UserRepository();
  
  // UI State
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Handlers (Interaksi Pengguna) ---

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  void _onClearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = "";
    });
  }
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    
    // 1. PENTING: Hapus semua SnackBar yang sedang tampil atau mengantre
    messenger.clearSnackBars(); 

    // Konfigurasi Durasi
    const totalDuration = Duration(milliseconds: 3000); // Total waktu tampil (3 detik)
    const fadeOutDuration = Duration(milliseconds: 1500); // Waktu menghilang pelan-pelan (1.5 detik)
    
    // 2. Tampilkan SnackBar baru
    messenger.showSnackBar(
      SnackBar(
        // 1. Buat Shell SnackBar Transparan & Tanpa Bayangan
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: totalDuration, 
        margin: EdgeInsets.zero, // Margin diatur di dalam konten custom
        
        // 2. Gunakan Widget Custom untuk Konten & Animasi
        content: FadingSnackBarContent(
          message: message,
          color: isError ? Colors.redAccent : Colors.green,
          totalDuration: totalDuration,
          fadeDuration: fadeOutDuration,
        ),
      ),
    );
  }

  Future<void> _handleRoleUpdate(UserModel user) async {
    // Cek Guard Clause Admin
    if (user.role == UserRole.admin) {
      _showSnackBar('Data Admin dilindungi dan tidak dapat diubah.', isError: true);
      return;
    }

    final UserRole? selectedRole = await showDialog<UserRole>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Pilih Role Baru'),
        children: UserRole.values.where((r) => r != UserRole.unknown).map((role) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, role),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(role.label, style: const TextStyle(fontSize: 16)),
            ),
          );
        }).toList(),
      ),
    );

    if (selectedRole != null && selectedRole != user.role) {
      try {
        await _repository.updateUserRole(user.id, selectedRole);
        // GANTI INI:
        _showSnackBar('Role ${user.displayName} diubah ke ${selectedRole.label}');
      } catch (e) {
        // GANTI INI:
        _showSnackBar(e.toString(), isError: true);
      }
    }
  }

  Future<void> _handleDeleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Yakin ingin menghapus pengguna ${user.displayName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repository.deleteUser(user.id);
        _showSnackBar('Pengguna berhasil dihapus');
      } catch (e) {
        _showSnackBar(e.toString(), isError: true);
      }
    }
  }

  // --- Build UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      // Menggunakan AppBar custom Anda jika ada, atau default
      appBar: const CustomAppBar(title: 'Manajemen Pengguna', subtitle: 'Kelola hak akses dan data',), 
      body: Column(
        children: [
          UserSearchBar(
            controller: _searchController,
            onChanged: _onSearchChanged,
            onClear: _onClearSearch,
            isNotEmpty: _searchQuery.isNotEmpty,
          ),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _repository.getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
                }

                final allUsers = snapshot.data ?? [];
                
                // Menerapkan Logika Filtering & Sorting di sini (Logic Layer)
                // Ini memisahkan UI rendering dari logika bisnis
                final displayUsers = UserManagementLogic.processUsers(
                  allUsers: allUsers,
                  searchQuery: _searchQuery,
                );

                if (displayUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty 
                              ? 'Belum ada data pengguna' 
                              : 'Tidak ditemukan hasil untuk "$_searchQuery"',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: displayUsers.length,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemBuilder: (context, index) {
                    final user = displayUsers[index];
                    return UserListTile(
                      user: user,
                      onTap: () => _handleRoleUpdate(user),
                      onDelete: () => _handleDeleteUser(user),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}