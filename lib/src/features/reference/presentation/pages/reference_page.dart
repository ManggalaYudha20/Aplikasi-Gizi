// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\reference\presentation\pages\reference_page.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';

// Import file yang telah dipisahkan
import '../../data/models/reference_data.dart';
import '../../widgets/reference_widgets.dart';

// 1. Ubah menjadi StatefulWidget
class ReferencePage extends StatefulWidget {
  const ReferencePage({super.key});

  @override
  State<ReferencePage> createState() => _ReferencePageState();
}

class _ReferencePageState extends State<ReferencePage> {
  // 2. Deklarasikan ScrollController
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    // 3. Jangan lupa dispose untuk mencegah memory leak
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(
        title: 'Referensi',
        subtitle: 'Sumber Data dan Rumus Perhitungan',
      ),
      body: Scrollbar(
        controller: _scrollController, // 4. Pasang controller di Scrollbar
        thumbVisibility: false,
        thickness: 6.0,
        radius: const Radius.circular(10),
        child: SingleChildScrollView(
          controller:
              _scrollController, // 5. Pasang controller yang sama di SingleChildScrollView
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, 'Sumber Data'),
              const SizedBox(height: 10),

              // Mapping Data Sources dari reference_data.dart
              ...ReferenceData.dataSources.map(
                (source) => DataSourceCard(
                  key: ValueKey(source.id),
                  semanticId: source.id,
                  title: source.title,
                  description: source.description,
                  icon: source.icon,
                ),
              ),

              const SizedBox(height: 25),
              _buildSectionTitle(context, 'Rumus Perhitungan'),
              const SizedBox(height: 10),

              ...ReferenceData.formulas.map(
                (formula) => FormulaTile(
                  key: ValueKey(formula.id),
                  semanticId: formula.id,
                  title: formula.title,
                  formulaName: formula.formulaName,
                  formulaContent: formula.formulaContent,
                  note: formula.note,
                ),
              ),

              const SizedBox(height: 25),
              _buildSectionTitle(context, 'Tabel Referensi'),
              const SizedBox(height: 10),

              ...ReferenceData.referenceTables.map(
                (table) => ReferenceTableWidget(
                  key: ValueKey(table.id),
                  semanticId: table.id,
                  title: table.title,
                  subtitle: table.subtitle,
                  headers: table.headers,
                  data: table.data,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
