import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart'; // <-- IMPORT BARU
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/leaflet_list_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/edit_leaflet_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/delete_leaflet_service.dart';

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
  final bool isAhliGizi = true;

  late final PdfViewerController _pdfViewerController;
  late final TextEditingController _searchController;
  PdfTextSearchResult _searchResult = PdfTextSearchResult();

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // =======================================================================
  // == FUNGSI DOWNLOAD YANG SUDAH DIPERBARUI ==
  // =======================================================================
  Future<void> _downloadPdf() async {
    bool hasPermission = false;

    // 1. Cek versi Android untuk menentukan izin yang diperlukan
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      if (deviceInfo.version.sdkInt >= 33) {
        // Android 13+
        // Tidak perlu izin sama sekali untuk menyimpan ke folder publik
        hasPermission = true;
      } else {
        // Android 12 dan di bawahnya
        final status = await Permission.storage.request();
        hasPermission = status.isGranted;
      }
    } else {
      // Untuk iOS atau platform lain, asumsikan izin sudah ada
      hasPermission = true;
    }

    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin penyimpanan ditolak.')),
        );
      }
      return;
    }

    // 2. Lanjutkan proses download jika izin diberikan
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mengunduh leaflet...')));

      // 3. Dapatkan direktori Downloads
      final Directory? downloadsDir = await getExternalStoragePublicDirectory(
        'Download', // Gunakan konstanta string yang benar
      );
      if (downloadsDir == null) {
        throw 'Tidak dapat menemukan direktori Downloads.';
      }

      final String fileName = widget.title.replaceAll(
        RegExp(r'[^a-zA-Z0-9]'),
        '_',
      );
      final filePath = '${downloadsDir.path}/$fileName.pdf';

      // 4. Gunakan Dio untuk mengunduh file
      await Dio().download(widget.url, filePath);

      // 5. Tampilkan pesan sukses
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil diunduh di folder Downloads!'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengunduh: $e')));
      }
    }
  }

  // Sisa kode tidak berubah...

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cari Teks'),
          content: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Masukkan kata kunci...',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchResult = _pdfViewerController.searchText(
                    _searchController.text,
                  );
                });
                Navigator.of(context).pop();
              },
              child: const Text('Cari'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 0, 148, 68)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Leaflet Informasi Gizi',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.title,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          if (_searchResult.totalInstanceCount > 0)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up),
                  onPressed: () {
                    _searchResult.previousInstance();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down),
                  onPressed: () {
                    _searchResult.nextInstance();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchResult.clear();
                      _searchController.clear();
                    });
                  },
                ),
              ],
            ),
        ],
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton.small(
                onPressed: _downloadPdf,
                heroTag: 'download',
                tooltip: 'Unduh',
                child: const Icon(Icons.download),
              ),
              const SizedBox(width: 8),
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
            ],
          ),
          if (isAhliGizi && widget.leaflet != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  onPressed: () => DeleteLeafletService.handleLeafletDelete(
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
                    if (result == true && mounted) {
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
        ],
      ),
    );
  }
}

// Helper method to get the correct downloads directory
Future<Directory?> getExternalStoragePublicDirectory(String type) async {
  if (Platform.isAndroid) {
    // This is a simplified way to get the downloads directory
    // path_provider's getExternalStorageDirectory() points to the app's
    // external storage, and we can navigate from there.
    final directory = await getExternalStorageDirectory();
    if (directory != null) {
      // Typically the downloads folder is not directly accessible this way on newer Android.
      // A better approach is to use platform channels or a dedicated package if this fails.
      // However, for many devices, saving in the root of external storage is sufficient.
      // Let's try to get a more reliable downloads path.
      final downloadsDirectory = await getDownloadsDirectory();
      return downloadsDirectory;
    }
  }
  // For iOS and other platforms, getApplicationDocumentsDirectory is a safe default.
  return getApplicationDocumentsDirectory();
}
