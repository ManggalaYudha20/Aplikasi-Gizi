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

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}
enum DateFilterType { all, thisWeek, thisMonth, thisYear, custom }

class _StatisticsPageState extends State<StatisticsPage> {
  DateFilterType _selectedFilterType = DateFilterType.all;
  DateTimeRange? _selectedDateRange; // Menyimpan tanggal start & end aktual
  String _filterLabel = "Semua Waktu"; // Label untuk ditampilkan di tombol
  final GlobalKey _chartKey = GlobalKey();
  int touchedIndex = -1;
  String _chartType = 'Pie';
  String _selectedCategory = 'Kategori Pasien';

  int totalUsers = 0;
  Map<String, int> roleCounts = {'admin': 0, 'ahli_gizi': 0, 'tamu': 0};
  bool isAdmin = false;

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

  Stream<QuerySnapshot>? _patientsStream;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<Uint8List?> _captureChart() async {
    try {
      RenderRepaintBoundary? boundary =
          _chartKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // pixelRatio 3.0 agar hasil gambar di PDF tajam (high resolution)
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Error capturing chart: $e");
      return null;
    }
  }

  void _updateStream() {
    final String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    
    // Mulai query dasar
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('patients');

    // 1. Filter Role (Jika bukan admin, hanya lihat data sendiri)
    if (!isAdmin) {
      query = query.where('createdBy', isEqualTo: currentUserUid);
    }

    setState(() {
      _patientsStream = query.snapshots(includeMetadataChanges: true);
    });
  }

