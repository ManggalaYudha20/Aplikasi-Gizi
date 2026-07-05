import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';

class WhitelistPage extends StatefulWidget {
  const WhitelistPage({super.key});

  @override
  State<WhitelistPage> createState() => _WhitelistPageState();
}

class _WhitelistPageState extends State<WhitelistPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Dialog ini menangani Tambah Data (jika docId null) dan Edit Data (jika docId ada)
  void _showWhitelistDialog({
    String? docId,
    String? currentNip,
    String? currentEmail,
  }) {
    final nipController = TextEditingController(text: currentNip ?? '');
    final emailController = TextEditingController(text: currentEmail ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  docId == null ? Icons.person_add_alt_1 : Icons.edit,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Text(docId == null ? 'Daftar Nutrisionis' : 'Edit Nutrisionis'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Masukkan NIP dan/atau Email untuk akses otomatis role Nutrisionis.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nipController,
                    keyboardType: TextInputType.number,
                    maxLength: 20,
                    decoration: InputDecoration(
                      labelText: 'NIP',
                      prefixIcon: const Icon(Icons.badge),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    maxLength: 254,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      counterText: '',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        final nip = nipController.text.trim();
                        final email = emailController.text.trim();

                        if (nip.isEmpty && email.isEmpty) {
                          _showSnackBar(
                            'Masukkan minimal NIP atau Email!',
                            isError: true,
                          );
                          return;
                        }

                        setState(() => isSaving = true);

                        try {
                          // CEK DUPLIKASI DATA (kecuali dokumen yang sedang diedit)
                          if (email.isNotEmpty) {
                            final existingByEmail = await _firestore
                                .collection('verified_nutritionists')
                                .where('email', isEqualTo: email)
                                .get();
                            if (existingByEmail.docs.any(
                              (doc) => doc.id != docId,
                            )) {
                              _showSnackBar(
                                'Email tersebut sudah terdaftar!',
                                isError: true,
                              );
                              setState(() => isSaving = false);
                              return;
                            }
                          }

                          if (nip.isNotEmpty) {
                            final existingByNip = await _firestore
                                .collection('verified_nutritionists')
                                .where('NIP', isEqualTo: nip)
                                .get();
                            if (existingByNip.docs.any(
                              (doc) => doc.id != docId,
                            )) {
                              _showSnackBar(
                                'NIP tersebut sudah terdaftar!',
                                isError: true,
                              );
                              setState(() => isSaving = false);
                              return;
                            }
                          }

                          // SIMPAN ATAU UPDATE DATA
                          final Map<String, dynamic> data = {
                            'NIP': nip.isNotEmpty ? nip : null,
                            'email': email.isNotEmpty ? email : null,
                          };

                          if (docId == null) {
                            // Tambah Baru
                            data['createdAt'] = FieldValue.serverTimestamp();
                            await _firestore
                                .collection('verified_nutritionists')
                                .add(data);
                          } else {
                            // Update Data
                            await _firestore
                                .collection('verified_nutritionists')
                                .doc(docId)
                                .update(data);
                          }

                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);

                          if (!mounted) return;
                          _showSnackBar(
                            docId == null
                                ? 'Data Nutrisionis berhasil ditambahkan'
                                : 'Data Nutrisionis berhasil diperbarui',
                          );
                        } catch (e) {
                          _showSnackBar('Gagal menyimpan: $e', isError: true);
                          setState(() => isSaving = false);
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteWhitelist(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Data'),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus data ini dari daftar whitelist?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore
            .collection('verified_nutritionists')
            .doc(docId)
            .delete();
        _showSnackBar('Data berhasil dihapus');
      } catch (e) {
        _showSnackBar('Gagal menghapus data: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(
        title: 'Daftar Whitelist',
        subtitle: 'Kelola data verifikasi Nutrisionis',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWhitelistDialog(),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Mengurutkan berdasarkan data yang paling baru ditambahkan
        stream: _firestore
            .collection('verified_nutritionists')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada data di dalam whitelist.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              final email = data['email'] as String?;
              final nip = data['NIP'] as String?;

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9), // Light green
                    child: Icon(Icons.verified, color: Colors.green),
                  ),
                  title: Text(
                    email ?? 'Email tidak diatur',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('NIP: ${nip ?? '-'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showWhitelistDialog(
                          docId: docId,
                          currentEmail: email,
                          currentNip: nip,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteWhitelist(docId),
                      ),
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
