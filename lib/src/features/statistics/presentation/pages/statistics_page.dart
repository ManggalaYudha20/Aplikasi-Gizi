// lib/src/features/statistics/presentation/pages/statistics_page.dart

import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:aplikasi_diagnosa_gizi/src/shared/services/user_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/fade_in_transition.dart';

import 'package:aplikasi_diagnosa_gizi/src/features/statistics/data/models/chart_data_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/statistics/services/statistics_fetch_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/statistics/services/statistics_pdf_service.dart';

import 'package:aplikasi_diagnosa_gizi/src/features/statistics/services/date_filter_logic.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/statistics/presentation/widgets/stat_bar_chart_widget.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/statistics/presentation/widgets/stat_filter_section.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/statistics/presentation/widgets/stat_pie_chart_widget.dart';

// ─── QA Key Constants ─────────────────────────────────────────────────────────
class StatisticsKeys {
  StatisticsKeys._();
  static const dateFilterButton = ValueKey('stats_date_filter_btn');
  static const categoryDropdown = ValueKey('stats_category_dropdown');
  static const chartTypeToggle = ValueKey('stats_chart_type_toggle');
  static const pieChartButton = ValueKey('stats_chart_type_pie_btn');
  static const barChartButton = ValueKey('stats_chart_type_bar_btn');
  static const chartContainer = ValueKey('stats_chart_container');
  static const downloadPdfButton = ValueKey('stats_download_pdf_btn');
  static const summaryCardPasien = ValueKey('stats_summary_card_pasien');
  static const summaryCardUser = ValueKey('stats_summary_card_user');
  static const indicatorList = ValueKey('stats_indicator_list');
  static const loadingIndicator = ValueKey('stats_loading_indicator');
}
// ─────────────────────────────────────────────────────────────────────────────

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  // ─── Panggil Controller Logic Tanggal ───────────────────────────────────────
  late final DateFilterLogic _dateLogic;

  // ─── State ──────────────────────────────────────────────────────────────────
  final GlobalKey _chartKey = GlobalKey();
  int _touchedIndex = -1;
  String _chartType = 'Pie';
  String _selectedCategory = 'Kategori Pasien';

  UserStats? _userStats;
  bool _isAdmin = false;
  Stream<QuerySnapshot>? _patientsStream;

  // ─── Category Options ───────────────────────────────────────────────────────
  final List<String> _categoryOptions = [
    'Kategori Pasien',
    'Jenis Kelamin',
    'Status Gizi (Dewasa)',
    'Status Gizi Anak (BB/U)',
    'Usia',
    'Diagnosis Medis',
    'Berat Badan',
    'Tinggi Badan',
  ];

  // ─── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    // Inisialisasi logic tanggal dan pasang callback-nya
    _dateLogic = DateFilterLogic(
      onUpdate: () {
        setState(() {}); // Paksa re-build UI saat tanggal berubah
        _updateStream(); // Minta data baru dari Firebase
      },
    );
    _initData();
  }

  // ─── Init ────────────────────────────────────────────────────────────────────
  Future<void> _initData() async {
    final String? userRole = await UserService().getUserRole();
    final bool isAdmin = userRole == 'admin';

    UserStats? userStats;
    if (isAdmin) {
      userStats = await StatisticsFetchService.fetchUserStats();
    }

    if (!mounted) return;
    setState(() {
      _isAdmin = isAdmin;
      _userStats = userStats;
      if (_isAdmin && !_categoryOptions.contains('Pengguna')) {
        _categoryOptions.add('Pengguna');
      }
    });
    _updateStream();
  }

  // ─── Stream ──────────────────────────────────────────────────────────────────
  void _updateStream() {
    setState(() {
      _patientsStream = StatisticsFetchService.buildPatientsQuery(
        isAdmin: _isAdmin,
      ).snapshots(includeMetadataChanges: false);
    });
  }

  // ─── Chart Capture ────────────────────────────────────────────────────────────
  Future<Uint8List?> _captureChart() async {
    try {
      final boundary =
          _chartKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      image.dispose();
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Error capturing chart: $e");
      return null;
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final double sw = mq.size.width;
    final double sp = sw < 400 ? 12.0 : (sw < 600 ? 16.0 : 24.0);
    final double cardRadius = sw < 400 ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(title: 'Statistik Data', subtitle: ''),
      body: _patientsStream == null
          ? const Center(
              key: StatisticsKeys.loadingIndicator,
              child: CircularProgressIndicator(),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: _patientsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    key: StatisticsKeys.loadingIndicator,
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text("Terjadi kesalahan memuat data"),
                  );
                }

                // ── Filter & Aggregate ───────────────────────────────────────
                final allDocs = snapshot.data?.docs ?? [];
                final filteredDocs = StatisticsFetchService.filterDocsByDate(
                  allDocs,
                  _dateLogic.selectedDateRange, // Ambil dari logic
                );
                final int totalPasien = filteredDocs.length;

                final aggregated = StatisticsFetchService.aggregatePatientData(
                  filteredDocs,
                );

                final ChartConfig chartConfig =
                    StatisticsFetchService.buildChartConfig(
                      selectedCategory: _selectedCategory,
                      data: aggregated,
                      userStats: _userStats,
                      isAdmin: _isAdmin,
                    );

                // ── Layout ───────────────────────────────────────────────────
                return FadeInTransition(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(sp),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Summary Card(s) (Dipotong untuk kerapian, sisanya sama dengan aslinya)
                        if (_isAdmin)
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  key: StatisticsKeys.summaryCardPasien,
                                  semanticIdentifier:
                                      'summary_card_total_pasien',
                                  semanticLabel:
                                      'Kartu ringkasan Total Pasien, $totalPasien pasien terdaftar',
                                  title: "Total Pasien",
                                  count: totalPasien,
                                  colors: const [
                                    Color(0xFF009444),
                                    Color(0xFF55C989),
                                  ],
                                  cardRadius: cardRadius,
                                  spacing: sp,
                                ),
                              ),
                              SizedBox(width: sp * 0.75),
                              Expanded(
                                child: _buildSummaryCard(
                                  key: StatisticsKeys.summaryCardUser,
                                  semanticIdentifier: 'summary_card_total_user',
                                  semanticLabel:
                                      'Kartu ringkasan Total Pengguna, ${_userStats?.totalUsers ?? 0} pengguna terdaftar',
                                  title: "Total Pengguna",
                                  count: _userStats?.totalUsers ?? 0,
                                  colors: [
                                    Colors.blue.shade700,
                                    Colors.blue.shade400,
                                  ],
                                  cardRadius: cardRadius,
                                  spacing: sp,
                                ),
                              ),
                            ],
                          )
                        else
                          _buildSummaryCard(
                            key: StatisticsKeys.summaryCardPasien,
                            semanticIdentifier: 'summary_card_total_pasien',
                            semanticLabel:
                                'Total Pasien Terdaftar: $totalPasien',
                            title: "Total Pasien Terdaftar",
                            count: totalPasien,
                            colors: const [
                              Color(0xFF009444),
                              Color(0xFF55C989),
                            ],
                            cardRadius: cardRadius,
                            spacing: sp,
                          ),

                        SizedBox(height: sp * 1.5),
                        Divider(color: Colors.grey.shade200),

                        // Filter Section
                        StatFilterSection(
                          categoryOptions: _categoryOptions,
                          selectedCategory: _selectedCategory,
                          onCategoryChanged: (value) => setState(() {
                            _selectedCategory = value;
                            _touchedIndex = -1;
                          }),

                          // Gunakan state dan fungsi dari DateFilterLogic
                          selectedFilterType: _dateLogic.selectedFilterType,
                          filterLabel: _dateLogic.filterLabel,
                          onFilterSelected: (type) =>
                              _dateLogic.handleDateFilter(context, type),
                          onPreviousDate:
                              (_dateLogic.selectedFilterType ==
                                      DateFilterType.all ||
                                  _dateLogic.selectedFilterType ==
                                      DateFilterType.custom)
                              ? null
                              : () => _dateLogic.shiftDate(-1),
                          onNextDate:
                              (_dateLogic.selectedFilterType ==
                                      DateFilterType.all ||
                                  _dateLogic.selectedFilterType ==
                                      DateFilterType.custom)
                              ? null
                              : () => _dateLogic.shiftDate(1),

                          chartType: _chartType,
                          onChartTypeChanged: (type) =>
                              setState(() => _chartType = type),
                          spacing: sp,
                        ),

                        SizedBox(height: sp),

                        // Chart Title
                        Text(
                          chartConfig.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: sp),

                        // Chart Container
                        Semantics(
                          identifier: 'stats_chart_container',
                          label: 'Grafik statistik: ${chartConfig.title}',
                          child: RepaintBoundary(
                            key: _chartKey,
                            child: Container(
                              key: StatisticsKeys.chartContainer,
                              height: sw < 200 ? 260 : 300,
                              padding: EdgeInsets.all(sp),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(cardRadius),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: _chartType == 'Pie'
                                  ? StatPieChartWidget(
                                      dataMap: chartConfig.dataMap,
                                      colors: chartConfig.colors,
                                      touchedIndex: _touchedIndex,
                                      onTouch: (i) =>
                                          setState(() => _touchedIndex = i),
                                    )
                                  : StatBarChartWidget(
                                      dataMap: chartConfig.dataMap,
                                      colors: chartConfig.colors,
                                    ),
                            ),
                          ),
                        ),

                        SizedBox(height: sp * 1.25),

                        // Legend / Indicator List
                        const Text(
                          "Detail Data:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: sp * 0.625),
                        _buildIndicatorList(
                          key: StatisticsKeys.indicatorList,
                          dataMap: chartConfig.dataMap,
                          colors: chartConfig.colors,
                          spacing: sp,
                        ),

                        SizedBox(height: sp * 3),

                        // Download PDF Button
                        Semantics(
                          identifier: 'stats_download_pdf_btn',
                          label: 'Tombol download laporan PDF statistik',
                          button: true,
                          child: SizedBox(
                            key: StatisticsKeys.downloadPdfButton,
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Membuat File PDF..."),
                                    ),
                                  );
                                  final Uint8List? chartImage =
                                      await _captureChart();
                                  final dataToSend =
                                      chartConfig.dataMap.length == 1 &&
                                          chartConfig.dataMap.keys.first ==
                                              "Tidak ada data"
                                      ? {"Tidak ada data": 0.0}
                                      : chartConfig.dataMap;

                                  await StatisticsPdfService.generateAndOpenPdf(
                                    chartTitle: chartConfig.title,
                                    selectedCategory: _selectedCategory,
                                    dataMap: dataToSend,
                                    totalPasien: totalPasien,
                                    chartImageBytes: chartImage,
                                    dateRange: _dateLogic
                                        .selectedDateRange, // Ambil dari logic
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Gagal membuka PDF: $e"),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.download,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "Download Laporan PDF",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF009444),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ─── Private Widget Helpers (Sama seperti sebelumnya) ──────────────────────────

  Widget _buildSummaryCard({
    required Key key,
    required String semanticIdentifier,
    required String semanticLabel,
    required String title,
    required int count,
    required List<Color> colors,
    required double cardRadius,
    required double spacing,
  }) {
    return Semantics(
      identifier: semanticIdentifier,
      label: semanticLabel,
      child: Container(
        key: key,
        padding: EdgeInsets.all(spacing * 0.9375),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(cardRadius),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              "$count",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "Orang",
              style: TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorList({
    required Key key,
    required Map<String, double> dataMap,
    required List<Color> colors,
    required double spacing,
  }) {
    final double total = dataMap.values.fold(0, (prev, item) => prev + item);

    return Column(
      key: key,
      children: List.generate(dataMap.length, (index) {
        final String itemKey = dataMap.keys.elementAt(index);
        final double value = dataMap.values.elementAt(index);
        final Color color = colors[index % colors.length];
        final bool isDummy = itemKey == "Tidak ada data";

        final String percentageStr = isDummy
            ? "0%"
            : (total > 0
                  ? "${((value / total) * 100).toStringAsFixed(1)}%"
                  : "0%");
        final String countStr = isDummy ? "0" : "${value.toInt()}";

        return Semantics(
          identifier: 'stats_indicator_item_$index',
          label: 'Kategori: $itemKey, jumlah $countStr orang, $percentageStr',
          child: Container(
            margin: EdgeInsets.only(bottom: spacing * 0.75),
            padding: EdgeInsets.all(spacing * 0.75),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    percentageStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    itemKey,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "$countStr Orang",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
