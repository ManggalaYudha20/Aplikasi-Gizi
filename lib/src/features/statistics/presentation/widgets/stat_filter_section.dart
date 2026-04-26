// lib/src/features/statistics/presentation/widgets/stat_filter_section.dart

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/statistics/data/models/chart_data_model.dart';

class StatFilterSection extends StatelessWidget {
  const StatFilterSection({
    super.key,
    required this.categoryOptions,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.selectedFilterType,
    required this.filterLabel,
    required this.onFilterSelected,
    this.onPreviousDate,
    this.onNextDate,
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
  final ValueChanged<DateFilterType> onFilterSelected;
  final VoidCallback? onPreviousDate;
  final VoidCallback? onNextDate;

  // ── Chart-type toggle ──────────────────────────────────────────────────────
  final String chartType;
  final ValueChanged<String> onChartTypeChanged;
  final double spacing;

  String _getFilterTypeName(DateFilterType type) {
    switch (type) {
      case DateFilterType.thisWeek:
        return 'Mingguan';
      case DateFilterType.thisMonth:
        return 'Bulanan';
      case DateFilterType.thisYear:
        return 'Tahunan';
      case DateFilterType.custom:
        return 'Periode';
      case DateFilterType.all:
        return 'Semua';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Date Filter (Panah Kiri + Label + Dropdown Kanan) ────────────────
        Padding(
          padding: EdgeInsets.only(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Bagian Kiri: Panah dan Label Waktu
              Row(
                children: [
                  InkWell(
                    onTap: onPreviousDate,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 16,
                        color: onPreviousDate == null
                            ? Colors.grey.shade300
                            : Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 80),
                    alignment: Alignment.center,
                    child: Text(
                      filterLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onNextDate,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: onNextDate == null
                            ? Colors.grey.shade300
                            : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),

              // Bagian Kanan: Dropdown Tipe Filter
              Semantics(
                identifier: 'stats_date_filter_btn',
                label: 'Ubah jenis filter waktu',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: PopupMenuButton<DateFilterType>(
                    initialValue: selectedFilterType,
                    onSelected: onFilterSelected,
                    offset: const Offset(0, 35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getFilterTypeName(selectedFilterType),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: DateFilterType.thisWeek,
                        child: Text('Mingguan'),
                      ),
                      PopupMenuItem(
                        value: DateFilterType.thisMonth,
                        child: Text('Bulanan'),
                      ),
                      PopupMenuItem(
                        value: DateFilterType.thisYear,
                        child: Text('Tahunan'),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: DateFilterType.custom,
                        child: Text('Periode (Custom)'),
                      ),
                      PopupMenuItem(
                        value: DateFilterType.all,
                        child: Text(
                          'Semua Waktu',
                          style: TextStyle(
                            color: Color(0xFF009444),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(color: Colors.grey.shade200),

        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Bagian Kiri (Dropdown Kategori) dibungkus Expanded agar mengambil sisa ruang
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pilih Statistik:",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: spacing * 0.5),
                  Semantics(
                    identifier: 'stats_category_dropdown',
                    label:
                        'Dropdown pilih kategori statistik, dipilih: $selectedCategory',
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
                          maxLines: 1,
                          overflow: TextOverflow
                              .ellipsis, // Mencegah teks kepanjangan
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
                ],
              ),
            ),

            SizedBox(width: spacing), // Jarak antara Dropdown dan Toggle
            // Bagian Kanan (Chart Type Toggle)
            Semantics(
              identifier: 'stats_chart_type_toggle',
              label: 'Toggle jenis grafik, terpilih: $chartType',
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(
                    12,
                  ), // Disamakan radiusnya dengan dropdown
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
          ],
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
