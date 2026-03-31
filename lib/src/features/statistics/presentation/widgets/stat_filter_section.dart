// lib/src/features/statistics/presentation/widgets/stat_filter_section.dart

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import 'package:aplikasi_diagnosa_gizi/src/features/statistics/data/models/chart_data_model.dart';

/// Composite filter bar that groups three controls:
///
///   1. **Category dropdown** – selects which metric to display.
///   2. **Date-range popup menu** – filters the patient dataset by time window.
///   3. **Chart-type toggle** – switches between Pie and Bar views.
///
/// All state is lifted to the parent page; this widget is purely presentational.
class StatFilterSection extends StatelessWidget {
  const StatFilterSection({
    super.key,
    required this.categoryOptions,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.selectedFilterType,
    required this.filterLabel,
    required this.onFilterSelected,
    required this.chartType,
    required this.onChartTypeChanged,
    required this.spacing,
  });

  // ── Category dropdown ──────────────────────────────────────────────────────
  final List<String> categoryOptions;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  // ── Date filter ────────────────────────────────────────────────────────────
  final DateFilterType selectedFilterType;
  final String filterLabel;

  /// Called when the user picks a [DateFilterType].
  /// The parent is responsible for handling [DateFilterType.custom]
  /// (showing the date-range picker) and updating [filterLabel].
  final ValueChanged<DateFilterType> onFilterSelected;

  // ── Chart-type toggle ──────────────────────────────────────────────────────
  final String chartType; // 'Pie' | 'Bar'
  final ValueChanged<String> onChartTypeChanged;

  // ── Layout ─────────────────────────────────────────────────────────────────
  final double spacing;

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Category Label ────────────────────────────────────────────────────
        const Text(
          "Pilih Statistik:",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: spacing * 0.5),

        // ── Category Dropdown ─────────────────────────────────────────────────
        Semantics(
          identifier: 'stats_category_dropdown',
          label: 'Dropdown pilih kategori statistik, dipilih: $selectedCategory',
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing,
              vertical: spacing * 0.125,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownSearch<String>(
              items: categoryOptions,
              selectedItem: selectedCategory,
              onChanged: (newValue) {
                if (newValue != null) onCategoryChanged(newValue);
              },
              dropdownBuilder: (context, selectedItem) => Text(
                selectedItem ?? "",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              popupProps: PopupProps.menu(
                fit: FlexFit.tight,
                constraints: const BoxConstraints(maxHeight: 200),
                scrollbarProps: const ScrollbarProps(
                  thumbVisibility: true,
                  thickness: 6,
                  radius: Radius.circular(10),
                ),
                menuProps: MenuProps(
                  borderRadius: BorderRadius.circular(12),
                  elevation: 4,
                ),
              ),
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              dropdownButtonProps: const DropdownButtonProps(
                icon: Icon(Icons.category, color: Color(0xFF009444)),
              ),
            ),
          ),
        ),

        SizedBox(height: spacing * 1.5),

        // ── Date Filter Button ────────────────────────────────────────────────
        Semantics(
          identifier: 'stats_date_filter_btn',
          label: 'Tombol filter waktu, filter aktif: $filterLabel',
          button: true,
          child: PopupMenuButton<DateFilterType>(
            initialValue: selectedFilterType,
            onSelected: onFilterSelected,
            itemBuilder: (context) =>
                const <PopupMenuEntry<DateFilterType>>[
              PopupMenuItem(
                value: DateFilterType.thisWeek,
                child: Row(children: [
                  Icon(Icons.calendar_view_week, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('Minggu Ini'),
                ]),
              ),
              PopupMenuItem(
                value: DateFilterType.thisMonth,
                child: Row(children: [
                  Icon(Icons.calendar_month, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('Bulan Ini'),
                ]),
              ),
              PopupMenuItem(
                value: DateFilterType.thisYear,
                child: Row(children: [
                  Icon(Icons.calendar_today, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('Tahun Ini'),
                ]),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: DateFilterType.custom,
                child: Row(children: [
                  Icon(Icons.date_range, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('Pilih Tanggal Sendiri (Custom)'),
                ]),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: DateFilterType.all,
                child: Row(children: [
                  Icon(Icons.all_inclusive, color: Color(0xFF009444)),
                  SizedBox(width: 8),
                  Text(
                    'Semua Waktu (Reset)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF009444),
                    ),
                  ),
                ]),
              ),
            ],
            child: Container(
              margin: EdgeInsets.only(bottom: spacing),
              padding:
                  EdgeInsets.symmetric(horizontal: spacing, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF009444)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Filter Waktu:",
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      Text(
                        filterLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF009444),
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_drop_down,
                      color: Color(0xFF009444)),
                ],
              ),
            ),
          ),
        ),

        // ── Chart Type Toggle ─────────────────────────────────────────────────
       // ── Chart Type Toggle ─────────────────────────────────────────────────
        Align(
          alignment: Alignment.centerLeft, // Ubah ke Alignment.center jika ingin posisinya di tengah
          child: Semantics(
            identifier: 'stats_chart_type_toggle',
            label: 'Toggle jenis grafik, terpilih: $chartType',
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ChartTypeButton(
                    type: 'Pie',
                    icon: Icons.pie_chart,
                    selectedType: chartType,
                    onTap: onChartTypeChanged,
                  ),
                  _ChartTypeButton(
                    type: 'Bar',
                    icon: Icons.bar_chart,
                    selectedType: chartType,
                    onTap: onChartTypeChanged,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Private helper widget ──────────────────────────────────────────────────

class _ChartTypeButton extends StatelessWidget {
  const _ChartTypeButton({
    required this.type,
    required this.icon,
    required this.selectedType,
    required this.onTap,
  });

  final String type;
  final IconData icon;
  final String selectedType;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedType == type;
    return Semantics(
      identifier: 'stats_chart_type_${type.toLowerCase()}_btn',
      label: 'Tombol grafik $type${isSelected ? ', terpilih' : ''}',
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: () => onTap(type),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? const [BoxShadow(color: Colors.black12, blurRadius: 2)]
                : const [],
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? const Color(0xFF009444) : Colors.grey,
          ),
        ),
      ),
    );
  }
}