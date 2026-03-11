import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/services/share_patient_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final SharePatientService _shareService = SharePatientService();

  Future<void> _handleAccept(String requestId, Map<String, dynamic> patientData, String patientType) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await _shareService.acceptRequest(requestId, patientData, patientType);

      if (mounted) {
        Navigator.pop(context); // Tutup loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data pasien berhasil ditambahkan ke daftar Anda!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tutup loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleReject(String requestId) async {
    try {
      await _shareService.rejectRequest(requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permintaan ditolak.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menolak: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Kotak Masuk', subtitle: ''),
      body: StreamBuilder<QuerySnapshot>(
        stream: _shareService.getPendingRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Tidak ada data pasien yang dibagikan ke Anda.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final senderName = data['senderName'] ?? 'Seseorang';
              final patientName = data['patientName'] ?? 'Pasien Tanpa Nama';
              final patientType = data['patientType'] ?? 'dewasa';
              final patientData = data['patientData'] as Map<String, dynamic>?;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            child: const Icon(Icons.person_add_alt_1, color: Colors.blue),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$senderName membagikan data pasien',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  patientType.toUpperCase(),
                                  style: TextStyle(fontSize: 12, color: patientType == 'anak' ? Colors.orange : Colors.green),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text('Nama Pasien: $patientName', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _handleReject(doc.id),
                            child: const Text('Tolak', style: TextStyle(color: Colors.red)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: patientData == null
                                ? null
                                : () => _handleAccept(doc.id, patientData, patientType),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Terima & Simpan'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}