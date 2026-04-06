// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\kidney_calculation\presentation\widgets\kidney_dynamic_menu_section.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/data/models/kidney_menu_models.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/services/pdf_generator_kidney.dart';

/// Section widget untuk menampilkan rekomendasi menu harian dinamis diet ginjal,
/// lengkap dengan tombol edit item dan download PDF.
class KidneyDynamicMenuSection extends StatefulWidget {
  final bool isLoading;
  final List<KidneyMealSession>? generatedMenu;
  final Function(KidneyMenuItem item, int sessionIndex, int itemIndex)
  onEditItem;
  final String patientName;

  const KidneyDynamicMenuSection({
    super.key,
    required this.isLoading,
    required this.generatedMenu,
    required this.onEditItem,
    this.patientName = 'Pasien',
  });

  @override
  State<KidneyDynamicMenuSection> createState() =>
      _KidneyDynamicMenuSectionState();
}

class _KidneyDynamicMenuSectionState extends State<KidneyDynamicMenuSection> {
  bool _isDownloadingPdf = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleDownloadPdf() async {
    if (widget.generatedMenu == null || widget.generatedMenu!.isEmpty) return;

    setState(() => _isDownloadingPdf = true);

    try {
      await saveAndOpenKidneyPdf(
        widget.generatedMenu!,
        widget.patientName,
        _notesController.text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mencetak PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloadingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Loading ──────────────────────────────────────────────────────────────
    if (widget.isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: const Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text(
              'Sedang menyusun rekomendasi menu...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // ── Kosong / gagal ───────────────────────────────────────────────────────
    if (widget.generatedMenu == null || widget.generatedMenu!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Menu belum tersedia atau gagal dimuat.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // ── Konten menu ──────────────────────────────────────────────────────────
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Text(
              'Rekomendasi Menu Sehari',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ketuk ikon pensil untuk mengganti menu',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Divider(height: 30),

          // ── Daftar sesi makan ──────────────────────────────────────────────
          ...widget.generatedMenu!.map((session) {
            final sessionIndex = widget.generatedMenu!.indexOf(session);
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header sesi
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade100,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                    child: Text(
                      session.sessionName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.teal.shade800,
                      ),
                    ),
                  ),
                  // Daftar item
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: session.items.length,
                    itemBuilder: (ctx, idx) {
                      final item = session.items[idx];
                      return ListTile(
                        title: Text(
                          item.foodName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${item.categoryLabel} • '
                          '${item.weight.toStringAsFixed(0)}g (${item.urt})',
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () =>
                              widget.onEditItem(item, sessionIndex, idx),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }),

          // ── Catatan tambahan ───────────────────────────────────────────────
          const SizedBox(height: 16),
          const Divider(),
          const Text(
            'Catatan Tambahan (Opsional)',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Tulis anjuran khusus atau catatan untuk pasien disini...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue.shade200),
              ),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),

          // ── Tombol download PDF ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: _isDownloadingPdf ? null : _handleDownloadPdf,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              icon: _isDownloadingPdf
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.download),
              label: const Text(
                'Download Menu PDF',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
