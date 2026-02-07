import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Definisi Role yang terstandarisasi
enum UserRole {
  admin,
  ahliGizi,
  tamu,
  unknown,
}

// Extension untuk menangani properti tampilan dan logika bisnis Role
extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin: return 'Admin';
      case UserRole.ahliGizi: return 'Ahli Gizi';
      case UserRole.tamu: return 'Tamu'; // Default tamu jika user baru
      default: return 'Tidak Diketahui';
    }
  }

  // Warna badge berdasarkan role
  Color get color {
    switch (this) {
      case UserRole.admin: return Colors.redAccent;
      case UserRole.ahliGizi: return Colors.green;
      case UserRole.tamu: return Colors.grey;
      default: return Colors.black;
    }
  }

  // Nilai string untuk disimpan ke Firestore
  String get toFirestoreValue {
    switch (this) {
      case UserRole.admin: return 'admin';
      case UserRole.ahliGizi: return 'ahli_gizi'; // Sesuaikan dengan database Anda
      case UserRole.tamu: return 'tamu';
      default: return 'tamu';
    }
  }

  // Logika Prioritas Pengurutan (Angka lebih kecil = Lebih tinggi)
  int get priority {
    switch (this) {
      case UserRole.admin: return 1;
      case UserRole.ahliGizi: return 2;
      case UserRole.tamu: return 3;
      default: return 4;
    }
  }

  // Konversi dari String Firestore ke Enum
  static UserRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'admin': return UserRole.admin;
      case 'ahli_gizi': 
      case 'ahligizi': return UserRole.ahliGizi;
      case 'tamu': return UserRole.tamu;
      default: return UserRole.tamu; // Default fallback
    }
  }
}

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final String? photoUrl;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.photoUrl,
  });

  // Factory method untuk konversi aman dari DocumentSnapshot
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      // Menangani kemungkinan nama field berbeda (nama vs displayName)
      displayName: data['displayName'] ?? data['nama'] ?? 'Tanpa Nama',
      role: UserRoleExtension.fromString(data['role']),
      photoUrl: data['photoURL'],
    );
  }

  // Method untuk pencarian (Case insensitive logic helper)
  bool matchesSearch(String query) {
    final q = query.toLowerCase();
    return email.toLowerCase().contains(q) || displayName.toLowerCase().contains(q);
  }
}