import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';

class NutritionistProfilePage extends StatelessWidget {
  final Map<String, dynamic> nutritionistData;
  final String nutritionistId;

  const NutritionistProfilePage({
    super.key,
    required this.nutritionistData,
    required this.nutritionistId,
  });

  @override
  Widget build(BuildContext context) {
    // Mapping data, berikan fallback jika null
    final String name = nutritionistData['displayName'] ?? 'Nama Tidak Diketahui';
    final String photoUrl = (nutritionistData['photoURL'] != null && nutritionistData['photoURL'].toString().isNotEmpty)
        ? nutritionistData['photoURL']
        : 'https://via.placeholder.com/150';
    final String role = nutritionistData['spesialisasi'] ?? 'Ahli Gizi';
    final String alumni = nutritionistData['alumni'] ?? 'Universitas Tidak Diketahui';
    final String strNumber = nutritionistData['nomor_str'] ?? '-';
    final String description = nutritionistData['deskripsi'] ?? 'Belum ada deskripsi profil untuk ahli gizi ini.';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Profil Ahli Gizi',
        subtitle: '',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian Header (Foto & Nama)
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(photoUrl),
                    backgroundColor: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            
            // Bagian Biodata
            const Text(
              'Biodata',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildBiodataRow(Icons.school, 'Alumnus', alumni),
            const SizedBox(height: 12),
            _buildBiodataRow(Icons.badge, 'No. STR', strNumber),
            const SizedBox(height: 24),
            
            // Bagian Deskripsi
            const Text(
              'Tentang',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 14, height: 1.5),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
      // Tombol Chat Mengambang di Bawah
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            key: const ValueKey('btn_profile_start_chat'),
            onPressed: () {
              debugPrint('Mulai chat dari profil dengan $name (UID: $nutritionistId)');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text(
              'Mulai Chat',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiodataRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}