import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/leaflet_list_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/pdf_viewer_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/leaflet_debug_page.dart';

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

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari leaflet...',
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
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: const CustomAppBar(
        title: 'Leaflet Informasi Gizi',
        subtitle: 'Pilih leaflet untuk dibaca',
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('leaflets').orderBy('title').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          const Text('Pastikan Anda memiliki koneksi internet', textAlign: TextAlign.center),
                        ],
                      ),
                    );
                  }
                  
                  if (!snapshot.hasData) {
                    return const Center(child: Text('Tidak ada data yang tersedia.'));
                  }
                  
                  final leaflets = snapshot.data!.docs;
                  
                  if (leaflets.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.description_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('Belum ada leaflet tersedia.'),
                          const SizedBox(height: 8),
                          const Text('Pastikan ada dokumen di koleksi "leaflets" di Firestore'),
                        ],
                      ),
                    );
                  }

                  // Filter leaflets based on search query
                  final filteredLeaflets = leaflets.where((doc) {
                    final leaflet = Leaflet.fromFirestore(doc);
                    return leaflet.title.toLowerCase().contains(_searchQuery) ||
                           leaflet.description.toLowerCase().contains(_searchQuery);
                  }).toList();

                  if (filteredLeaflets.isEmpty && _searchQuery.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text('Tidak ada leaflet yang cocok dengan "$_searchQuery"'),
                          const SizedBox(height: 8),
                          const Text('Coba kata kunci lain'),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredLeaflets.length,
                    itemBuilder: (context, index) {
                      try {
                        final leaflet = Leaflet.fromFirestore(filteredLeaflets[index]);
                        
                        // Debug: Print leaflet data
                        //debugPrint('Leaflet ${index + 1}: ${leaflet.title} - ${leaflet.url}');

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
                            title: Text(leaflet.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(leaflet.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              if (leaflet.url.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => PdfViewerPage(
                                      url: leaflet.url,
                                      title: leaflet.title,
                                    ),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      const begin = Offset(1.0, 0.0);
                                      const end = Offset.zero;
                                      const curve = Curves.easeInOut;
                                      
                                      var tween = Tween(begin: begin, end: end).chain(
                                        CurveTween(curve: curve),
                                      );
                                      
                                      return SlideTransition(
                                        position: animation.drive(tween),
                                        child: child,
                                      );
                                    },
                                    transitionDuration: const Duration(milliseconds: 300),
                                    reverseTransitionDuration: const Duration(milliseconds: 300),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('URL PDF tidak valid.')),
                                );
                              }
                            },
                          ),
                        );
                      } catch (e) {
                        debugPrint('Error parsing leaflet ${index + 1}: $e');
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const Icon(Icons.error, color: Colors.red),
                            title: Text('Error parsing document ${index + 1}'),
                            subtitle: Text('Error: $e'),
                          ),
                        );
                      }
                      
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}