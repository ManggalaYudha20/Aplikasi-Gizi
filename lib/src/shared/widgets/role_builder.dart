//lib\src\shared\widgets\role_builder.dart

// lib/src/shared/widgets/role_builder.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Widget yang membangun UI berdasarkan role pengguna yang sedang login.
///
/// Widget ini secara otomatis mendengarkan data pengguna dari Firestore
/// dan membandingkan role-nya dengan [requiredRole].
class RoleBuilder extends StatelessWidget {
  /// Role yang diperlukan untuk menampilkan [builder].
  /// Contoh: 'admin', 'ahli_gizi', 'pasien'.
  final String requiredRole;

  /// Builder yang akan dipanggil jika role pengguna sesuai dengan [requiredRole].
  final WidgetBuilder builder;

  /// Builder opsional yang akan dipanggil jika role pengguna *tidak* sesuai.
  /// Jika null, [SizedBox.shrink] (widget kosong) akan digunakan.
  final WidgetBuilder? nonRoleBuilder;

  /// Widget opsional yang ditampilkan saat data role sedang dimuat.
  /// Jika null, [SizedBox.shrink] (widget kosong) akan digunakan.
  final Widget? loadingWidget;

  const RoleBuilder({
    super.key,
    required this.requiredRole,
    required this.builder,
    this.nonRoleBuilder,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Dapatkan pengguna yang sedang login dari FirebaseAuth
    final User? user = FirebaseAuth.instance.currentUser;

    // 2. Jika tidak ada pengguna yang login, tampilkan nonRoleBuilder
    if (user == null) {
      return nonRoleBuilder?.call(context) ?? const SizedBox.shrink();
    }

    // 3. Jika ada pengguna, dengarkan data-nya dari Firestore
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      // Asumsi koleksi Anda bernama 'users' dan dokumennya menggunakan UID
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        // 4. Saat sedang memuat data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ?? const SizedBox.shrink();
        }

        // 5. Jika ada error atau tidak ada data
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return nonRoleBuilder?.call(context) ?? const SizedBox.shrink();
        }

        // 6. Dapatkan data pengguna dan role-nya
        final userData = snapshot.data!.data();
        final userRole = userData?['role'] as String?;

        // 7. Bandingkan role
        if (userRole == requiredRole) {
          // Role sesuai, tampilkan widget utama
          return builder(context);
        } else {
          // Role tidak sesuai, tampilkan nonRoleBuilder
          return nonRoleBuilder?.call(context) ?? const SizedBox.shrink();
        }
      },
    );
  }
}