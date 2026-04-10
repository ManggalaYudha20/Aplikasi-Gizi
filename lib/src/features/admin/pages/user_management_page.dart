// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\admin\pages\user_management_page.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/admin/models/user_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/admin/models/user_filter_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/admin/repositories/user_repository.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/admin/logic/user_management_logic.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/admin/widgets/user_search_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/admin/widgets/user_list_tile.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/admin/widgets/fading_snackbar_content.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/admin/widgets/user_filter_sheet.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  UserFilterModel _currentFilter = UserFilterModel();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- 1. Fungsi penentu jumlah kolom responsif ---
  int _getCrossAxisCount(double screenWidth) {
    if (screenWidth >= 1200) return 3; // Desktop / Layar sangat lebar (3 kolom)
    if (screenWidth >= 800) return 2; // Tablet / Layar sedang (2 kolom)
    return 1; // Mobile (1 kolom)
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

    messenger.clearSnackBars();

    const totalDuration = Duration(milliseconds: 3000);
    const fadeOutDuration = Duration(milliseconds: 1500);

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: totalDuration,
        margin: EdgeInsets.zero,
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
    if (user.role == UserRole.admin) {
      _showSnackBar(
        'Data Admin dilindungi dan tidak dapat diubah.',
        isError: true,
      );
      return;
    }

    final UserRole? selectedRole = await showDialog<UserRole>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Pilih Role Baru'),
        // Sembunyikan role lama (.ahliGizi) agar tidak muncul ganda di dialog
        children: UserRole.values
            .where((r) => r != UserRole.unknown && r != UserRole.ahliGizi)
            .map((role) {
              return SimpleDialogOption(
                onPressed: () => Navigator.pop(context, role),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(role.label, style: const TextStyle(fontSize: 16)),
                ),
              );
            })
            .toList(),
      ),
    );

    if (selectedRole != null && selectedRole != user.role) {
      try {
        await _repository.updateUserRole(user.id, selectedRole);
        _showSnackBar(
          'Role ${user.displayName} diubah ke ${selectedRole.label}',
        );
      } catch (e) {
        _showSnackBar(e.toString(), isError: true);
      }
    }
  }

  Future<void> _handleDeleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        // Menambahkan Row untuk menempatkan Icon dan Text secara berdampingan
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Konfirmasi Hapus'),
          ],
        ),
        // Menyesuaikan teks agar lebih informatif seperti pada account_dialogs
        content: Text(
          'Apakah Anda yakin ingin menghapus pengguna ${user.displayName} secara permanen? '
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          // Mengubah TextButton menjadi ElevatedButton dengan warna merah
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Hapus'),
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
  // Tambahkan fungsi ini di bawah handlers yang lain
  void _openFilterSheet() async {
    final result = await showModalBottomSheet<UserFilterModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserFilterSheet(
        currentFilters: _currentFilter,
        onResetPressed: () {
          setState(() {
            _currentFilter = UserFilterModel();
          });
          Navigator.pop(context); // Tutup sheet setelah reset
        },
      ),
    );

    if (result != null) {
      setState(() {
        _currentFilter = result;
      });
    }
  }

  // --- Build UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(
        title: 'Manajemen Pengguna',
        subtitle: 'Kelola hak akses dan data',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: UserSearchBar(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onClear: _onClearSearch,
                    isNotEmpty: _searchQuery.isNotEmpty,
                  ),
                ),
                const SizedBox(width: 8),
                // Tombol Filter
                Container(
                  decoration: BoxDecoration(
                    color: _currentFilter.isFiltering 
                        ? Colors.green.shade50 
                        : Colors.white,
                    border: Border.all(
                      color: _currentFilter.isFiltering 
                          ? Colors.green 
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.filter_list,
                      color: _currentFilter.isFiltering 
                          ? Colors.green 
                          : Colors.grey.shade700,
                    ),
                    onPressed: _openFilterSheet,
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('settings')
                .doc('app_settings')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  color: Colors.red.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.error_outline, color: Colors.red),
                    title: const Text('Gagal memuat pengaturan Mode UAT'),
                    subtitle: Text(
                      snapshot.error.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              }

              bool isUatMode = false;

              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                // Cek apakah database masih menyimpan format lama atau format baru
                isUatMode =
                    (data?['default_role'] == 'ahli_gizi' ||
                    data?['default_role'] == 'nutrisionis');
              }

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                color: isUatMode ? Colors.green.shade50 : null,
                child: SwitchListTile(
                  activeThumbColor: Colors.green,
                  activeTrackColor: Colors.green.shade300,
                  title: const Text(
                    'Mode Auto-Nutrisionis',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    isUatMode
                        ? 'Aktif: Pendaftar baru otomatis menjadi Nutrisionis.'
                        : 'Mati: Pendaftar baru otomatis menjadi Tamu.',
                  ),
                  value: isUatMode,
                  onChanged: (bool value) async {
                    try {
                      // Simpan dengan format role yang baru ke database
                      final newRole = value ? 'nutrisionis' : 'tamu';

                      await FirebaseFirestore.instance
                          .collection('settings')
                          .doc('app_settings')
                          .set({
                            'default_role': newRole,
                          }, SetOptions(merge: true));

                      _showSnackBar(
                        'Mode berhasil ${value ? "diaktifkan" : "dimatikan"}',
                      );
                    } catch (e) {
                      _showSnackBar('Gagal mengubah mode: $e', isError: true);
                    }
                  },
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _repository.getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Terjadi kesalahan: ${snapshot.error}'),
                  );
                }

                final allUsers = snapshot.data ?? [];

                var displayUsers = UserManagementLogic.processUsers(
                  allUsers: allUsers,
                  searchQuery: _searchQuery,
                );

                // 2. --- TERAPKAN LOGIKA FILTER ROLE DI SINI ---
                if (_currentFilter.isFiltering) {
                  displayUsers = displayUsers.where((user) {
                    // Jika filter yang dipilih adalah Nutrisionis, 
                    // loloskan user dengan role Nutrisionis (baru) ATAU Ahli Gizi (lama)
                    if (_currentFilter.role == UserRole.nutrisionis) {
                      return user.role == UserRole.nutrisionis || 
                             user.role == UserRole.ahliGizi;
                    }
                    
                    // Untuk role lain (seperti Admin atau Tamu), filter seperti biasa
                    return user.role == _currentFilter.role;
                  }).toList();
                }

                if (displayUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
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

                // --- 2. Bungkus list dengan LayoutBuilder ---
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;

                    // --- 3. Gunakan GridView.builder sebagai pengganti ListView.builder ---
                    return GridView.builder(
                      padding: const EdgeInsets.only(
                        bottom: 80,
                        left: 16,
                        right: 16,
                        top: 8,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _getCrossAxisCount(screenWidth),
                        crossAxisSpacing: 12.0, // Jarak antar kolom
                        mainAxisSpacing: 12.0, // Jarak antar baris
                        mainAxisExtent:
                            90.0, // Tinggi standar tile (sesuaikan jika terpotong)
                      ),
                      itemCount: displayUsers.length,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
