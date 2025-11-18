// lib/src/features/home/presentation/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/presentation/pages/data_form_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/models/patient_model.dart';
import 'patient_detail_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/fade_in_transition.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/services/user_service.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/patient_filter_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/patient_filter_form.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/models/patient_anak_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/presentation/pages/data_form_anak_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/presentation/pages/patient_anak_detail_page.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final UserService _userService = UserService();
  late Future<String?> _userRoleFuture;

  PatientFilterModel _activeFilters = PatientFilterModel();

  @override
  void initState() {
    super.initState();
    _userRoleFuture = _userService.getUserRole();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters(PatientFilterModel newFilters) {
    setState(() {
      _activeFilters = newFilters;
    });
  }

  void _showFilterModal(BuildContext context) async {
    // Tampilkan modal dan tunggu hasilnya (PatientFilterModel)
    final newFilters = await showModalBottomSheet<PatientFilterModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Buat transparan agar border radius sheet terlihat
      builder: (context) {
        // Panggil widget reusable Anda
        return PatientFilterSheet(
          currentFilters: _activeFilters,
          // --- KIRIM FUNGSI CALLBACK KE SHEET ---
          onResetPressed: () {
            // Panggil fungsi yang me-reset state halaman home
            _applyFilters(PatientFilterModel());
          },
        );
      },
    );

    // Jika pengguna menekan "Terapkan" atau "Reset", 'newFilters' tidak akan null
    if (newFilters != null) {
      setState(() {
        _activeFilters = newFilters;
      });
    }
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari nama atau No. RM pasien...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(150, 255, 255, 255),
      appBar: const CustomAppBar(title: 'Daftar Pasien', subtitle: ''),
      body: SafeArea(
        child: FutureBuilder<String?>(
          future: _userRoleFuture,
          builder: (context, snapshot) {
            // State 1: Menunggu data role dari future
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // State 2: Terjadi error atau tidak ada data role
            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(child: Text("Gagal memuat data pengguna."));
            }

            // State 3: Data berhasil didapat
            final userRole = snapshot.data;
            final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

            // Buat query Firestore secara dinamis berdasarkan role
            Query<Map<String, dynamic>> patientQuery;
            if (userRole == 'admin') {
              patientQuery = FirebaseFirestore.instance
                  .collection('patients')
                  .orderBy('namaLengkap', descending: false);
            } else {
              patientQuery = FirebaseFirestore.instance
                  .collection('patients')
                  .where('createdBy', isEqualTo: currentUserUid);
            }

            // Kembalikan UI utama dengan query yang sudah benar
            return FadeInTransition(
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSearchBar(), // Search bar tanpa margin
                          ),
                          const SizedBox(width: 8),
                          // Tombol Filter
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.filter_list,
                                // Beri warna jika filter aktif
                                color: !_activeFilters.isDefault
                                    ? const Color.fromARGB(255, 0, 148, 68)
                                    : Colors.grey,
                              ),
                              onPressed: () {
                                _showFilterModal(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: patientQuery
                            .snapshots(), // Menggunakan query yang dinamis
                        builder: (context, streamSnapshot) {
                          if (streamSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (streamSnapshot.hasError) {
                            return Center(
                              child: Text('Error: ${streamSnapshot.error}'),
                            );
                          }
                          if (!streamSnapshot.hasData ||
                              streamSnapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Belum ada data pasien',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    'Tekan tombol + untuk menambah data baru',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }

                          final patients = streamSnapshot.data!.docs;

                          // Filter pasien berdasarkan query pencarian
                          final filteredPatients = patients.where((doc) {
                            final data = doc.data();
                            final searchQueryLower = _searchQuery.toLowerCase();

                            // --- 1. LOGIKA PENCARIAN (Search) ---
                            // (Logika search tetap di sini, ini sudah benar)
                            bool matchesSearch = false;
                            final String namaLengkap =
                                data['namaLengkap'] ?? '';
                            final String noRM = data['noRM'] ?? '';

                            matchesSearch =
                                namaLengkap.toLowerCase().contains(
                                  searchQueryLower,
                                ) ||
                                noRM.toLowerCase().contains(searchQueryLower);

                            if (!matchesSearch &&
                                (data['tipePasien'] ?? 'dewasa') == 'dewasa') {
                              final String diagnosisMedis =
                                  data['diagnosisMedis'] ?? '';
                              if (diagnosisMedis.toLowerCase().contains(
                                searchQueryLower,
                              )) {
                                matchesSearch = true;
                              }
                            }
                            if (!matchesSearch) return false;

                            // --- 2. LOGIKA FILTER (Sekarang Bersih) ---
                            // Panggil method 'matches' yang baru dengan data mentah
                            // Logika 'isDefault' sudah ada di dalam method 'matches'
                            final bool matchesFilter = _activeFilters.matches(
                              data,
                            );

                            // Pasien hanya ditampilkan jika cocok KEDUA-DUANYA
                            return matchesSearch && matchesFilter;
                          }).toList();

                          if (filteredPatients.isEmpty &&
                              _searchQuery.isNotEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.search_off,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tidak ada pasien dengan nama atau No. RM "$_searchQuery"',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredPatients.length,
                            itemBuilder: (context, index) {
                              final doc = filteredPatients[index];
                              final data = doc.data();

                              // Tentukan tipe, default 'dewasa' untuk data lama
                              final String tipePasien =
                                  data['tipePasien'] ?? 'dewasa';

                              if (tipePasien == 'anak') {
                                // Buat model anak
                                final patientAnak = PatientAnak.fromFirestore(
                                  doc,
                                );
                                // Buat card anak (dibuat di 6c)
                                return _buildPatientAnakCard(
                                  context,
                                  patientAnak,
                                );
                              } else {
                                final patient = Patient.fromFirestore(
                                  filteredPatients[index],
                                );
                                return _buildPatientCard(context, patient);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: SpeedDial(
        // Ikon utama saat tombol tertutup
        icon: Icons.add,
        // Ikon saat tombol terbuka (opsional)
        activeIcon: Icons.close,
        backgroundColor: const Color.fromARGB(255, 0, 148, 68),
        foregroundColor: Colors.white,
        buttonSize: const Size(55.0, 55.0), // Ukuran standar FAB
        childrenButtonSize: const Size(55.0, 55.0), // Ukuran tombol anak
        visible: true,
        curve: Curves.bounceIn, // Jenis animasi
        // Ini adalah arah animasi "muncul ke atas" yang Anda inginkan
        direction: SpeedDialDirection.up,
        overlayOpacity: 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            16.0,
          ), // Atur radius sudut di sini
        ),
        spacing: 12.0,

        // Ini adalah daftar tombol Anda (Dewasa & Anak)
        children: [
          SpeedDialChild(
            child: const Icon(Icons.child_care),
            label: 'Pasien Anak (0-5 th)',
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            onTap: () {
              // Langsung navigasi ke form anak
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DataFormAnakPage(),
                ),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.person),
            label: 'Pasien Dewasa',
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            onTap: () {
              // Langsung navigasi ke form dewasa
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DataFormPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPatientAnakCard(BuildContext context, PatientAnak patient) {
    // Tentukan warna berdasarkan status gizi anak
    Color statusColor = Colors.grey;
    String statusGizi = patient.statusGiziIMTU ?? 'Belum ada status';

    if (statusGizi.contains('kurang') || statusGizi.contains('buruk')) {
      statusColor = Colors.orange;
    } else if (statusGizi.contains('lebih')) {
      statusColor = Colors.red;
    } else if (statusGizi.contains('baik') || statusGizi.contains('normal')) {
      statusColor = Colors.green;
    }

    String formattedDate = DateFormat(
      'dd MMM yyyy',
      'id_ID',
    ).format(patient.tanggalPemeriksaan);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // !! PENTING: Navigasi ke Halaman Detail ANAK !!
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientAnakDetailPage(patient: patient),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      patient.namaLengkap,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),

              // Tampilkan data demografi anak
              Text(
                '${patient.jenisKelamin} | ${patient.usiaFormatted} | No.RM: ${patient.noRM}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 8),

              // Tampilkan Status Gizi Anak
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Status Gizi Anak:', style: TextStyle(fontSize: 13)),
                  Text(
                    statusGizi,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, Patient patient) {
    Color statusColor = Colors.grey;
    String statusGizi = patient.monevStatusGizi ?? 'Belum ada status';

    if (statusGizi.contains('Kurang') || statusGizi.contains('Buruk')) {
      statusColor = Colors.orange;
    } else if (statusGizi.contains('Lebih') ||
        statusGizi.contains('Obesitas')) {
      statusColor = Colors.red;
    } else if (statusGizi.contains('Baik') || statusGizi.contains('Normal')) {
      statusColor = Colors.green;
    }

    // 2. Format Tanggal Pemeriksaan
    // Pastikan patient.tanggalPemeriksaan adalah DateTime. Jika Timestamp, konversi dulu di Model.
    String formattedDate = DateFormat(
      'dd MMM yyyy',
      'id_ID',
    ).format(patient.tanggalPemeriksaan);

    // 3. Hitung Usia (Opsional, jika ingin ditampilkan)
    DateTime today = DateTime.now();
    int age = today.year - patient.tanggalLahir.year;
    if (patient.tanggalLahir.month > today.month ||
        (patient.tanggalLahir.month == today.month &&
            patient.tanggalLahir.day > today.day)) {
      age--; // Kurangi 1 jika belum ulang tahun
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  PatientDetailPage(patient: patient),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                // Posisi awal dari kiri (-1.0) ke posisi akhir di tengah (0.0)
                const begin = Offset(-1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;

                var tween = Tween(
                  begin: begin,
                  end: end,
                ).chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);

                return SlideTransition(position: offsetAnimation, child: child);
              },
              transitionDuration: const Duration(
                milliseconds: 400,
              ), // Atur durasi animasi
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      patient.namaLengkap,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),

              // --- BARIS 2: Detail Demografi Kecil ---
              Text(
                '${patient.jenisKelamin} | $age Tahun | No.RM: ${patient.noRM}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),

              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 8),

              // --- BARIS 3: Diagnosis & Status Gizi ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Diagnosis Medis',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        Text(
                          patient.diagnosisMedis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end, // Rata kanan
                      children: [
                        const Text(
                          'Status Gizi',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Text(
                            statusGizi,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
