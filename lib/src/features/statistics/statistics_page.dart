// lib/src/features/statistics/statistics_page.dart


import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/services/user_service.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/statistics/statistics_pdf_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/fade_in_transition.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

// ─── QA Key Constants ────────────────────────────────────────────────────────
// Centralised key registry – import this file in Katalon helper scripts.
class StatisticsKeys {
  StatisticsKeys._();
  static const dateFilterButton   = ValueKey('stats_date_filter_btn');
  static const categoryDropdown   = ValueKey('stats_category_dropdown');
  static const chartTypeToggle    = ValueKey('stats_chart_type_toggle');
  static const pieChartButton     = ValueKey('stats_chart_type_pie_btn');
  static const barChartButton     = ValueKey('stats_chart_type_bar_btn');
  static const chartContainer     = ValueKey('stats_chart_container');
  static const downloadPdfButton  = ValueKey('stats_download_pdf_btn');
  static const summaryCardPasien  = ValueKey('stats_summary_card_pasien');
  static const summaryCardUser    = ValueKey('stats_summary_card_user');
  static const indicatorList      = ValueKey('stats_indicator_list');
  static const loadingIndicator   = ValueKey('stats_loading_indicator');
}
// ─────────────────────────────────────────────────────────────────────────────

enum DateFilterType { all, thisWeek, thisMonth, thisYear, custom }

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  // ─── State ─────────────────────────────────────────────────────────────────
  DateFilterType _selectedFilterType = DateFilterType.all;
  DateTimeRange? _selectedDateRange;
  String _filterLabel = "Semua Waktu";
  final GlobalKey _chartKey = GlobalKey();
  int _touchedIndex = -1;
  String _chartType = 'Pie';
  String _selectedCategory = 'Kategori Pasien';

  int _totalUsers = 0;
  Map<String, int> _roleCounts = {'admin': 0, 'ahli_gizi': 0, 'tamu': 0};
  bool _isAdmin = false;

  Stream<QuerySnapshot>? _patientsStream;

  // ─── Category Options (grown via initData if admin) ────────────────────────
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

  // ─── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initData();
  }

  // ─── Chart Capture (RepaintBoundary) ───────────────────────────────────────
  /// Captures the chart as a PNG byte array for embedding in the PDF.
  ///
  /// **Memory optimisation notes:**
  ///   • pixelRatio 2.0 chosen deliberately over 3.0 – it produces a crisp
  ///     image in a PDF (≈800×600 px) without allocating a ~9× larger bitmap.
  ///     Use 3.0 only when the PDF is intended for A3/print-quality output.
  ///   • `image.dispose()` is called after `toByteData` so the native
  ///     ui.Image object is released immediately, before the async PDF build
  ///     starts. Without this, both the raw image and the PNG byte buffer
  ///     live simultaneously in memory.
  Future<Uint8List?> _captureChart() async {
    try {
      final boundary =
          _chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // Use 2.0 ratio for balanced quality/memory (see doc above).
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      // ✅ Release native image immediately.
      image.dispose();

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Error capturing chart: $e");
      return null;
    }
  }

  // ─── Firestore Stream ──────────────────────────────────────────────────────
  void _updateStream() {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection('patients');

    if (!_isAdmin) {
      query = query.where('createdBy', isEqualTo: uid);
    }

    // includeMetadataChanges: false — prevents extra rebuild on cache hit.
    setState(() {
      _patientsStream = query.snapshots(includeMetadataChanges: false);
    });
  }

  // ─── Date Filter ───────────────────────────────────────────────────────────
  Future<void> _handleDateFilter(DateFilterType type) async {
    final DateTime now = DateTime.now();
    DateTime? start;
    DateTime? end = now;
    String label = "Semua Waktu";

    switch (type) {
      case DateFilterType.thisWeek:
        start = DateTime(now.year, now.month,
            now.day - (now.weekday - 1)); // Monday of current week
        label = "Minggu Ini";
        break;

      case DateFilterType.thisMonth:
        start = DateTime(now.year, now.month, 1);
        label = "Bulan Ini";
        break;

      case DateFilterType.thisYear:
        start = DateTime(now.year, 1, 1);
        label = "Tahun Ini";
        break;

      case DateFilterType.custom:
        final DateTimeRange? picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2023),
          lastDate: now,
          initialDateRange: _selectedDateRange,
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF009444),
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          ),
        );
        if (picked == null) return; // user cancelled
        start = picked.start;
        end = picked.end;
        label =
            "${picked.start.day}/${picked.start.month} – ${picked.end.day}/${picked.end.month}";
        break;

      case DateFilterType.all:
        start = null;
        end = null;
        label = "Semua Waktu";
        break;
    }

    setState(() {
      _selectedFilterType = type;
      _filterLabel = label;
      if (start != null && end != null) {
        _selectedDateRange = DateTimeRange(
          start: start,
          end: DateTime(end.year, end.month, end.day, 23, 59, 59),
        );
      } else {
        _selectedDateRange = null;
      }
    });

    _updateStream();
  }

  // ─── Init Data ─────────────────────────────────────────────────────────────
  Future<void> _initData() async {
    final String? userRole = await UserService().getUserRole();

    if (userRole == 'admin') {
      try {
        final snap =
            await FirebaseFirestore.instance.collection('users').get();
        int admins = 0, nutritionists = 0, guests = 0;
        for (final doc in snap.docs) {
          final role = (doc.data()['role'] as String?) ?? 'tamu';
          if (role == 'admin') {
            admins++;
          } else if (role == 'ahli_gizi') {
            nutritionists++;
          } else {
            guests++;
          }
        }
        if (!mounted) return;
        setState(() {
          _totalUsers = snap.docs.length;
          _roleCounts = {
            'admin': admins,
            'ahli_gizi': nutritionists,
            'tamu': guests,
          };
        });
      } catch (e) {
        debugPrint("Error fetching users: $e");
      }
    }

    if (!mounted) return;
    setState(() {
      _isAdmin = userRole == 'admin';
      if (_isAdmin && !_categoryOptions.contains('Pengguna')) {
        _categoryOptions.add('Pengguna');
      }
    });
    _updateStream();
  }

  // ─── Data Helpers ──────────────────────────────────────────────────────────
  String _cleanString(dynamic value) {
    if (value == null) return "Tidak Diketahui";
    final s = value.toString().trim();
    return s.isEmpty ? "Tidak Diketahui" : s;
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    }
    return 0.0;
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Responsive spacing computed once per build.
    final mq = MediaQuery.of(context);
    final double sw = mq.size.width;
    final double sp = sw < 400 ? 12.0 : (sw < 600 ? 16.0 : 24.0); // base spacing
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

                // ── Client-Side Date Filter ────────────────────────────────
                final allDocs = snapshot.data?.docs ?? [];
                final List<QueryDocumentSnapshot> docs =
                    _selectedDateRange == null
                        ? allDocs
                        : allDocs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            if (data['tanggalPemeriksaan'] == null) return false;
                            try {
                              final ts =
                                  data['tanggalPemeriksaan'] as Timestamp;
                              final date = ts.toDate();
                              return date.isAfter(_selectedDateRange!.start
                                      .subtract(const Duration(seconds: 1))) &&
                                  date.isBefore(_selectedDateRange!.end
                                      .add(const Duration(seconds: 1)));
                            } catch (_) {
                              return false;
                            }
                          }).toList();

                final int totalPasien = docs.length;

                // ── Aggregate Data ─────────────────────────────────────────
                int totalDewasa = 0,
                    totalAnak = 0,
                    totalLaki = 0,
                    totalPerempuan = 0;
                Map<String, double> statusGiziMap = {};
                Map<String, double> statusGiziAnakBBUMap = {};
                Map<String, double> diagnosisMap = {};
                Map<String, double> usiaMap = {
                  "Balita (0-5)": 0,
                  "Anak (6-11)": 0,
                  "Remaja (12-25)": 0,
                  "Dewasa (26-45)": 0,
                  "Lansia (>45)": 0,
                };
                Map<String, double> bbMap = {
                  "< 40 kg": 0, "40 - 50 kg": 0, "50 - 60 kg": 0,
                  "60 - 70 kg": 0, "70 - 80 kg": 0, "> 80 kg": 0,
                };
                Map<String, double> tbMap = {
                  "< 150 cm": 0, "150 - 160 cm": 0,
                  "160 - 170 cm": 0, "> 170 cm": 0,
                };

                for (final doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final String tipe = (data['tipePasien'] as String?) ?? 'dewasa';

                  // A. Tipe & Gender
                  if (tipe == 'anak') {
                    totalAnak++;
                    String statusBBU = _cleanString(data['statusGiziBBU']);
                    if (statusBBU == "Tidak Diketahui") {
                      statusBBU = _cleanString(data['statusGiziAnak']);
                    }
                    if (statusBBU != "Tidak Diketahui") {
                      final key = statusBBU.length > 1
                          ? statusBBU[0].toUpperCase() + statusBBU.substring(1)
                          : statusBBU;
                      statusGiziAnakBBUMap[key] =
                          (statusGiziAnakBBUMap[key] ?? 0) + 1;
                    }
                  } else {
                    totalDewasa++;
                  }

                  final String gender =
                      (data['jenisKelamin'] as String?) ?? '';
                  if (gender.toLowerCase().contains('laki')) {
                    totalLaki++;
                  } else if (gender.toLowerCase().contains('perempuan')) {
                    totalPerempuan++;
                  }

                  // B. Status Gizi Dewasa
                  if (tipe != 'anak') {
                    final String status = _cleanString(data['monevStatusGizi']);
                    if (status != "Tidak Diketahui") {
                      final key = status.length > 1
                          ? status[0].toUpperCase() +
                              status.substring(1).toLowerCase()
                          : status;
                      statusGiziMap[key] = (statusGiziMap[key] ?? 0) + 1;
                    }
                  }

                  // C. Diagnosis
                  final String diag = _cleanString(data['diagnosisMedis']);
                  if (diag != "Tidak Diketahui") {
                    diagnosisMap[diag] = (diagnosisMap[diag] ?? 0) + 1;
                  }

                  // D. Usia
                  if (data['tanggalLahir'] is Timestamp) {
                    final int age = _calculateAge(
                        (data['tanggalLahir'] as Timestamp).toDate());
                    if (age <= 5) {
                      usiaMap["Balita (0-5)"] = usiaMap["Balita (0-5)"]! + 1;
                    } else if (age <= 11) {
                      usiaMap["Anak (6-11)"] = usiaMap["Anak (6-11)"]! + 1;
                    } else if (age <= 25) {
                      usiaMap["Remaja (12-25)"] =
                          usiaMap["Remaja (12-25)"]! + 1;
                    } else if (age <= 45) {
                      usiaMap["Dewasa (26-45)"] =
                          usiaMap["Dewasa (26-45)"]! + 1;
                    } else {
                      usiaMap["Lansia (>45)"] = usiaMap["Lansia (>45)"]! + 1;
                    }
                  }

                  // E. Berat Badan
                  final double bb = _parseDouble(data['beratBadan']);
                  if (bb > 0) {
                    if (bb < 40) {
                      bbMap["< 40 kg"] = bbMap["< 40 kg"]! + 1;
                    } else if (bb < 50) {
                      bbMap["40 - 50 kg"] = bbMap["40 - 50 kg"]! + 1;
                    } else if (bb < 60) {
                      bbMap["50 - 60 kg"] = bbMap["50 - 60 kg"]! + 1;
                    } else if (bb < 70) {
                      bbMap["60 - 70 kg"] = bbMap["60 - 70 kg"]! + 1;
                    } else if (bb < 80) {
                      bbMap["70 - 80 kg"] = bbMap["70 - 80 kg"]! + 1;
                    } else {
                      bbMap["> 80 kg"] = bbMap["> 80 kg"]! + 1;
                    }
                  }

                  // F. Tinggi Badan
                  final double tb = _parseDouble(data['tinggiBadan']);
                  if (tb > 0) {
                    if (tb < 150) {
                      tbMap["< 150 cm"] = tbMap["< 150 cm"]! + 1;
                    } else if (tb < 160) {
                      tbMap["150 - 160 cm"] = tbMap["150 - 160 cm"]! + 1;
                    } else if (tb < 170) {
                      tbMap["160 - 170 cm"] = tbMap["160 - 170 cm"]! + 1;
                    } else {
                      tbMap["> 170 cm"] = tbMap["> 170 cm"]! + 1;
                    }
                  }
                }

                // Clean maps
                usiaMap.removeWhere((_, v) => v == 0);
                bbMap.removeWhere((_, v) => v == 0);
                tbMap.removeWhere((_, v) => v == 0);

                // ── Chart Config ───────────────────────────────────────────
                Map<String, double> rawData = {};
                List<Color> chartColors = [];
                String chartTitle = "";

                if (_selectedCategory == 'Pengguna' && _isAdmin) {
                  chartTitle = "Distribusi Role Pengguna";
                  rawData = {
                    "Admin": _roleCounts['admin']!.toDouble(),
                    "Ahli Gizi": _roleCounts['ahli_gizi']!.toDouble(),
                    "Tamu": _roleCounts['tamu']!.toDouble(),
                  };
                  chartColors = [Colors.red, Colors.teal, Colors.lightGreen];
                } else if (_selectedCategory == 'Kategori Pasien') {
                  chartTitle = "Persentase Tipe Pasien";
                  rawData = {
                    "Dewasa": totalDewasa.toDouble(),
                    "Anak": totalAnak.toDouble(),
                  };
                  chartColors = [Colors.blue, Colors.orange];
                } else if (_selectedCategory == 'Jenis Kelamin') {
                  chartTitle = "Persentase Gender";
                  rawData = {
                    "Laki-laki": totalLaki.toDouble(),
                    "Perempuan": totalPerempuan.toDouble(),
                  };
                  chartColors = [Colors.cyan, Colors.pinkAccent];
                } else if (_selectedCategory == 'Status Gizi (Dewasa)') {
                  chartTitle = "Status Gizi (Dewasa)";
                  rawData = statusGiziMap;
                  chartColors = [
                    Colors.orange, Colors.green, Colors.red,
                    Colors.blueGrey, Colors.purple,
                  ];
                } else if (_selectedCategory == 'Status Gizi Anak (BB/U)') {
                  chartTitle = "Status Gizi Anak (BB/U)";
                  rawData = statusGiziAnakBBUMap;
                  chartColors = [
                    Colors.green, Colors.redAccent, Colors.orangeAccent,
                    Colors.blueAccent, Colors.purpleAccent,
                  ];
                } else if (_selectedCategory == 'Diagnosis Medis') {
                  chartTitle = "Diagnosis Medis Terbanyak";
                  final sortedKeys = diagnosisMap.keys.toList(growable: false)
                    ..sort((k1, k2) =>
                        diagnosisMap[k2]!.compareTo(diagnosisMap[k1]!));
                  double countLainnya = 0;
                  for (int i = 0; i < sortedKeys.length; i++) {
                    if (i < 5) {
                      rawData[sortedKeys[i]] = diagnosisMap[sortedKeys[i]]!;
                    } else {
                      countLainnya += diagnosisMap[sortedKeys[i]]!;
                    }
                  }
                  if (countLainnya > 0) rawData["Lainnya"] = countLainnya;
                  chartColors = [
                    Colors.redAccent, Colors.blueAccent, Colors.orangeAccent,
                    Colors.green, Colors.purpleAccent, Colors.grey,
                  ];
                } else if (_selectedCategory == 'Usia') {
                  chartTitle = "Rentang Usia Pasien";
                  rawData = usiaMap;
                  chartColors = [
                    Colors.lightBlue, Colors.blue, Colors.indigo,
                    Colors.deepPurple, Colors.teal,
                  ];
                } else if (_selectedCategory == 'Berat Badan') {
                  chartTitle = "Sebaran Berat Badan";
                  rawData = bbMap;
                  chartColors = [
                    Colors.brown.shade300, Colors.brown.shade400,
                    Colors.brown.shade500, Colors.brown.shade600,
                    Colors.brown.shade700, Colors.brown.shade800,
                  ];
                } else if (_selectedCategory == 'Tinggi Badan') {
                  chartTitle = "Sebaran Tinggi Badan";
                  rawData = tbMap;
                  chartColors = [
                    Colors.teal.shade300, Colors.teal.shade400,
                    Colors.teal.shade500, Colors.teal.shade700,
                  ];
                }

                Map<String, double> chartData = Map.from(rawData)
                  ..removeWhere((_, v) => v == 0);
                if (chartData.isEmpty) {
                  chartData = {"Tidak ada data": 1};
                  chartColors = [Colors.grey.shade300];
                }

                // ── Layout ─────────────────────────────────────────────────
                return FadeInTransition(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(sp),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Summary Cards
                        if (_isAdmin)
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  key: StatisticsKeys.summaryCardPasien,
                                  semanticIdentifier: 'summary_card_total_pasien',
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
                                      'Kartu ringkasan Total Pengguna, $_totalUsers pengguna terdaftar',
                                  title: "Total Pengguna",
                                  count: _totalUsers,
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

                        // ── Category Label ──────────────────────────────────
                        const Text(
                          "Pilih Statistik:",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: sp * 0.5),

                        // ── Category Dropdown ───────────────────────────────
                        Semantics(
                          identifier: 'stats_category_dropdown',
                          label: 'Dropdown pilih kategori statistik, dipilih: $_selectedCategory',
                          child: Container(
                            key: StatisticsKeys.categoryDropdown,
                            padding: EdgeInsets.symmetric(
                              horizontal: sp,
                              vertical: sp * 0.125,
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
                              items: _categoryOptions,
                              selectedItem: _selectedCategory,
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedCategory = newValue;
                                    _touchedIndex = -1;
                                  });
                                }
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
                              dropdownDecoratorProps:
                                  const DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              dropdownButtonProps: const DropdownButtonProps(
                                icon: Icon(
                                  Icons.category,
                                  color: Color(0xFF009444),
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: sp * 1.5),

                        // ── Date Filter Button ──────────────────────────────
                        Semantics(
                          identifier: 'stats_date_filter_btn',
                          label: 'Tombol filter waktu, filter aktif: $_filterLabel',
                          button: true,
                          child: Container(
                            key: StatisticsKeys.dateFilterButton,
                            margin: EdgeInsets.only(bottom: sp),
                            child: Row(
                              children: [
                                Expanded(
                                  child: PopupMenuButton<DateFilterType>(
                                    initialValue: _selectedFilterType,
                                    onSelected: _handleDateFilter,
                                    itemBuilder: (context) =>
                                        const <PopupMenuEntry<DateFilterType>>[
                                      PopupMenuItem(
                                        value: DateFilterType.thisWeek,
                                        child: Row(children: [
                                          Icon(Icons.calendar_view_week,
                                              color: Colors.grey),
                                          SizedBox(width: 8),
                                          Text('Minggu Ini'),
                                        ]),
                                      ),
                                      PopupMenuItem(
                                        value: DateFilterType.thisMonth,
                                        child: Row(children: [
                                          Icon(Icons.calendar_month,
                                              color: Colors.grey),
                                          SizedBox(width: 8),
                                          Text('Bulan Ini'),
                                        ]),
                                      ),
                                      PopupMenuItem(
                                        value: DateFilterType.thisYear,
                                        child: Row(children: [
                                          Icon(Icons.calendar_today,
                                              color: Colors.grey),
                                          SizedBox(width: 8),
                                          Text('Tahun Ini'),
                                        ]),
                                      ),
                                      PopupMenuDivider(),
                                      PopupMenuItem(
                                        value: DateFilterType.custom,
                                        child: Row(children: [
                                          Icon(Icons.date_range,
                                              color: Colors.grey),
                                          SizedBox(width: 8),
                                          Text('Pilih Tanggal Sendiri (Custom)'),
                                        ]),
                                      ),
                                      PopupMenuDivider(),
                                      PopupMenuItem(
                                        value: DateFilterType.all,
                                        child: Row(children: [
                                          Icon(Icons.all_inclusive,
                                              color: Color(0xFF009444)),
                                          SizedBox(width: 8),
                                          Text('Semua Waktu (Reset)',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF009444))),
                                        ]),
                                      ),
                                    ],
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: sp, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                            color: const Color(0xFF009444)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text("Filter Waktu:",
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey)),
                                              Text(
                                                _filterLabel,
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
                              ],
                            ),
                          ),
                        ),

                        // ── Chart Type Toggle ───────────────────────────────
                        Row(
                          children: [
                            Semantics(
                              identifier: 'stats_chart_type_toggle',
                              label: 'Toggle jenis grafik, terpilih: $_chartType',
                              child: Container(
                                key: StatisticsKeys.chartTypeToggle,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    _buildChartTypeButton(
                                      "Pie", Icons.pie_chart,
                                      key: StatisticsKeys.pieChartButton,
                                    ),
                                    _buildChartTypeButton(
                                      "Bar", Icons.bar_chart,
                                      key: StatisticsKeys.barChartButton,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: sp),

                        // ── Chart Title ─────────────────────────────────────
                        Text(
                          chartTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: sp),

                        // ── Chart Container ─────────────────────────────────
                        Semantics(
                          identifier: 'stats_chart_container',
                          label: 'Grafik statistik: $chartTitle',
                          child: RepaintBoundary(
                            key: _chartKey,
                            child: Container(
                              key: StatisticsKeys.chartContainer,
                              height: sw < 200 ? 260 : 300,
                              padding: EdgeInsets.all(sp),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(cardRadius),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.grey.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: _chartType == 'Pie'
                                  ? _buildPieChartOnly(
                                      dataMap: chartData,
                                      colors: chartColors,
                                      touchedIndex: _touchedIndex,
                                      onTouch: (i) => setState(
                                          () => _touchedIndex = i),
                                    )
                                  : _buildBarChartOnly(
                                      dataMap: chartData,
                                      colors: chartColors,
                                    ),
                            ),
                          ),
                        ),

                        SizedBox(height: sp * 1.25),

                        // ── Legend / Indicator List ─────────────────────────
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
                          dataMap: chartData,
                          colors: chartColors,
                          spacing: sp,
                        ),

                        SizedBox(height: sp * 3),

                        // ── Download PDF Button ─────────────────────────────
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
                                        content:
                                            Text("Membuat File PDF...")),
                                  );
                                  final Uint8List? chartImage =
                                      await _captureChart();
                                  final dataToSend = rawData.isEmpty
                                      ? {"Tidak ada data": 0.0}
                                      : rawData;
                                  await StatisticsPdfService
                                      .generateAndOpenPdf(
                                    chartTitle: chartTitle,
                                    selectedCategory: _selectedCategory,
                                    dataMap: dataToSend,
                                    totalPasien: totalPasien,
                                    chartImageBytes: chartImage,
                                    dateRange: _selectedDateRange,
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text("Gagal membuka PDF: $e")),
                                  );
                                }
                              },
                              icon: const Icon(Icons.download,
                                  color: Colors.white),
                              label: const Text(
                                "Download Laporan PDF",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF009444),
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

  // ─── Private Widget Helpers ─────────────────────────────────────────────────

  Widget _buildChartTypeButton(
    String type,
    IconData icon, {
    Key? key,
  }) {
    final bool isSelected = _chartType == type;
    return Semantics(
      identifier: 'stats_chart_type_${type.toLowerCase()}_btn',
      label: 'Tombol grafik $type${isSelected ? ', terpilih' : ''}',
      button: true,
      selected: isSelected,
      child: InkWell(
        key: key,
        onTap: () => setState(() => _chartType = type),
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
            color: isSelected
                ? const Color(0xFF009444)
                : Colors.grey,
          ),
        ),
      ),
    );
  }

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
            Text(title,
                style:
                    const TextStyle(color: Colors.white, fontSize: 12)),
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
    final double total =
        dataMap.values.fold(0, (prev, item) => prev + item);

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
                      horizontal: 12, vertical: 6),
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

  // ─── Chart Builders ─────────────────────────────────────────────────────────

  Widget _buildPieChartOnly({
    required Map<String, double> dataMap,
    required List<Color> colors,
    required int touchedIndex,
    required ValueChanged<int> onTouch,
  }) {
    final double total =
        dataMap.values.fold(0, (prev, item) => prev + item);
    if (total == 0 ||
        (dataMap.length == 1 && dataMap.keys.first == "Tidak ada data")) {
      return const Center(child: Text("Data Kosong"));
    }

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            if (!event.isInterestedForInteractions ||
                pieTouchResponse == null ||
                pieTouchResponse.touchedSection == null) {
              onTouch(-1);
              return;
            }
            onTouch(
                pieTouchResponse.touchedSection!.touchedSectionIndex);
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: List.generate(dataMap.length, (i) {
          final bool isTouched = i == touchedIndex;
          final double value = dataMap.values.elementAt(i);
          final String percentage = total > 0
              ? (value / total * 100).toStringAsFixed(1)
              : "0";

          return PieChartSectionData(
            color: colors[i % colors.length],
            value: value,
            title: '$percentage%',
            radius: isTouched ? 110.0 : 100.0,
            titleStyle: TextStyle(
              fontSize: isTouched ? 20.0 : 14.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBarChartOnly({
    required Map<String, double> dataMap,
    required List<Color> colors,
  }) {
    if (dataMap.length == 1 && dataMap.keys.first == "Tidak ada data") {
      return const Center(child: Text("Data Kosong"));
    }

    double maxY = dataMap.values.fold(0, (prev, v) => v > prev ? v : prev);
    maxY = maxY + (maxY * 0.2);
    if (maxY == 0) maxY = 10;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.blueGrey,
            getTooltipItem: (group, _, rod, __) {
              final String label =
                  dataMap.keys.elementAt(group.x.toInt());
              return BarTooltipItem(
                '$label\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: rod.toY.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final int index = value.toInt();
                if (index < 0 || index >= dataMap.length) {
                  return const SizedBox();
                }
                String text = dataMap.keys.elementAt(index);
                if (text.length > 5) text = "${text.substring(0, 6)}..";
                return SideTitleWidget(
                  meta: meta,
                  space: 4,
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value == value.toInt().toDouble()) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(dataMap.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: dataMap.values.elementAt(index),
                color: colors[index % colors.length],
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}