import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Tambahkan import Firestore
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart'; 
import '../widgets/nutritionist_card.dart'; 
import 'nutritionist_profile_page.dart'; 

class ConsultationPage extends StatelessWidget {
  const ConsultationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Konsultasi Gizi',
        subtitle: 'Pilih Ahli Gizi untuk berdiskusi',
      ),
      body: SafeArea(
        // Menggunakan StreamBuilder untuk mengambil data dari Firestore secara realtime
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'ahli_gizi') // Asumsi role untuk ahli gizi di database adalah 'ahli_gizi'
              .snapshots(),
          builder: (context, snapshot) {
            // 1. Tampilkan loading spinner saat data sedang diambil
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // 2. Tangani jika terjadi error
            if (snapshot.hasError) {
              return const Center(
                child: Text('Terjadi kesalahan saat memuat data ahli gizi.'),
              );
            }

            // 3. Tangani jika data kosong
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('Belum ada ahli gizi yang tersedia saat ini.'),
              );
            }

            // 4. Jika data berhasil didapatkan
            final nutritionists = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: nutritionists.length,
              itemBuilder: (context, index) {
                // Ambil data tiap dokumen
                final data = nutritionists[index].data() as Map<String, dynamic>;
                final nutritionistId = nutritionists[index].id; // UID ahli gizi

                // Mapping data Firestore ke variabel, berikan nilai default jika field kosong/tidak ada
                final String name = data['displayName'] ?? 'Nama Tidak Diketahui';
                final String photoUrl = (data['photoURL'] != null && data['photoURL'].toString().isNotEmpty)
                    ? data['photoURL']
                    : 'https://via.placeholder.com/150'; // Gambar default jika user belum upload foto

                // Asumsi field tambahan ini Anda tambahkan manual ke dokumen Firestore ahli gizi
                final String spesialisasi = data['role'] ?? 'Ahli Gizi';
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
                    // Cek di terminal apakah tombol ditekan dan membawa data yang benar
                    debugPrint('Mulai chat dengan $name (UID: $nutritionistId)');
                    
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