// lib\src\features\pdf_leaflets\presentation\pages\leaflet_list_page.dart

import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/add_leaflet_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/leaflet_list_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/pdf_viewer_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  Widget build(BuildContext context) {
    // Responsive Variables
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.04; // 4% dari lebar layar
    final verticalPadding = screenWidth * 0.03;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(title: 'Leaflet Edukasi Gizi', subtitle: 'Pilih Leaflet Untuk dibaca'), // Sesuaikan dengan nama class AppBar Anda
      body: Column(
        children: [
          // Area Pencarian
         Container(
            margin: EdgeInsets.fromLTRB(
              horizontalPadding,
              verticalPadding,
              horizontalPadding,
              verticalPadding / 2,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1), // Konsisten dengan UserSearchBar
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
                  hintText: 'Cari Leaflet...', // Disesuaikan konteks
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  // Menambahkan tombol Clear jika ada teks (konsisten dengan UserSearchBar)
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            // SetState dipanggil otomatis oleh listener di initState
                          },
                        )
                      : null,
                  border: InputBorder.none, // Border dihilangkan karena sudah ada di Container
                  contentPadding: EdgeInsets.symmetric(
                    vertical: verticalPadding,
                    horizontal: horizontalPadding,
                  ),
                ),
              ),
            ),
          ),
          // Daftar Leaflet
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('leaflets').snapshots(),
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
                final leaflets = data.map((doc) {
                  return Leaflet.fromFirestore(
                    doc as DocumentSnapshot<Map<String, dynamic>>,
                  );
                }).where((leaflet) {
                  return leaflet.title.toLowerCase().contains(_searchQuery);
                }).toList();

                if (leaflets.isEmpty) {
                  return const Center(
                    key: Key('empty_state_message'),
                    child: Text('Tidak ada leaflet ditemukan.'),
                  );
                }

                return ListView.builder(
                  key: const Key('leaflet_list_view'),
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  itemCount: leaflets.length,
                  itemBuilder: (context, index) {
                    return _LeafletListItem(
                      key: Key('leaflet_item_$index'), // Unique Key per item
                      leaflet: leaflets[index],
                      screenWidth: screenWidth,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // PERBAIKAN DI SINI: Menggunakan parameter yang benar untuk RoleBuilder
      floatingActionButton: RoleBuilder(
        requiredRole: 'admin', // Role yang dibutuhkan
        builder: (context) => Semantics( // Widget jika role = admin
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
        nonRoleBuilder: (context) => const SizedBox.shrink(), // Widget jika bukan admin
      ),
    );
  }
}

class _LeafletListItem extends StatelessWidget {
  final Leaflet leaflet;
  final double screenWidth;

  const _LeafletListItem({
    super.key,
    required this.leaflet,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    // Dynamic sizing based on screen width
    final iconSize = screenWidth * 0.1; // 10% dari lebar layar
    final titleSize = screenWidth * 0.045;
    
    return Semantics(
      label: 'Kartu leaflet berjudul ${leaflet.title}',
      button: true,
      child: Card(
        margin: EdgeInsets.only(bottom: screenWidth * 0.03),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            vertical: screenWidth * 0.02,
            horizontal: screenWidth * 0.04,
          ),
          leading: Icon(
            Icons.picture_as_pdf,
            color: Colors.red,
            size: iconSize.clamp(30.0, 50.0), // Min 30, Max 50
          ),
          title: Text(
            leaflet.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: titleSize.clamp(14.0, 18.0),
            ),
          ),
          subtitle: Text(
            leaflet.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: (titleSize - 2).clamp(12.0, 16.0)),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _navigateToViewer(context),
        ),
      ),
    );
  }

  void _navigateToViewer(BuildContext context) {
    if (leaflet.url.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerPage(
            url: leaflet.url,
            title: leaflet.title,
            leaflet: leaflet,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL PDF tidak ditemukan.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}