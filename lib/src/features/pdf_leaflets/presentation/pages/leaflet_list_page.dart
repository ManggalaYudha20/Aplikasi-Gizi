//lib\src\features\pdf_leaflets\presentation\pages\leaflet_list_page.dart

import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/add_leaflet_page.dart'; // Import halaman baru
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/leaflet_list_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/pdf_viewer_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeafletListPage extends StatefulWidget {
  const LeafletListPage({super.key});

  @override
  State<LeafletListPage> createState() => _LeafletListPageState();
}

class _LeafletListPageState extends State<LeafletListPage> {
  // --- PERSIAPAN UNTUK LEVEL AKSES ---
  // Untuk saat ini, kita buat variabel sederhana.
  // Nantinya, nilai ini akan didapat dari status login pengguna.
  final bool isAhliGizi = true; // Ganti menjadi 'false' untuk menyembunyikan tombol
  
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

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 5),
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
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari judul atau deskripsi leaflet...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: const CustomAppBar(
        title: 'Leaflet Edukasi Gizi',
        subtitle: 'Pilih leaflet untuk dibaca',
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('leaflets').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.picture_as_pdf_outlined, size: 60, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Belum ada leaflet tersedia', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    );
                  }
                  
                  final allLeaflets = snapshot.data!.docs;
                  final filteredLeaflets = allLeaflets.where((doc) {
                    final leaflet = Leaflet.fromFirestore(doc);
                    final query = _searchQuery.toLowerCase();
                    return leaflet.title.toLowerCase().contains(query) ||
                           leaflet.description.toLowerCase().contains(query);
                  }).toList();
                  
                  if (filteredLeaflets.isEmpty && _searchQuery.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 60, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada leaflet yang cocok dengan pencarian "$_searchQuery"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredLeaflets.length,
                    itemBuilder: (context, index) {
                      final leaflet = Leaflet.fromFirestore(filteredLeaflets[index]);
                      return _LeafletListItem(leaflet: leaflet);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // --- TAMBAHKAN TOMBOL INI ---
      floatingActionButton: isAhliGizi
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddLeafletPage()),
                );
              },
              backgroundColor: const Color.fromARGB(255, 0, 148, 68),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null, // Jika bukan ahli gizi, tombol tidak akan tampil
    );
  }
}

// Widget _LeafletListItem tetap sama seperti sebelumnya
class _LeafletListItem extends StatelessWidget {
  final Leaflet leaflet;
  const _LeafletListItem({required this.leaflet});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
        title: Text(leaflet.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          leaflet.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (leaflet.url.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PdfViewerPage(
                  url: leaflet.url,
                  title: leaflet.title,
                  leaflet: leaflet, // Pass the complete leaflet object
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('URL PDF tidak ditemukan.')),
            );
          }
        },
      ),
    );
  }
}