 Future<void> _handleDateFilter(DateFilterType type) async {
    DateTime now = DateTime.now();
    DateTime? start;
    DateTime? end = now; // Default end adalah sekarang
    String label = "Semua Waktu";

    switch (type) {
      case DateFilterType.thisWeek:
        // Mencari hari Senin minggu ini
        start = now.subtract(Duration(days: now.weekday - 1));
        // Reset jam ke 00:00:00
        start = DateTime(start.year, start.month, start.day); 
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
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF009444),
                  onPrimary: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          start = picked.start;
          end = picked.end;
          label = "${picked.start.day}/${picked.start.month} - ${picked.end.day}/${picked.end.month}";
        } else {
          // User membatalkan custom, jangan ubah apa-apa
          return;
        }
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
        // Hapus tanda seru (!)
        DateTime endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
        _selectedDateRange = DateTimeRange(start: start, end: endOfDay);
      } else {
        _selectedDateRange = null;
      }
    });

    // Panggil fungsi update stream setelah filter berubah
    _updateStream();
  }

  Future<void> _initData() async {
    final userService = UserService();
    final String? userRole = await userService.getUserRole();

    // Logika hitung user untuk admin (Biarkan tetap ada)
    if (userRole == 'admin') {
      try {
        final userSnapshot = await FirebaseFirestore.instance.collection('users').get();
        int admins = 0, nutritionists = 0, guests = 0;
        for (var doc in userSnapshot.docs) {
          String role = doc.data()['role'] ?? 'tamu';
          if (role == 'admin') {
            admins++;
          } else if (role == 'ahli_gizi') {
            nutritionists++;
          } else {
            guests++;
          }
        }
        if (mounted) {
          setState(() {
            totalUsers = userSnapshot.docs.length;
            roleCounts = {'admin': admins, 'ahli_gizi': nutritionists, 'tamu': guests};
          });
        }
      } catch (e) {
        debugPrint("Error fetching users: $e");
      }
    }

    if (mounted) {
      setState(() {
        isAdmin = userRole == 'admin';
        if (isAdmin && !_categoryOptions.contains('Pengguna')) {
          _categoryOptions.add('Pengguna');
        }
      });
      // Panggil updateStream untuk inisialisasi awal
      _updateStream();
    }
  }

  // Helper: Membersihkan string dan menangani null
  String cleanString(dynamic value) {
    if (value == null) return "Tidak Diketahui";
    return value.toString().trim().isEmpty
        ? "Tidak Diketahui"
        : value.toString().trim();
  }

  // Helper: Parsing angka dengan aman (handle int, double, String)
  double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      // Hapus karakter non-angka jika ada (misal "60 kg" -> "60")
      String clean = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(clean) ?? 0.0;
    }
    return 0.0;
  }

  // Helper: Hitung Usia Presisi
  int calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(150, 255, 255, 255),
      appBar: const CustomAppBar(title: 'Statistik Data', subtitle: ''),
      body: _patientsStream == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _patientsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text("Terjadi kesalahan memuat data"),
                  );
                }

                final allDocs = snapshot.data?.docs ?? [];
                
                // --- LOGIKA FILTER TANGGAL (CLIENT SIDE) ---
                List<QueryDocumentSnapshot> docs = [];

                if (_selectedDateRange == null) {
                  // Jika filter "Semua Waktu", pakai semua data
                  docs = allDocs;
                } else {
                  // Jika ada filter tanggal, kita saring manual
                  docs = allDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    
                    // CEK 1: Pastikan field 'createdAt' ada dan tidak null
                    // GANTI 'createdAt' dengan nama field tanggal di databasemu jika berbeda
                    if (data['tanggalPemeriksaan'] == null) return false;

                    Timestamp timestamp;
                    try {
                      timestamp = data['tanggalPemeriksaan'] as Timestamp;
                    } catch (e) {
                      return false; // Skip jika format bukan timestamp
                    }

                    DateTime date = timestamp.toDate();
                    
                    // Logika Range Inclusive (Start <= Date <= End)
                    return date.isAfter(_selectedDateRange!.start.subtract(const Duration(seconds: 1))) &&
                           date.isBefore(_selectedDateRange!.end.add(const Duration(seconds: 1)));
                  }).toList();
                }
                int totalPasien = docs.length;

                // --- VARIABEL PENAMPUNG DATA ---
                int totalDewasa = 0,
                    totalAnak = 0,
                    totalLaki = 0,
                    totalPerempuan = 0;

                Map<String, double> statusGiziMap = {};

                Map<String, double> statusGiziAnakBBUMap = {};

                Map<String, double> diagnosisMap = {};

                // Urutan map penting untuk legend chart
                Map<String, double> usiaMap = {
                  "Balita (0-5)": 0,
                  "Anak (6-11)": 0,
                  "Remaja (12-25)": 0,
                  "Dewasa (26-45)": 0,
                  "Lansia (>45)": 0,
                };
                Map<String, double> bbMap = {
                  "< 40 kg": 0,
                  "40 - 50 kg": 0,
                  "50 - 60 kg": 0,
                  "60 - 70 kg": 0,
                  "70 - 80 kg": 0,
                  "> 80 kg": 0,
                };
                Map<String, double> tbMap = {
                  "< 150 cm": 0,
                  "150 - 160 cm": 0,
                  "160 - 170 cm": 0,
                  "> 170 cm": 0,
                };

                // --- LOGIKA PENGOLAHAN DATA ---
                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  String tipe = data['tipePasien'] ?? 'dewasa';

                  // A. Tipe & Gender
                  if (tipe == 'anak') {
                    totalAnak++;

                    String statusBBU = cleanString(data['statusGiziBBU']);
                    if (statusBBU == "Tidak Diketahui") {
                      statusBBU = cleanString(data['statusGiziAnak']);
                    }

                    if (statusBBU != "Tidak Diketahui") {
                      // Kapitalisasi agar rapi (misal: "gizi baik" -> "Gizi baik")
                      if (statusBBU.length > 1) {
                        statusBBU =
                            statusBBU[0].toUpperCase() + statusBBU.substring(1);
                      }
                      statusGiziAnakBBUMap[statusBBU] =
                          (statusGiziAnakBBUMap[statusBBU] ?? 0) + 1;
                    }
                  } else {
                    totalDewasa++;
                  }

                  String gender = data['jenisKelamin'] ?? '';
                  if (gender.toLowerCase().contains('laki')) {
                    totalLaki++;
                  } else if (gender.toLowerCase().contains('perempuan')) {
                    totalPerempuan++;
                  }

                  // B. Status Gizi (Hanya untuk Dewasa)
                  if (tipe != 'anak') {
                    String status = cleanString(data['monevStatusGizi']);
                    if (status != "Tidak Diketahui") {
                      // Kapitalisasi huruf pertama
                      String statusKey = status.length > 1
                          ? status[0].toUpperCase() +
                                status.substring(1).toLowerCase()
                          : status;
                      statusGiziMap[statusKey] =
                          (statusGiziMap[statusKey] ?? 0) + 1;
                    }
                  }

                  // C. Diagnosis Medis
                  String diag = cleanString(data['diagnosisMedis']);
                  if (diag != "Tidak Diketahui") {
                    diagnosisMap[diag] = (diagnosisMap[diag] ?? 0) + 1;
                  }

                  // D. Usia (Dengan Pengecekan Tipe Data Timestamp)
                  if (data['tanggalLahir'] != null &&
                      data['tanggalLahir'] is Timestamp) {
                    Timestamp tglLahir = data['tanggalLahir'];
                    int age = calculateAge(
                      tglLahir.toDate(),
                    ); // Menggunakan fungsi presisi

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
                  double bb = parseDouble(data['beratBadan']);
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
                  double tb = parseDouble(data['tinggiBadan']);
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

                // --- BERSIHKAN MAP (Hapus kategori dengan nilai 0) ---
                usiaMap.removeWhere((key, value) => value == 0);
                bbMap.removeWhere((key, value) => value == 0);
                tbMap.removeWhere((key, value) => value == 0);

                // --- PERSIAPAN DATA CHART ---
                Map<String, double> rawData = {};
                Map<String, double> chartData = {};
                List<Color> chartColors = [];
                String chartTitle = "";

                if (_selectedCategory == 'Pengguna' && isAdmin) {
                  chartTitle = "Distribusi Role Pengguna";
                  rawData = {
                    "Admin": roleCounts['admin']!.toDouble(),
                    "Ahli Gizi": roleCounts['ahli_gizi']!.toDouble(),
                    "Tamu": roleCounts['tamu']!.toDouble(),
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
                    Colors.orange,
                    Colors.green,
                    Colors.red,
                    Colors.blueGrey,
                    Colors.purple,
                  ];
                } else if (_selectedCategory == 'Status Gizi Anak (BB/U)') {
                  // --- KONFIGURASI CHART BARU ---
                  chartTitle = "Status Gizi Anak (BB/U)";
                  rawData = statusGiziAnakBBUMap;

                  // Palette warna indikatif
                  chartColors = [
                    Colors.green,
                    Colors.redAccent,
                    Colors.orangeAccent,
                    Colors.blueAccent,
                    Colors.purpleAccent,
                  ];
                } else if (_selectedCategory == 'Diagnosis Medis') {
                  chartTitle = "Diagnosis Medis Terbanyak";
                  // Urutkan diagnosis dari yang terbanyak
                  var sortedKeys = diagnosisMap.keys.toList(growable: false)
                    ..sort(
                      (k1, k2) =>
                          diagnosisMap[k2]!.compareTo(diagnosisMap[k1]!),
                    );

                  // Ambil Top 5, sisanya gabung ke "Lainnya"
                  double countLainnya = 0;
                  int maxItems = 5;
                  for (int i = 0; i < sortedKeys.length; i++) {
                    if (i < maxItems) {
                      rawData[sortedKeys[i]] = diagnosisMap[sortedKeys[i]]!;
                    } else {
                      countLainnya += diagnosisMap[sortedKeys[i]]!;
                    }
                  }
                  if (countLainnya > 0) rawData["Lainnya"] = countLainnya;
                  chartColors = [
                    Colors.redAccent,
                    Colors.blueAccent,
                    Colors.orangeAccent,
                    Colors.green,
                    Colors.purpleAccent,
                    Colors.grey,
                  ];
                } else if (_selectedCategory == 'Usia') {
                  chartTitle = "Rentang Usia Pasien";
                  rawData = usiaMap;
                  chartColors = [
                    Colors.lightBlue,
                    Colors.blue,
                    Colors.indigo,
                    Colors.deepPurple,
                    Colors.teal,
                  ];
                } else if (_selectedCategory == 'Berat Badan') {
                  chartTitle = "Sebaran Berat Badan";
                  rawData = bbMap;
                  chartColors = [
                    Colors.brown.shade300,
                    Colors.brown.shade400,
                    Colors.brown.shade500,
                    Colors.brown.shade600,
                    Colors.brown.shade700,
                    Colors.brown.shade800,
                  ];
                } else if (_selectedCategory == 'Tinggi Badan') {
                  chartTitle = "Sebaran Tinggi Badan";
                  rawData = tbMap;
                  chartColors = [
                    Colors.teal.shade300,
                    Colors.teal.shade400,
                    Colors.teal.shade500,
                    Colors.teal.shade700,
                  ];
                }

                chartData = Map.from(rawData);
                chartData.removeWhere((key, value) => value == 0);

                // Handle jika chartData kosong
                if (chartData.isEmpty) {
                  chartData = {"Tidak ada data": 1};
                  chartColors = [Colors.grey.shade300];
                }

                return FadeInTransition(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isAdmin)
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  "Total Pasien",
                                  totalPasien,
                                  const [Color(0xFF009444), Color(0xFF55C989)],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSummaryCard(
                                  "Total Pengguna",
                                  totalUsers,
                                  [Colors.blue.shade700, Colors.blue.shade400],
                                ),
                              ),
                            ],
                          )
                        else
                          _buildSummaryCard(
                            "Total Pasien Terdaftar",
                            totalPasien,
                            const [Color(0xFF009444), Color(0xFF55C989)],
                          ),
                        const SizedBox(height: 24),

                        const Text(
                          "Pilih Statistik:",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Container(
                          // Container luar untuk border & shadow (sama seperti desain lama)
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 2,
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

                            // 1. Logika Perubahan
                            onChanged: (newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedCategory = newValue;
                                  touchedIndex = -1;
                                });
                              }
                            },

                            // 2. (PENTING) Gunakan dropdownBuilder agar tampilan "Selected Item" rapi
                            // Ini mengubah tampilan input menjadi Teks biasa yang mudah diatur gayanya
                            dropdownBuilder: (context, selectedItem) {
                              return Text(
                                selectedItem ?? "",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize:
                                      14, // Sesuaikan ukuran font agar pas
                                  color: Colors.black87,
                                ),
                              );
                            },

                            // 3. Konfigurasi Popup (Menu Pilihan)
                            popupProps: PopupProps.menu(
                              fit: FlexFit.tight,
                              // A. Batasi tinggi agar hanya muat kira-kira 4 item (4 * 50px = 200px)
                              constraints: const BoxConstraints(maxHeight: 200),

                              // B. Tampilkan Scrollbar (Slider di kanan)
                              scrollbarProps: const ScrollbarProps(
                                thumbVisibility:
                                    true, // Selalu tampilkan scrollbar
                                thickness: 6,
                                radius: Radius.circular(10),
                              ),

                              // Styling menu popup
                              menuProps: MenuProps(
                                borderRadius: BorderRadius.circular(12),
                                elevation: 4,
                              ),
                            ),

                            // 4. Styling Dekorasi (Hilangkan border bawaan input)
                            dropdownDecoratorProps: const DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                border: InputBorder.none,
                                // Sesuaikan padding agar teks berada di tengah vertikal
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),

                            // 5. Ikon Kustom (Bar Chart Hijau)
                            dropdownButtonProps: const DropdownButtonProps(
                              icon: Icon(
                                Icons.category,
                                color: Color.fromARGB(255, 0, 148, 68),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  _buildChartTypeButton("Pie", Icons.pie_chart),
                                  _buildChartTypeButton("Bar", Icons.bar_chart),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Di dalam build method, sebelum "Pilih Statistik:"
                       // Di dalam build(), letakkan ini DI ATAS widget Container DropdownSearch

                          Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: PopupMenuButton<DateFilterType>(
                                  initialValue: _selectedFilterType,
                                  onSelected: _handleDateFilter,
                                  itemBuilder: (BuildContext context) =>
                                      <PopupMenuEntry<DateFilterType>>[
                                    const PopupMenuItem<DateFilterType>(
                                      value: DateFilterType.thisWeek,
                                      child: Row(children: [
                                        Icon(Icons.calendar_view_week,
                                            color: Colors.grey),
                                        SizedBox(width: 8),
                                        Text('Minggu Ini')
                                      ]),
                                    ),
                                    const PopupMenuItem<DateFilterType>(
                                      value: DateFilterType.thisMonth,
                                      child: Row(children: [
                                        Icon(Icons.calendar_month,
                                            color: Colors.grey),
                                        SizedBox(width: 8),
                                        Text('Bulan Ini')
                                      ]),
                                    ),
                                    const PopupMenuItem<DateFilterType>(
                                      value: DateFilterType.thisYear,
                                      child: Row(children: [
                                        Icon(Icons.calendar_today,
                                            color: Colors.grey),
                                        SizedBox(width: 8),
                                        Text('Tahun Ini')
                                      ]),
                                    ),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem<DateFilterType>(
                                      value: DateFilterType.custom,
                                      child: Row(children: [
                                        Icon(Icons.date_range,
                                            color: Colors.grey),
                                        SizedBox(width: 8),
                                        Text('Pilih Tanggal Sendiri (Custom)')
                                      ]),
                                    ),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem<DateFilterType>(
                                      value: DateFilterType.all,
                                      child: Row(children: [
                                        Icon(Icons.all_inclusive,
                                            color: Color(0xFF009444)),
                                        SizedBox(width: 8),
                                        Text('Semua Waktu (Reset)',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF009444)))
                                      ]),
                                    ),
                                  ],
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
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
                                                  color: Color(0xFF009444)),
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
                        const SizedBox(height: 50),

                        Text(
                          chartTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // WIDGET DIAGRAM LINGKARAN
                        RepaintBoundary(
                          // <--- TAMBAHKAN INI
                          key: _chartKey, // <--- PASANG KEY DISINI
                          child: Container(
                            height: 300,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors
                                  .white, // Pastikan background putih agar terlihat di PDF
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: _chartType == 'Pie'
                                ? _buildPieChartOnly(
                                    dataMap: chartData,
                                    colors: chartColors,
                                    touchedIndex: touchedIndex,
                                    onTouch: (index) =>
                                        setState(() => touchedIndex = index),
                                  )
                                : _buildBarChartOnly(
                                    dataMap: chartData,
                                    colors: chartColors,
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // WIDGET INDIKATOR (LEGEND)
                        const Text(
                          "Detail Data:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildIndicatorList(chartData, chartColors),

                        const SizedBox(height: 50),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Tampilkan loading indicator kecil jika perlu atau langsung panggil
                              try {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Membuat File PDF..."),
                                  ),
                                );

                                final Uint8List? chartImage =
                                    await _captureChart();
                                final dataToSend = rawData.isEmpty
                                    ? {"Tidak ada data": 0.0}
                                    : rawData;

                                await StatisticsPdfService.generateAndOpenPdf(
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
                              backgroundColor: const Color.fromARGB(
                                255,
                                0,
                                148,
                                68,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
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

  Widget _buildChartTypeButton(String type, IconData icon) {
    bool isSelected = _chartType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _chartType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [const BoxShadow(color: Colors.black12, blurRadius: 2)]
              : [],
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected
              ? const Color.fromARGB(255, 0, 148, 68)
              : Colors.grey,
        ),
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

    // Mencari nilai maksimum untuk skala Y-axis
    double maxY = 0;
    for (var val in dataMap.values) {
      if (val > maxY) maxY = val;
    }
    // Tambahkan sedikit buffer di atas
    maxY = maxY + (maxY * 0.2);
    if (maxY == 0) maxY = 10;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String key = dataMap.keys.elementAt(group.x.toInt());
              return BarTooltipItem(
                '$key\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: (rod.toY).toInt().toString(),
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
                int index = value.toInt();
                if (index < 0 || index >= dataMap.length) {
                  return const SizedBox();
                }

                // Tampilkan teks singkatan atau indeks jika label terlalu panjang
                // Logic: Ambil 3 huruf pertama atau tampilkan inisial
                String text = dataMap.keys.elementAt(index);
                if (text.length > 5) {
                  text = "${text.substring(0, 6)}..";
                }

                return SideTitleWidget(
                  // Ganti 'axisSide: meta.axisSide' dengan 'meta: meta'
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
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
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
                width: 20, // Lebar batang
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

  // --- WIDGET HELPER: PIE CHART ---
  Widget _buildPieChartOnly({
    required Map<String, double> dataMap,
    required List<Color> colors,
    required int touchedIndex,
    required Function(int) onTouch,
  }) {
    double total = dataMap.values.fold(0, (prev, item) => prev + item);

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
            onTouch(pieTouchResponse.touchedSection!.touchedSectionIndex);
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: List.generate(dataMap.length, (i) {
          final isTouched = i == touchedIndex;
          final radius = isTouched ? 110.0 : 100.0;
          final fontSize = isTouched ? 20.0 : 14.0;
          final value = dataMap.values.elementAt(i);
          final percentage = total > 0
              ? (value / total * 100).toStringAsFixed(1)
              : "0";

          return PieChartSectionData(
            color: colors[i % colors.length],
            value: value,
            title: '$percentage%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [const Shadow(color: Colors.black26, blurRadius: 2)],
            ),
          );
        }),
      ),
    );
  }

  // --- WIDGET HELPER: LIST INDIKATOR ---
  Widget _buildIndicatorList(Map<String, double> dataMap, List<Color> colors) {
    double total = dataMap.values.fold(0, (prev, item) => prev + item);

    return Column(
      children: List.generate(dataMap.length, (index) {
        final key = dataMap.keys.elementAt(index);
        final value = dataMap.values.elementAt(index);
        final color = colors[index % colors.length];

        bool isDummyData = key == "Tidak ada data";

        // Jika dummy, paksa tampilkan "0%". Jika tidak, hitung normal.
        final percentageStr = isDummyData
            ? "0%"
            : (total > 0
                  ? "${((value / total) * 100).toStringAsFixed(1)}%"
                  : "0%");

        // Jika dummy, paksa tampilkan "0". Jika tidak, ambil value aslinya.
        final countStr = isDummyData ? "0" : "${value.toInt()}";

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
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
              // Badge Warna & Persentase
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
              // Nama Kategori
              Expanded(
                child: Text(
                  key,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              // Jumlah Angka
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
        );
      }),
    );
  }

  Widget _buildSummaryCard(String title, int count, List<Color> colors) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
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
    );
  }
}
