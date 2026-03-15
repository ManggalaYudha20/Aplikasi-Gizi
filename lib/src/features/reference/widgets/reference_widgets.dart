import 'package:flutter/material.dart';

/// Widget untuk menampilkan kartu Sumber Data
class DataSourceCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String semanticId;

  const DataSourceCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.semanticId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Semantics(
      identifier: semanticId,
      label: 'Kartu sumber data: $title',
      child: Card(
        // Key digunakan oleh Katalon untuk menemukan objek
        key: ValueKey(semanticId),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget untuk menampilkan Tile Rumus yang bisa di-expand
class FormulaTile extends StatelessWidget {
  final String title;
  final String formulaName;
  final Widget formulaContent;
  final String note;
  final String semanticId;

  const FormulaTile({
    super.key,
    required this.title,
    required this.formulaName,
    required this.formulaContent,
    required this.note,
    required this.semanticId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: ValueKey('${semanticId}_card'),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        key: ValueKey('${semanticId}_expansion'),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          formulaName,
          style: TextStyle(fontSize: 12, color: theme.hintColor),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha:0.3), // Pengganti grey[50]
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Rumus:",
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: formulaContent),
                ),
                const SizedBox(height: 10),
                Text(
                  "Catatan:",
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  note,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget untuk Tabel Referensi
class ReferenceTableWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<String> headers;
  final List<List<String>> data;
  final String semanticId;

  const ReferenceTableWidget({
    super.key,
    required this.title,
    this.subtitle,
    required this.headers,
    required this.data,
    required this.semanticId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: ValueKey('${semanticId}_card'),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        key: ValueKey('${semanticId}_expansion'),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          subtitle ?? "Klik untuk melihat tabel",
          style: TextStyle(fontSize: 12, color: theme.hintColor),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Table(
              border: TableBorder.all(
                color: theme.dividerColor,
                width: 1,
                borderRadius: BorderRadius.circular(8),
              ),
              columnWidths: const {
                0: FlexColumnWidth(1.2),
                1: FlexColumnWidth(0.8),
              },
              children: [
                // --- Header Row ---
                TableRow(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha:0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                  children: headers.map((header) {
                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        header,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }).toList(),
                ),
                // --- Data Rows ---
                ...data.map((row) {
                  return TableRow(
                    children: row.map((cellData) {
                      return Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          cellData,
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper Widget untuk menampilkan Pecahan Matematika
class FractionText extends StatelessWidget {
  final String numerator;
  final String denominator;

  const FractionText(this.numerator, this.denominator, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          numerator,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          height: 1.5,
          width: double.infinity,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        Text(
          denominator,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}