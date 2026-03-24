import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart'; 
import '../widgets/nutritionist_card.dart'; 
import 'nutritionist_profile_page.dart'; 

class ConsultationPage extends StatelessWidget {
  const ConsultationPage({super.key});

  /// 1. Tambahkan fungsi ini untuk menentukan jumlah kolom dinamis
  int _getCrossAxisCount(double screenWidth) {
    if (screenWidth >= 1200) return 3; // Desktop lebar / Windows besar
    if (screenWidth >= 800) return 2;  // Tablet landscape / Windows kecil
    return 1;                          // Mobile (default, 1 kolom karena card memanjang)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Konsultasi Gizi',
        subtitle: 'Pilih Ahli Gizi untuk berdiskusi',
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', whereIn: ['ahli_gizi', 'nutrisionis'] )
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text('Terjadi kesalahan saat memuat data ahli gizi.'),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('Belum ada ahli gizi yang tersedia saat ini.'),
              );
            }

            final nutritionists = snapshot.data!.docs;

            // 2. Bungkus dengan LayoutBuilder untuk membaca lebar layar
            return LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                
                // 3. Ganti ListView.builder menjadi GridView.builder
                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(screenWidth), // Jumlah kolom responsif
                    crossAxisSpacing: 16.0, // Jarak horizontal antar card
                    mainAxisSpacing: 16.0,  // Jarak vertikal antar card
                    // 4. Gunakan mainAxisExtent agar tinggi card tetap proporsional (tidak gepeng)
                    mainAxisExtent: 200.0,  
                  ),
                  itemCount: nutritionists.length,
                  itemBuilder: (context, index) {
                    final data = nutritionists[index].data() as Map<String, dynamic>;
                    final nutritionistId = nutritionists[index].id;

                    final String name = data['displayName'] ?? 'Nama Tidak Diketahui';
                    final String photoUrl = (data['photoURL'] != null && data['photoURL'].toString().isNotEmpty)
                        ? data['photoURL']
                        : 'https://via.placeholder.com/150';

                    final String spesialisasi = data['role'] ?? 'Nutrisionis';
                    final String pengalaman = data['pengalaman'] ?? '0 tahun';
                    final String rating = data['rating'] ?? '0%';

                    return NutritionistCard(
                      name: name,
                      role: spesialisasi,
                      experience: pengalaman,
                      rating: rating,
                      imageUrl: photoUrl,
                      onCardTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NutritionistProfilePage(
                              nutritionistData: data,
                              nutritionistId: nutritionistId,
                            ),
                          ),
                        );
                      },
                      onChatPressed: () {
                        debugPrint('Mulai chat dengan $name (UID: $nutritionistId)');
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}