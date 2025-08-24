import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';

class PdfViewerPage extends StatelessWidget {
  final String url;
  final String title;

  const PdfViewerPage({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: CustomAppBar(
        title: 'Leaflet Informasi Gizi' ,
        subtitle: title ,
      ),
      body: SfPdfViewer.network(
        url,
        // Menampilkan loading indicator saat PDF dimuat
        canShowScrollHead: true,
        canShowPaginationDialog: true,
      ),
    );
  }
}