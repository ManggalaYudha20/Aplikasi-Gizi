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

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 5),
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
                    _buildSearchBar(),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: patientQuery.snapshots(), // Menggunakan query yang dinamis
                        builder: (context, streamSnapshot) {
                          if (streamSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (streamSnapshot.hasError) {
                            return Center(child: Text('Error: ${streamSnapshot.error}'));
                          }
                          if (!streamSnapshot.hasData || streamSnapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline, size: 60, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('Belum ada data pasien', style: TextStyle(fontSize: 18, color: Colors.grey)),
                                  Text('Tekan tombol + untuk menambah data baru', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            );
                          }

                                final patients = streamSnapshot.data!.docs;

                                // Filter pasien berdasarkan query pencarian
                                final filteredPatients = patients.where((doc) {
                                  final patient = Patient.fromFirestore(doc);
                                  final searchQueryLower = _searchQuery
                                      .toLowerCase();
                                  return patient.namaLengkap
                                          .toLowerCase()
                                          .contains(searchQueryLower) ||
                                      patient.noRM.toLowerCase().contains(
                                        searchQueryLower,
                                      ) ||
                                      patient.diagnosisMedis
                                          .toLowerCase()
                                          .contains(searchQueryLower);
                                }).toList();

                                if (filteredPatients.isEmpty &&
                                    _searchQuery.isNotEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                    final patient = Patient.fromFirestore(
                                      filteredPatients[index],
                                    );
                                    return _buildPatientCard(context, patient);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DataFormPage()),
          );
        },
        backgroundColor: const Color.fromARGB(255, 0, 148, 68),
        child: const Icon(Icons.add, size: 28, color: Colors.white),
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, Patient patient) {

    Color statusColor = Colors.grey;
    String statusGizi = patient.monevStatusGizi ?? 'Belum ada status';
    
    if (statusGizi.contains('Kurang') || statusGizi.contains('Buruk')) {
      statusColor = Colors.orange;
    } else if (statusGizi.contains('Lebih') || statusGizi.contains('Obesitas')) {
      statusColor = Colors.red;
    } else if (statusGizi.contains('Baik') || statusGizi.contains('Normal')) {
      statusColor = Colors.green;
    }

    // 2. Format Tanggal Pemeriksaan
    // Pastikan patient.tanggalPemeriksaan adalah DateTime. Jika Timestamp, konversi dulu di Model.
    String formattedDate = DateFormat('dd MMM yyyy', 'id_ID').format(patient.tanggalPemeriksaan);

    // 3. Hitung Usia (Opsional, jika ingin ditampilkan)
    int age = DateTime.now().year - patient.tanggalLahir.year;

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
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
