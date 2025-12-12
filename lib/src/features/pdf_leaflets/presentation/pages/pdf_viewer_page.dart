//lib\src\features\pdf_leaflets\presentation\pages\pdf_viewer_page.dart

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/leaflet_list_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/edit_leaflet_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/delete_leaflet_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/role_builder.dart';

class PdfViewerPage extends StatefulWidget {
  final String url;
  final String title;
  final Leaflet? leaflet;

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
  late final PdfViewerController _pdfViewerController;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 0, 148, 68)),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
      ),
      body: SfPdfViewer.network(
        widget.url,
        controller: _pdfViewerController,
        canShowScrollHead: true,
        canShowPaginationDialog: true,
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              tooltip: 'Halaman Sebelumnya',
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => _pdfViewerController.previousPage(),
            ),
            IconButton(
              tooltip: 'Perkecil',
              icon: const Icon(Icons.zoom_out),
              onPressed: () => _pdfViewerController.zoomLevel -= 0.25,
            ),
            IconButton(
              tooltip: 'Perbesar',
              icon: const Icon(Icons.zoom_in),
              onPressed: () => _pdfViewerController.zoomLevel += 0.25,
            ),
            IconButton(
              tooltip: 'Halaman Berikutnya',
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: () => _pdfViewerController.nextPage(),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Tombol Share (Download Dihapus)
          FloatingActionButton.small(
            onPressed: () {
              SharePlus.instance.share(
                ShareParams(
                  text:
                      'Lihat leaflet gizi "${widget.title}" di link berikut: ${widget.url}',
                ),
              );
            },
            heroTag: 'share',
            tooltip: 'Bagikan',
            child: const Icon(Icons.share),
          ),

          RoleBuilder(
            requiredRole: 'admin',
            builder: (context) {
              // Pastikan juga widget.leaflet tidak null
              if (widget.leaflet == null) {
                return const SizedBox.shrink();
              }

              // Jika role adalah 'admin' dan leaflet ada, tampilkan tombol:
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FloatingActionButton.small(
                        onPressed: () =>
                            DeleteLeafletService.handleLeafletDelete(
                              context: context,
                              leaflet: widget.leaflet!,
                            ),
                        heroTag: 'delete',
                        tooltip: 'Hapus',
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton.small(
                        onPressed: () async {
                          final result = await EditLeafletService.showEditPage(
                            context,
                            widget.leaflet!,
                          );
                          if (result == true && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        heroTag: 'edit',
                        tooltip: 'Edit',
                        backgroundColor: const Color.fromARGB(255, 0, 148, 68),
                        child: const Icon(Icons.edit, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
