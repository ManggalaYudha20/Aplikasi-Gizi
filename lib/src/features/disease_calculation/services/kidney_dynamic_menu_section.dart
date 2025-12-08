// lib/src/features/disease_calculation/presentation/widgets/kidney_dynamic_menu_section.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/kidney_menu_models.dart';
// Import file generator PDF yang baru dibuat
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/pdf_generator_kidney.dart'; 

class KidneyDynamicMenuSection extends StatefulWidget {
  final bool isLoading;
  final List<KidneyMealSession>? generatedMenu;
  final Function(KidneyMenuItem item, int sessionIndex, int itemIndex) onEditItem;
  // Tambahkan field nama pasien (opsional, default 'Pasien')
  final String patientName;

  const KidneyDynamicMenuSection({
    super.key,
    required this.isLoading,
    required this.generatedMenu,
    required this.onEditItem,
    this.patientName = "Pasien", // Default value
  });

  @override
  State<KidneyDynamicMenuSection> createState() => _KidneyDynamicMenuSectionState();
}

class _KidneyDynamicMenuSectionState extends State<KidneyDynamicMenuSection> {
  // State lokal untuk loading saat download PDF
  bool _isDownloadingPdf = false;

  // Fungsi handle download
  Future<void> _handleDownloadPdf() async {
    if (widget.generatedMenu == null || widget.generatedMenu!.isEmpty) return;

    setState(() => _isDownloadingPdf = true);

    try {
      // Panggil fungsi dari file pdf_generator_kidney.dart
      await saveAndOpenKidneyPdf(widget.generatedMenu!, widget.patientName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mencetak PDF: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloadingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Tampilan saat Loading Menu
    if (widget.isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Column(
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Sedang menyusun rekomendasi menu...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // 2. Tampilan jika menu belum ada / gagal
    if (widget.generatedMenu == null || widget.generatedMenu!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("Menu belum tersedia atau gagal dimuat.", style: TextStyle(color: Colors.grey)),
      );
    }

    // 3. Tampilan Menu Makanan (List Card) + Tombol PDF
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, // Agar tombol full width
      children: [
        
        // --- LIST MENU ---
        ...widget.generatedMenu!.map((session) {
          int sessionIndex = widget.generatedMenu!.indexOf(session);
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                  child: Text(
                    session.sessionName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16, 
                      color: Colors.teal.shade800
                    ),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: session.items.length,
                  itemBuilder: (ctx, idx) {
                    final item = session.items[idx];
                    return ListTile(
                      title: Text(
                        item.foodName, 
                        style: const TextStyle(fontWeight: FontWeight.w600)
                      ),
                      subtitle: Text(
                        "${item.categoryLabel} • ${item.weight.toStringAsFixed(0)}g (${item.urt})"
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                        onPressed: () => widget.onEditItem(item, sessionIndex, idx),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }).toList(),

         // --- TOMBOL DOWNLOAD PDF ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: ElevatedButton.icon(
            onPressed: _isDownloadingPdf ? null : _handleDownloadPdf,
            style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Tetap Biru
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
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : const Icon(Icons.download),
            label: Text( "Download Menu PDF",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}