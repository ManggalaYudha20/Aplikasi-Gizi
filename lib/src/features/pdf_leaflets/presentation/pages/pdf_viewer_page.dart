import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/leaflet_list_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/edit_leaflet_service.dart';

class PdfViewerPage extends StatefulWidget {
  final String url;
  final String title;
  final Leaflet? leaflet; // Optional leaflet data for editing

  const PdfViewerPage({
    super.key,
    required this.url,
    required this.title,
    this.leaflet,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  // For now, we'll assume only nutritionists can edit
  // This should be replaced with actual user role checking
  final bool isAhliGizi = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: CustomAppBar(
        title: 'Leaflet Informasi Gizi' ,
        subtitle: widget.title ,
      ),
      body: SfPdfViewer.network(
        widget.url,
        // Menampilkan loading indicator saat PDF dimuat
        canShowScrollHead: true,
        canShowPaginationDialog: true,
      ),
      floatingActionButton: isAhliGizi && widget.leaflet != null
          ? FloatingActionButton(
              onPressed: () async {
                final result = await EditLeafletService.showEditPage(
                  context,
                  widget.leaflet!,
                );
                if (result == true && mounted) {
                  // If edit was successful, refresh the page or go back
                  Navigator.of(context).pop();
                }
              },
              backgroundColor: const Color.fromARGB(255, 0, 148, 68),
              child: const Icon(Icons.edit, color: Colors.white),
            )
          : null,
    );
  }
}