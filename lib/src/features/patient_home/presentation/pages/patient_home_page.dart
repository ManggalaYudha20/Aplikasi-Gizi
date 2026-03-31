// lib/src/features/patient_home/presentation/pages/patient_home_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/presentation/pages/data_form_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/models/patient_model.dart';
//import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/presentation/pages/patient_detail_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/fade_in_transition.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/services/user_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/models/patient_filter_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/services/patient_filter_form.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/models/patient_anak_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/presentation/pages/data_form_anak_page.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/presentation/pages/inbox_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/services/share_patient_service.dart';

// ── Widgets yang diekstrak ───────────────────────────────────────────────────
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/presentation/widgets/patient_list_card.dart';

// Dipertahankan agar navigasi di PatientListCard & PatientAnakListCard bisa
// menggunakan PageRouteBuilder tanpa import tambahan di widget tersebut.
// (Navigasi ke PatientDetailPage sudah di dalam patient_list_card.dart)
export 'package:aplikasi_diagnosa_gizi/src/features/patient_home/presentation/pages/patient_detail_page.dart';

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

  // ── Toggle Status Selesai ─────────────────────────────────────────────────
  // Logika Firestore tetap di sini; hanya callback yang diteruskan ke card.
  Future<void> _togglePatientStatus(String docId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(docId)
          .update({'isCompleted': !currentStatus});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !currentStatus
                  ? 'Pasien ditandai Selesai'
                  : 'Pasien ditandai Belum Selesai',
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: !currentStatus ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengupdate status: $e')),
        );
      }
    }
  }

  void _applyFilters(PatientFilterModel newFilters) {
    setState(() {
      _activeFilters = newFilters;
    });
  }

  void _showFilterModal(BuildContext context) async {
    final newFilters = await showModalBottomSheet<PatientFilterModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PatientFilterSheet(
          currentFilters: _activeFilters,
          onResetPressed: () {
            _applyFilters(PatientFilterModel());
          },
        );
      },
    );

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
                  onPressed: () => _searchController.clear(),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(title: 'Daftar Pasien', subtitle: ''),
      body: SafeArea(
        child: FutureBuilder<String?>(
          future: _userRoleFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(
                  child: Text('Gagal memuat data pengguna.'));
            }

            final userRole = snapshot.data;
            final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

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

            return FadeInTransition(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Column(
                  children: [
                    // ── Search Bar + Filter + Inbox ────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 5),
                      child: Row(
                        children: [
                          Expanded(child: _buildSearchBar()),
                          const SizedBox(width: 8),

                          // Filter
                          _buildIconContainer(
                            child: IconButton(
                              icon: Icon(
                                Icons.filter_list,
                                color: !_activeFilters.isDefault
                                    ? const Color.fromARGB(255, 0, 148, 68)
                                    : Colors.grey,
                              ),
                              onPressed: () => _showFilterModal(context),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Inbox
                          _buildIconContainer(
                            child: StreamBuilder<QuerySnapshot>(
                              stream:
                                  SharePatientService().getPendingRequests(),
                              builder: (context, snapshot) {
                                int pendingCount = 0;
                                if (snapshot.hasData) {
                                  pendingCount = snapshot.data!.docs.length;
                                }
                                return Badge(
                                  label: Text(pendingCount.toString()),
                                  isLabelVisible: pendingCount > 0,
                                  backgroundColor: Colors.red,
                                  child: IconButton(
                                    icon: const Icon(Icons.move_to_inbox,
                                        color: Colors.blue),
                                    tooltip: 'Kotak Masuk Rujukan',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const InboxPage(),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),

                    // ── Daftar Pasien ──────────────────────────────────────
                    Expanded(
                      child: StreamBuilder<
                          QuerySnapshot<Map<String, dynamic>>>(
                        stream: patientQuery.snapshots(
                            includeMetadataChanges: true),
                        builder: (context, streamSnapshot) {
                          if (streamSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (streamSnapshot.hasError) {
                            return Center(
                                child: Text(
                                    'Error: ${streamSnapshot.error}'));
                          }
                          if (!streamSnapshot.hasData ||
                              streamSnapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline,
                                      size: 60, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'Belum ada data pasien',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.grey),
                                  ),
                                  Text(
                                    'Tekan tombol + untuk menambah data baru',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }

                          // ── Filter & Sort ──────────────────────────────
                          final patients = streamSnapshot.data!.docs;

                          final filteredPatients = patients.where((doc) {
                            final data = doc.data();
                            final searchQueryLower =
                                _searchQuery.toLowerCase();

                            bool matchesSearch = false;
                            final String namaLengkap =
                                data['namaLengkap'] ?? '';
                            final String noRM = data['noRM'] ?? '';

                            matchesSearch =
                                namaLengkap.toLowerCase().contains(
                                        searchQueryLower) ||
                                    noRM.toLowerCase().contains(
                                        searchQueryLower);

                            if (!matchesSearch &&
                                (data['tipePasien'] ?? 'dewasa') ==
                                    'dewasa') {
                              final String diagnosisMedis =
                                  data['diagnosisMedis'] ?? '';
                              if (diagnosisMedis.toLowerCase().contains(
                                  searchQueryLower)) {
                                matchesSearch = true;
                              }
                            }
                            if (!matchesSearch) return false;

                            return _activeFilters.matches(data);
                          }).toList();

                          filteredPatients.sort((a, b) {
                            final dataA = a.data();
                            final dataB = b.data();

                            final Timestamp? timeA =
                                dataA['tanggalPemeriksaan'] as Timestamp?;
                            final Timestamp? timeB =
                                dataB['tanggalPemeriksaan'] as Timestamp?;
                            final DateTime dateA =
                                timeA?.toDate() ?? DateTime(1900);
                            final DateTime dateB =
                                timeB?.toDate() ?? DateTime(1900);
                            final int dateComparison =
                                dateB.compareTo(dateA);
                            if (dateComparison != 0) return dateComparison;

                            final String nameA =
                                (dataA['namaLengkap'] ?? '')
                                    .toString()
                                    .toLowerCase();
                            final String nameB =
                                (dataB['namaLengkap'] ?? '')
                                    .toString()
                                    .toLowerCase();
                            return nameA.compareTo(nameB);
                          });

                          return Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: filteredPatients.length,
                                  itemBuilder: (context, index) {
                                    final doc = filteredPatients[index];
                                    final data = doc.data();
                                    final String tipePasien =
                                        data['tipePasien'] ?? 'dewasa';

                                    if (tipePasien == 'anak') {
                                      // ── Card Pasien Anak ─────────────
                                      final patientAnak =
                                          PatientAnak.fromFirestore(doc);
                                      return PatientAnakListCard(
                                        patient: patientAnak,
                                        onToggleStatus: () =>
                                            _togglePatientStatus(
                                          patientAnak.id,
                                          patientAnak.isCompleted,
                                        ),
                                      );
                                    } else {
                                      // ── Card Pasien Dewasa ───────────
                                      final patient =
                                          Patient.fromFirestore(doc);
                                      return PatientListCard(
                                        patient: patient,
                                        onToggleStatus: () =>
                                            _togglePatientStatus(
                                          patient.id,
                                          patient.isCompleted,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
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

      // ── FAB: SpeedDial ────────────────────────────────────────────────────
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: const Color.fromARGB(255, 0, 148, 68),
        foregroundColor: Colors.white,
        buttonSize: const Size(55.0, 55.0),
        childrenButtonSize: const Size(55.0, 55.0),
        visible: true,
        curve: Curves.bounceIn,
        direction: SpeedDialDirection.up,
        overlayOpacity: 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        spacing: 12.0,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.child_care),
            label: 'Pasien Anak',
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const DataFormAnakPage()),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.person),
            label: 'Pasien Dewasa',
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DataFormPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Helper: Container dekoratif untuk tombol ikon di toolbar ─────────────
  Widget _buildIconContainer({required Widget child}) {
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
      child: child,
    );
  }
}