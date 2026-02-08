// lib\src\features\pdf_leaflets\presentation\pages\pdf_viewer_page.dart

import 'package:flutter/material.dart';
// Menggunakan alias untuk menghindari konflik dengan widget atau class lain yang bernama 'Share'
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
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  @override
  Widget build(BuildContext context) {
    // Memastikan layout aman dari notch/system bars
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: const Color.fromARGB(255, 0, 148, 68),
          foregroundColor: Colors.white,
          actions: [
            Semantics(
              label: 'Bagikan PDF',
              button: true,
              child: IconButton(
                key: const Key('pdf_share_button'),
                icon: const Icon(Icons.share),
                onPressed: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text:
                          'Lihat leaflet gizi "${widget.title}" di link berikut: ${widget.url}',
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        body: SfPdfViewer.network(
          widget.url,
          controller: _pdfViewerController,
          key: _pdfViewerKey,
          canShowScrollHead: true,
          canShowScrollStatus: true,
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

        floatingActionButton: RoleBuilder(
          requiredRole: 'admin', // Role yang dibutuhkan
          // Builder dijalankan jika user adalah admin
          builder: (context) {
            if (widget.leaflet == null) return const SizedBox.shrink();

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      label: 'Hapus Leaflet',
                      button: true,
                      child: FloatingActionButton.small(
                        key: const Key('pdf_delete_button'),
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
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      label: 'Edit Leaflet',
                      button: true,
                      child: FloatingActionButton.small(
                        key: const Key('pdf_edit_button'),
                        onPressed: () async {
                          final result = await EditLeafletService.showEditPage(
                            context,
                            widget.leaflet!,
                          );
                          // Jika ada perubahan, kembali ke halaman list untuk refresh
                          if (result == true && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        heroTag: 'edit',
                        tooltip: 'Edit',
                        backgroundColor: const Color.fromARGB(255, 0, 148, 68),
                        child: const Icon(Icons.edit, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },

          // Builder dijalankan jika user BUKAN admin (atau belum login)
          nonRoleBuilder: (context) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
