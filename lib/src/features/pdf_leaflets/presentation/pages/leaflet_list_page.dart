// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\pdf_leaflets\presentation\pages\leaflet_list_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/data/models/leaflet_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/add_leaflet_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/widgets/leaflet_card_widget.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/role_builder.dart';

class LeafletListPage extends StatefulWidget {
  const LeafletListPage({super.key});

  @override
  State<LeafletListPage> createState() => _LeafletListPageState();
}

class _LeafletListPageState extends State<LeafletListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Fungsi Penentu Jumlah Kolom ---
  int _getCrossAxisCount(double screenWidth) {
    if (screenWidth >= 1200) return 3; // Desktop
    if (screenWidth >= 800) return 2; // Tablet
    return 1; // Mobile
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(
        title: 'Leaflet Edukasi Gizi',
        subtitle: 'Pilih Leaflet Untuk dibaca',
      ),
      body: Column(
        children: [
          // Area Pencarian (Dibatasi maksimal lebarnya agar rapi di layar besar)
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Semantics(
                  label: 'Input pencarian leaflet',
                  textField: true,
                  child: TextField(
                    key: const Key('leaflet_search_field'),
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari Leaflet...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      border: InputBorder.none,
                      // Padding vertikal dibuat fixed agar tidak terlalu lebar (gemuk)
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14.0,
                        horizontal: 16.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Daftar Leaflet (Menggunakan GridView agar responsif)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('leaflets')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    key: Key('error_message'),
                    child: Text('Terjadi kesalahan memuat data.'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!.docs;
                final leaflets = data
                    .map(
                      (doc) => Leaflet.fromFirestore(
                        doc as DocumentSnapshot<Map<String, dynamic>>,
                      ),
                    )
                    .where(
                      (leaflet) =>
                          leaflet.title.toLowerCase().contains(_searchQuery),
                    )
                    .toList();

                if (leaflets.isEmpty) {
                  return const Center(
                    key: Key('empty_state_message'),
                    child: Text('Tidak ada leaflet ditemukan.'),
                  );
                }

                return GridView.builder(
                  key: const Key('leaflet_list_view'),
                  padding: const EdgeInsets.only(
                    bottom: 80, // Ruang untuk FloatingActionButton
                    left: 16,
                    right: 16,
                    top: 8,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(screenWidth),
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                    mainAxisExtent:
                        100.0, // Sesuaikan tinggi ideal Card di sini
                  ),
                  itemCount: leaflets.length,
                  itemBuilder: (context, index) {
                    return LeafletCardWidget(
                      key: Key('leaflet_item_$index'),
                      leaflet: leaflets[index],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: RoleBuilder(
        requiredRole: 'admin',
        builder: (context) => Semantics(
          label: 'Tombol tambah leaflet baru',
          button: true,
          child: FloatingActionButton(
            key: const Key('add_leaflet_fab'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddLeafletPage()),
              );
            },
            backgroundColor: const Color.fromARGB(255, 0, 148, 68),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
        nonRoleBuilder: (context) => const SizedBox.shrink(),
      ),
    );
  }
}
