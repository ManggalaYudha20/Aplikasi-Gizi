// lib/src/features/pdf_leaflets/presentation/widgets/leaflet_card_widget.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/data/models/leaflet_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/pdf_viewer_page.dart';

/// Widget kartu publik yang merepresentasikan satu item Leaflet dalam daftar.
/// Diekstrak dari class private _LeafletListItem di leaflet_list_page.dart.
class LeafletCardWidget extends StatelessWidget {
  final Leaflet leaflet;
  final double screenWidth;

  const LeafletCardWidget({
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