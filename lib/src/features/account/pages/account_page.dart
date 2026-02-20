//D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\account\pages\account_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Imports internal (sesuaikan path impor Anda)
import 'package:aplikasi_diagnosa_gizi/src/login/auth_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/services/user_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/fade_in_transition.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/version_info_app.dart';

// Imports hasil refaktoring baru
import 'package:aplikasi_diagnosa_gizi/src/features/account/logic/role_formatter.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/account/widgets/account_dialogs.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/account/widgets/role_badge.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/account/widgets/account_menu_button.dart';

class AccountPage extends StatelessWidget {
  // DEPENDENCY INJECTION:
  // Service di-pass via constructor, bukan di-instansiasi di dalam build.
  // Ini memungkinkan kita mengganti service dengan mock saat testing.
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
        subtitle: 'Halo, ${user?.displayName}!',
      ),
      body: FadeInTransition(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // SECTION: User Profile
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (user != null) _buildUserProfile(context, user),
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
                  AccountMenuButton(
                    testId: 'btn_logout',
                    label: 'Keluar',
                    icon: Icons.logout,
                    textColor: Colors.red,
                    iconColor: Colors.red,
                    onPressed: () => AccountDialogs.showSignOutConfirmation(
                      context,
                      onConfirm: () async {
                        await authService.signOut();
                        // Handle navigasi setelah logout jika perlu
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const VersionInfoWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context, User user) {
    return FutureBuilder<DocumentSnapshot>(
      future: userService.getUserDocument(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Bungkus dengan SizedBox dan beri tinggi (height)
          // agar "Center" memiliki ruang untuk menaruh loading di tengah vertikal
          return const SizedBox(
            height: 200, // Tinggi perkiraan area profil
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // Error Handling yang lebih graceful
        if (snapshot.hasError) {
          return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Data pengguna tidak ditemukan'));
        }

        final data = snapshot.data!;
        // Menggunakan helper class untuk mengambil data dengan aman
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
              label: 'user_display_name', // Label tetap untuk QA
              child: Text(
                displayName,
                key: const Key(
                  'text_display_name',
                ), // Key untuk verifikasi teks
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),

            // Menggunakan Widget Badge yang reusable
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
      },
    );
  }
}
