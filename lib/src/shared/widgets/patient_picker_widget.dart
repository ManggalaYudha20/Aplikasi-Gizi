// lib/src/shared/widgets/patient_picker_widget.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/models/patient_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/models/patient_anak_model.dart';

class PatientPickerWidget extends StatefulWidget {
  final Function(double weight, double height, String gender, DateTime birthDate) onPatientSelected;

  const PatientPickerWidget({
    super.key, 
    required this.onPatientSelected
  });

  @override
  State<PatientPickerWidget> createState() => PatientPickerWidgetState();
}

class PatientPickerWidgetState extends State<PatientPickerWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  String? _selectedPatientId; 

  // UBAH 1: Ubah dari 'late Stream' menjadi 'Stream?' (Nullable)
  // Alasannya: Kita butuh waktu untuk fetch role user dulu, jadi stream awalnya null.
  Stream<QuerySnapshot<Map<String, dynamic>>>? _patientStream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  // UBAH 2: Ubah logic _initStream menjadi Asynchronous untuk cek role
  Future<void> _initStream() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Ambil Data Role User dari Firestore
      // Asumsi: Anda menyimpan data role di collection 'users'
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // Ambil field 'role', jika tidak ada default ke 'ahli_gizi'
      final String role = userDoc.data()?['role'] ?? 'ahli_gizi';
      
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('patients');

      // 2. Tentukan Query Berdasarkan Role
      if (role == 'admin') {
        // ADMIN: Bisa melihat SEMUA data (Tanpa filter createdBy)
        query = query.orderBy('tanggalPemeriksaan', descending: true);
      } else {
        // AHLI GIZI: Hanya melihat data BUATAN SENDIRI
        query = query
            .where('createdBy', isEqualTo: user.uid)
            .orderBy('tanggalPemeriksaan', descending: true);
      }

      // 3. Update Stream di dalam setState
      if (mounted) {
        setState(() {
          _patientStream = query.limit(50).snapshots();
        });
      }
    } catch (e) {
      debugPrint("Error fetching role or stream: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void resetSelection() {
    setState(() {
      _selectedPatientId = null; 
      _searchController.clear(); 
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ambil Data dari Pasien',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        
        // --- SEARCH BAR ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari nama atau No. RM...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              suffixIcon: _searchQuery.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _selectedPatientId = null; 
                      });
                    },
                  ) 
                : null,
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),

        const SizedBox(height: 8),

        SizedBox(
          height: 140, 
          // UBAH 3: Handle kondisi jika _patientStream masih null (sedang loading role)
          child: _patientStream == null 
            ? const Center(child: CircularProgressIndicator()) 
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _patientStream, 
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const SizedBox.shrink();
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState('Belum ada data pasien.');
                  }

                  final allDocs = snapshot.data!.docs;

                  final filteredDocs = allDocs.where((doc) {
                    final data = doc.data();
                    final String nama = (data['namaLengkap'] ?? '').toString().toLowerCase();
                    final String norm = (data['noRM'] ?? '').toString().toLowerCase();
                    
                    return nama.contains(_searchQuery) || norm.contains(_searchQuery);
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return _buildEmptyState('Pasien tidak ditemukan.');
                  }

                  return ListView.builder(
                    key: const PageStorageKey('patient_list_scroll'), 
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final data = doc.data();
                      
                      final String docId = doc.id;

                      final String tipePasien = data['tipePasien'] ?? 'dewasa';
                      final bool isAnak = tipePasien == 'anak';
                      
                      String nama;
                      String noRM;
                      DateTime tglLahir;
                      double berat;
                      double tinggi;
                      String gender;

                      try {
                        if (isAnak) {
                           final patient = PatientAnak.fromFirestore(doc);
                           nama = patient.namaLengkap;
                           noRM = patient.noRM;
                           tglLahir = patient.tanggalLahir;
                           berat = patient.beratBadan.toDouble();
                           tinggi = patient.tinggiBadan.toDouble();
                           gender = patient.jenisKelamin;
                        } else {
                           final patient = Patient.fromFirestore(doc);
                           nama = patient.namaLengkap;
                           noRM = patient.noRM;
                           tglLahir = patient.tanggalLahir;
                           berat = patient.beratBadan.toDouble();
                           tinggi = patient.tinggiBadan.toDouble();
                           gender = patient.jenisKelamin;
                        }
                      } catch (e) {
                        return const SizedBox.shrink(); 
                      }

                      return _buildPatientCard(
                        context: context, 
                        docId: docId, 
                        name: nama, 
                        noRM: noRM, 
                        dob: tglLahir, 
                        weight: berat, 
                        height: tinggi, 
                        gender: gender,
                        isChild: isAnak
                      );
                    },
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12, left: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    int days = now.day - birthDate.day;

    if (months < 0 || (months == 0 && days < 0)) {
      years--;
      months += 12;
    }
    // Jika hari ini belum mencapai tanggal lahir di bulan ini
    if (days < 0) {
      months--;
    }
    
    // Tampilan output
    if (years > 0) {
      return '$years thn ${months > 0 ? '$months bln' : ''}';
    } else {
      return '$months bulan';
    }
  }

 Widget _buildPatientCard({
    required BuildContext context, 
    required String docId, 
    required String name, 
    required String noRM, 
    required DateTime dob, 
    required double weight, 
    required double height, 
    required String gender,
    required bool isChild,
  }) {
    final bool isSelected = _selectedPatientId == docId;

    return Card(
      elevation: isSelected ? 4 : 2, 
      margin: const EdgeInsets.only(right: 12, bottom: 4, top: 4, left: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected 
          ? const BorderSide(color: Colors.green, width: 2.0) 
          : BorderSide.none,
      ),
      color: isSelected ? Colors.green[50] : null, 
      
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _selectedPatientId = docId;
          });

          widget.onPatientSelected(
            weight,
            height,
            gender,
            dob
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Data $name terpilih!'),
              duration: const Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        },
        child: SizedBox( 
          width: 140,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- Header: Icon & No RM ---
                    Row(
                      children: [
                        Icon(
                          isChild ? Icons.child_care : Icons.person, 
                          size: 16, 
                          color: isChild ? Colors.orange : Colors.blue
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'No. RM : $noRM',
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // --- Nama Pasien ---
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    const Divider(height: 8),

                    // --- UPDATE BAGIAN INI (Ganti BB/TB dengan Usia/Gender) ---
                    
                    // 1. Baris Usia
                    Row(
                      children: [
                        const Icon(Icons.cake, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _calculateAge(dob),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // 2. Baris Jenis Kelamin
                    Row(
                      children: [
                        Icon(
                          gender.toLowerCase().contains('laki') ? Icons.male : Icons.female, 
                          size: 12, 
                          color: gender.toLowerCase().contains('laki') ? Colors.blue : Colors.pink
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            gender,
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Icon Centang jika dipilih
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}