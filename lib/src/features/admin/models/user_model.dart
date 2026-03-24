import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Definisi Role yang terstandarisasi
enum UserRole {
  admin,
  ahliGizi,     // Role lama (Legacy) - dipertahankan agar data lama tidak error
  nutrisionis,  // Role baru
  tamu,
  unknown,
}

// Extension untuk menangani properti tampilan dan logika bisnis Role
extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin: return 'Admin';
      case UserRole.ahliGizi: return 'Nutrisionis'; // Data lama juga ditampilkan sebagai Nutrisionis
      case UserRole.nutrisionis: return 'Nutrisionis'; 
      case UserRole.tamu: return 'Tamu';
      default: return 'Tidak Diketahui';
    }
  }

  // Warna badge berdasarkan role
  Color get color {
    switch (this) {
      case UserRole.admin: return Colors.redAccent;
      case UserRole.ahliGizi: 
      case UserRole.nutrisionis: return Colors.green; // Berlaku untuk keduanya
      case UserRole.tamu: return Colors.grey;
      default: return Colors.black;
    }
  }

  // Nilai string untuk disimpan ke Firestore
  String get toFirestoreValue {
    switch (this) {
      case UserRole.admin: return 'admin';
      case UserRole.ahliGizi: return 'ahli_gizi'; // Biarkan data lama tersimpan apa adanya
      case UserRole.nutrisionis: return 'nutrisionis'; // Format baru
      case UserRole.tamu: return 'tamu';
      default: return 'tamu';
    }
  }

  // Logika Prioritas Pengurutan (Angka lebih kecil = Lebih tinggi)
  int get priority {
    switch (this) {
      case UserRole.admin: return 1;
      case UserRole.ahliGizi: 
      case UserRole.nutrisionis: return 2;
      case UserRole.tamu: return 3;
      default: return 4;
    }
  }

  // Konversi dari String Firestore ke Enum
  static UserRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'admin': return UserRole.admin;
      case 'ahli_gizi': 
      case 'ahligizi': return UserRole.ahliGizi; // Membaca data lama
      case 'nutrisionis': return UserRole.nutrisionis; // Membaca data baru
      case 'tamu': return UserRole.tamu;
      default: return UserRole.tamu; // Default fallback
    }
  }
  bool get isNutrisionis {
    return this == UserRole.ahliGizi || this == UserRole.nutrisionis;
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

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? data['nama'] ?? 'Tanpa Nama',
      role: UserRoleExtension.fromString(data['role']),
      photoUrl: data['photoURL'],
    );
  }

  bool matchesSearch(String query) {
    final q = query.toLowerCase();
    return email.toLowerCase().contains(q) || displayName.toLowerCase().contains(q);
  }
}