// lib/src/features/pdf_leaflets/presentation/widgets/leaflet_card_widget.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/data/models/leaflet_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/pdf_viewer_page.dart';

class LeafletCardWidget extends StatelessWidget {
  final Leaflet leaflet;
  
  // screenWidth dihapus karena tidak lagi diperlukan

  const LeafletCardWidget({
    super.key,
    required this.leaflet,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Kartu leaflet berjudul ${leaflet.title}',
      button: true,
      child: Card(
        // Margin dinolkan karena GridView.builder sudah memberikan jarak (spacing)
        margin: EdgeInsets.zero, 
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // Center digunakan agar isi otomatis berada di tengah secara vertikal
        child: Center(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 4.0,
              horizontal: 16.0,
            ),
            leading: const Icon(
              Icons.picture_as_pdf,
              color: Colors.red,
              size: 40.0, // Ukuran ikon yang pas dan standar
            ),
            title: Text(
              leaflet.title,
              maxLines: 1, // Mencegah judul panjang merusak tinggi card
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            subtitle: Text(
              leaflet.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.0),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToViewer(context),
          ),
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