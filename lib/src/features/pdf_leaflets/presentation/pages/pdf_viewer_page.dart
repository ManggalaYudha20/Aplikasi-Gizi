import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/leaflet_list_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/edit_leaflet_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/delete_leaflet_service.dart';

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
        title: 'Leaflet Informasi Gizi',
        subtitle: widget.title,
      ),
      body: SfPdfViewer.network(
        widget.url,
        // Menampilkan loading indicator saat PDF dimuat
        canShowScrollHead: true,
        canShowPaginationDialog: true,
      ),

      floatingActionButton: isAhliGizi && widget.leaflet != null
          ? Row(
              mainAxisAlignment:
                  MainAxisAlignment.end, // Agar tombol tetap di kanan
              children: [
                // Tombol Hapus (Delete)
                FloatingActionButton(
                  onPressed: () {
                    // Menampilkan dialog konfirmasi hapus
                    DeleteLeafletService.handleLeafletDelete(
                      context: context,
                      leaflet: widget.leaflet!,
                    );
                  },
                  backgroundColor: Colors.red,
                  heroTag: null, // Penting agar tidak konflik dengan FAB lain
                  child: const Icon(Icons.delete, color: Colors.white),
                ),

                const SizedBox(width: 16),

                FloatingActionButton(
                  onPressed: () async {
                    // Jadikan async
                    final result = await EditLeafletService.showEditPage(
                      context,
                      widget.leaflet!,
                    );
                    // Cek mounted setelah await
                    if (result == true && mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  backgroundColor: const Color.fromARGB(255, 0, 148, 68),
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
              ],
            )
          : null,
    );
  }
}
