// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\account\pages\account_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Imports internal (sesuaikan path impor Anda)
import 'package:aplikasi_diagnosa_gizi/src/features/login/auth_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/services/user_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/fade_in_transition.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/version_info_app.dart';

// Imports hasil refaktoring baru
import 'package:aplikasi_diagnosa_gizi/src/features/account/logic/role_formatter.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/account/widgets/account_dialogs.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/account/widgets/role_badge.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/account/widgets/account_menu_button.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/account/pages/backup_page.dart';

import 'package:aplikasi_diagnosa_gizi/src/features/login/login_screen.dart';

class AccountPage extends StatelessWidget {
  final AuthService authService;
  final UserService userService;

  const AccountPage({
    super.key,
    required this.authService,
    required this.userService,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: 'Profil Akun',
        subtitle: 'Halo, ${user?.displayName ?? 'User'}!',
      ),
      // Pindahkan FutureBuilder ke sini agar role bisa dibaca oleh profil DAN tombol
      body: FutureBuilder<DocumentSnapshot>(
        future: userService.getUserDocument(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }

          final data = snapshot.data;
          // Ambil rawRole di sini
          final String rawRole = data != null && data.exists 
              ? (data.get('role')?.toString() ?? '') 
              : '';

          return FadeInTransition(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // SECTION: User Profile
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (user != null && data != null && data.exists)
                          _buildUserProfile(context, user, data),
                      ],
                    ),
                  ),
                ),

                // SECTION: Actions & Info
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // LOGIKA FILTER ROLE: Hanya tampil jika ahli_gizi ATAU admin
                      if (rawRole == 'ahli_gizi' || rawRole == 'admin' || rawRole == 'nutrisionis' ) ...[
                        AccountMenuButton(
                          testId: 'btn_backup_restore',
                          label: 'Backup & Restore Data Pasien',
                          icon: Icons.cloud_sync_outlined,
                          textColor: Colors.black87,
                          iconColor: Colors.blue,
                          onPressed: () {
                            if (user != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BackupPage(currentUserId: user.uid,userRole: rawRole,),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Anda harus login terlebih dahulu.')),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      AccountMenuButton(
                        testId: 'btn_logout',
                        label: 'Keluar',
                        icon: Icons.logout,
                        textColor: Colors.red,
                        iconColor: Colors.red,
                        onPressed: () => AccountDialogs.showSignOutConfirmation(
                          context,
                          onConfirm: () async {
                            try {
                              await authService.signOut();
                              if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                  (Route<dynamic> route) => false,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Gagal keluar akun: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 30),
                      const VersionInfoWidget(),

                      AccountMenuButton(
                        testId: 'btn_delete_account',
                        label: 'Hapus Akun',
                        icon: Icons.delete_forever,
                        textColor: Colors.red,
                        iconColor: Colors.red,
                        onPressed: () => AccountDialogs.showDeleteAccountConfirmation(
                          context,
                          onConfirm: () async {
                            try {
                              final currentUser = FirebaseAuth.instance.currentUser;
                              if (currentUser == null) return;

                              
                              final lastSignIn = currentUser.metadata.lastSignInTime;
                              if (lastSignIn != null && DateTime.now().difference(lastSignIn).inMinutes > 5) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sesi login terlalu lama. Demi keamanan, silakan LOGOUT dan LOGIN kembali sebelum menghapus akun.'),
                                    duration: Duration(seconds: 5),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return; 
                              }
                            

                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(child: CircularProgressIndicator()),
                              );

                              // 1. Hapus data di Firestore terlebih dahulu
                              await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).delete();
                              
                              // 2. Hapus Autentikasi dari Firebase Auth
                              await currentUser.delete();

                              if (context.mounted) Navigator.pop(context); // Tutup dialog loading
                              if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                  (Route<dynamic> route) => false,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Akun berhasil dihapus secara permanen.')),
                                );
                              }
                            } on FirebaseAuthException catch (e) {
                              if (context.mounted) Navigator.pop(context);
                              if (e.code == 'requires-recent-login') {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Sesi terlalu lama. Silakan logout dan login kembali.'),
                                      duration: Duration(seconds: 5),
                                    ),
                                  );
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Gagal menghapus akun: ${e.message}')),
                                  );
                                }
                              }
                            } catch (e) {
                              if (context.mounted) Navigator.pop(context);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Terjadi kesalahan: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ),

                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Fungsi _buildUserProfile disesuaikan agar menerima DocumentSnapshot (data) langsung
  Widget _buildUserProfile(BuildContext context, User user, DocumentSnapshot data) {
    final String rawRole = data.get('role')?.toString() ?? '';
    final String formattedRole = RoleFormatter.format(rawRole);
    final String displayName = data.get('displayName') ?? 'User';
    final String? photoUrl = user.photoURL;

    return Column(
      children: [
        GestureDetector(
          key: const Key('avatar_profile_click'),
          onTap: () => AccountDialogs.showProfileImage(context, photoUrl),
          child: Hero(
            tag: 'profile-avatar',
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: photoUrl != null
                  ? NetworkImage(photoUrl)
                  : null,
              child: photoUrl == null
                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          label: 'user_display_name',
          child: Text(
            displayName,
            key: const Key('text_display_name'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        RoleBadge(
          key: const Key('badge_role'), 
          roleName: formattedRole
        ),
        const SizedBox(height: 8),
        Semantics(
          label: 'user_email',
          child: Text(
            user.email ?? '',
            key: const Key('text_user_email'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ),
      ],
    );
  }
}