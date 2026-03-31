import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/account_page/logic/backup_restore_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/models/patient_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/models/patient_anak_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';

class BackupPage extends StatefulWidget {
  final String currentUserId;
  final String userRole; // Tambahkan parameter role

  const BackupPage({
    super.key, 
    required this.currentUserId, 
    required this.userRole,
  });

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final BackupRestoreService _backupService = BackupRestoreService();

  // Pisahkan list agar sesuai dengan kebutuhan BackupRestoreService
  List<Patient> _allDewasa = [];
  List<PatientAnak> _allAnak = [];
  
  List<Patient> _selectedDewasa = [];
  List<PatientAnak> _selectedAnak = [];

  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  // Ambil data pasien dengan filter berdasarkan role
  Future<void> _fetchPatients() async {
    setState(() => _isLoading = true);
    try {
      // 1. Tentukan Query Dasar
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('patients');

      // 2. LOGIKA ADMIN: Jika bukan admin, filter berdasarkan createdBy
      // Jika admin, biarkan query tanpa filter createdBy untuk akses semua data
      if (widget.userRole != 'admin') {
        query = query.where('createdBy', isEqualTo: widget.currentUserId);
      }

      final snapshot = await query.get();

      if (!mounted) return;

      List<Patient> tempDewasa = [];
      List<PatientAnak> tempAnak = [];

      // 3. Pisahkan data berdasarkan tipePasien
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['tipePasien'] == 'anak') {
          tempAnak.add(PatientAnak.fromFirestore(doc));
        } else {
          tempDewasa.add(Patient.fromFirestore(doc));
        }
      }

      setState(() {
        _allDewasa = tempDewasa;
        _allAnak = tempAnak;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedDewasa = List.from(_allDewasa);
        _selectedAnak = List.from(_allAnak);
      } else {
        _selectedDewasa.clear();
        _selectedAnak.clear();
      }
    });
  }

  Future<void> _handleBackup() async {
    if (_selectedDewasa.isEmpty && _selectedAnak.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih setidaknya 1 pasien')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Pilih Format Backup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.data_object, color: Colors.blue),
                title: const Text('Simpan sebagai JSON (Rekomendasi)'),
                onTap: () {
                  Navigator.pop(context);
                  _executeBackup(format: 'json');
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.green),
                title: const Text('Simpan sebagai Excel (.csv)'),
                onTap: () {
                  Navigator.pop(context);
                  _executeBackup(format: 'csv');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _executeBackup({required String format}) async {
    try {
      if (format == 'csv') {
        await _backupService.exportDataToCSV(
          selectedDewasa: _selectedDewasa,
          selectedAnak: _selectedAnak, 
        );
      } else {
        await _backupService.exportDataToJSON(
          selectedDewasa: _selectedDewasa,
          selectedAnak: _selectedAnak,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _handleUpload() async {
    setState(() => _isUploading = true);
    try {
      await _backupService.importDataFromJSON(widget.currentUserId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil mengimpor data!')));
      _fetchPatients();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAllSelected = (_allDewasa.length + _allAnak.length) > 0 &&
        (_selectedDewasa.length + _selectedAnak.length) == (_allDewasa.length + _allAnak.length);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(title: 'Cadangan', subtitle: 'Backup & Restore Data Pasien'),
      body: _isLoading || _isUploading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      // Tombol Ekspor/Backup
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _handleBackup,
                          icon: const Icon(Icons.download, size: 20),
                          label: Text('Backup (${_selectedDewasa.length + _selectedAnak.length})'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 0, 148, 68),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Tombol Impor/Upload
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _handleUpload,
                          icon: const Icon(Icons.upload_file, size: 20),
                          label: const Text('Upload JSON'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                CheckboxListTile(
                  title: const Text('Pilih Semua Pasien', style: TextStyle(fontWeight: FontWeight.bold)),
                  value: isAllSelected,
                  onChanged: _toggleSelectAll,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    children: [
                      if (_allDewasa.isNotEmpty) ...[
                        const Padding(padding: EdgeInsets.all(8.0), child: Text("PASIEN DEWASA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                        ..._allDewasa.map((p) => CheckboxListTile(
                          title: Text(p.namaLengkap),
                          subtitle: Text('RM: ${p.noRM} | ${p.diagnosisMedis}'),
                          value: _selectedDewasa.contains(p),
                          onChanged: (val) => setState(() => val! ? _selectedDewasa.add(p) : _selectedDewasa.remove(p)),
                        )),
                      ],

                      const Divider(height: 20, thickness: 2),

                      if (_allAnak.isNotEmpty) ...[
                        const Padding(padding: EdgeInsets.all(8.0), child: Text("PASIEN ANAK", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                        ..._allAnak.map((p) => CheckboxListTile(
                          title: Text(p.namaLengkap),
                          subtitle: Text('RM: ${p.noRM} | ${p.diagnosisMedis}'),
                          value: _selectedAnak.contains(p),
                          onChanged: (val) => setState(() => val! ? _selectedAnak.add(p) : _selectedAnak.remove(p)),
                        )),
                      ],
                    ],
                  ),
                ),
              ],
            ),
      
    );
  }
}