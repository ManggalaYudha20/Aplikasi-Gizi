// lib\src\features\pdf_leaflets\presentation\pages\leaflet_list_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Model data untuk Leaflet PDF.
/// Merepresentasikan dokumen 'leaflets' dari Firestore.
class Leaflet {
  final String id;
  final String title;
  final String description;
  final String url;

  const Leaflet({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
  });

  /// Factory method untuk mengubah dokumen Firestore menjadi objek Leaflet.
  /// Menangani kemungkinan null value dengan nilai default yang aman.
  factory Leaflet.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    return Leaflet(
      id: doc.id,
      title: data['title'] as String? ?? 'Tanpa Judul',
      description: data['description'] as String? ?? 'Tanpa Deskripsi',
      url: data['url'] as String? ?? '',
    );
  }
}