//lib\src\features\pdf_leaflets\presentation\pages\leaflet_list_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Leaflet {
  final String id;
  final String title;
  final String description;
  final String url;

  Leaflet({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
  });

  // Pastikan nama field di sini (contoh: data['title'])
  // sama persis dengan yang ada di Firestore Anda
  factory Leaflet.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    
    return Leaflet(
      id: doc.id,
      title: data['title'] ?? 'Tanpa Judul',
      description: data['description'] ?? 'Tanpa Deskripsi',
      url: data['url'] ?? '',
    );
  }
}