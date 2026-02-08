// lib\src\features\pdf_leaflets\presentation\pages\edit_leaflet_service.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/add_leaflet_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/leaflet_list_model.dart';

class EditLeafletService {
  /// Membuka halaman AddLeafletPage dalam mode edit.
  /// Mengembalikan true jika pengguna berhasil menyimpan perubahan.
  static Future<bool?> showEditPage(BuildContext context, Leaflet leaflet) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddLeafletPage(leaflet: leaflet),
      ),
    );
    
    return result == true;
  }
}