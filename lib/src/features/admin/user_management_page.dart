import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Referensi ke koleksi users
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fungsi untuk update Role
 Future<void> _updateUserRole(String userId, String currentRole) async {
    // 1. Pilih Role Baru
    String? newRole = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Pilih Role Baru'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () { Navigator.pop(context, 'admin'); },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Admin'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () { Navigator.pop(context, 'ahli_gizi'); },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Ahli Gizi'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () { Navigator.pop(context, 'tamu'); },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Tamu'),
              ),
            ),
          ],
        );
      },
    );

    // Jika tidak ada role yang dipilih atau role sama dengan yang lama, berhenti di sini
    if (newRole == null || newRole == currentRole) return;

    // 2. Tampilkan Dialog Konfirmasi (LOGIC BARU)
    if (!mounted) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Perubahan Role'),
        content: Text('Apakah Anda yakin ingin mengubah hak akses pengguna ini menjadi "$newRole"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Batal
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Konfirmasi
            child: const Text('Ya, Simpan'),
          ),
        ],
      ),
    );

    // 3. Eksekusi Update ke Firestore hanya jika dikonfirmasi
    if (confirm == true) {
      try {
        await _usersCollection.doc(userId).update({'role': newRole});
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Role berhasil diubah menjadi $newRole'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengubah role: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Fungsi konfirmasi hapus (Hanya data Firestore)
  Future<void> _deleteUser(String userId) async {
    // 1. Dialog Konfirmasi dengan Peringatan Keras
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pengguna & Data?'),
        content: const Text(
          'PERINGATAN: Tindakan ini akan menghapus:\n\n'
          '1. Profil pengguna ini.\n'
          '2. SEMUA DATA PASIEN yang pernah dibuat oleh pengguna ini.\n\n'
          'Data yang sudah dihapus tidak dapat dikembalikan. Apakah Anda yakin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Ya, Hapus Semuanya', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        // Referensi ke koleksi patients
        final CollectionReference patientsCollection = FirebaseFirestore.instance.collection('patients');

        // 2. Query cari semua pasien yang dibuat oleh user ini
        final QuerySnapshot patientSnapshot = await patientsCollection
            .where('createdBy', isEqualTo: userId)
            .get();

        // 3. Gunakan Batch Write agar proses hapus efisien dan atomik (sekaligus)
        WriteBatch batch = FirebaseFirestore.instance.batch();

        // A. Masukkan perintah hapus untuk setiap dokumen pasien
        for (DocumentSnapshot doc in patientSnapshot.docs) {
          batch.delete(doc.reference);
        }

        // B. Masukkan perintah hapus untuk dokumen user
        batch.delete(_usersCollection.doc(userId));

        // 4. Eksekusi Batch (Commit)
        await batch.commit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pengguna dan seluruh data pasiennya berhasil dihapus.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint("Error deleting user: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil ID user yang sedang login saat ini
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Manajemen Pengguna',
        subtitle: 'Kelola hak akses dan data',
      ),
      body: Column(
        children: [
         _buildSearchBar(),
          // 2. User List (DIPERBARUI)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _usersCollection.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Terjadi kesalahan'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs;
                
                final filteredUsers = users.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['displayName'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) || email.contains(_searchQuery);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text('Tidak ada pengguna ditemukan.'));
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final doc = filteredUsers[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    final String userId = doc.id; // ID User di dalam list
                    final String role = data['role'] ?? 'user';
                    final String name = data['displayName'] ?? 'Tanpa Nama';
                    final String email = data['email'] ?? '-';
                    final String? photoUrl = data['photoURL'];

                    // LOGIKA UTAMA: Cek apakah user ini adalah diri sendiri
                    final bool isSelf = currentUserId == userId;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                          child: photoUrl == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(
                          name + (isSelf ? ' (Anda)' : ''), // Menandai akun sendiri
                          style: const TextStyle(fontWeight: FontWeight.bold)
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 11, // Ubah angka ini untuk ukuran Email
                                color: Colors.grey[700], // Opsional: Warna teks email
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Badge Role
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: role == 'admin' ? Colors.red.shade100 : 
                                       role == 'ahli_gizi' ? Colors.teal.shade100 : Colors.lightGreen.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                role.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10, 
                                  fontWeight: FontWeight.bold,
                                  color: role == 'admin' ? Colors.red : 
                                         role == 'ahli_gizi' ? Colors.teal : Colors.lightGreen[700]
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tombol Edit Role
                            IconButton(
                              // Jika akun sendiri (isSelf), warna jadi abu-abu
                              icon: Icon(Icons.edit, color: isSelf ? Colors.grey : Colors.blue),
                              // Jika akun sendiri, onPressed jadi null (tombol mati)
                              onPressed: isSelf 
                                ? null 
                                : () => _updateUserRole(userId, role),
                            ),
                            // Tombol Hapus
                            IconButton(
                              // Jika akun sendiri (isSelf), warna jadi abu-abu
                              icon: Icon(Icons.delete, color: isSelf ? Colors.grey : Colors.red),
                              // Jika akun sendiri, onPressed jadi null (tombol mati)
                              onPressed: isSelf 
                                ? null 
                                : () => _deleteUser(userId),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET SEARCH BAR BARU (Meniru style Patient Home) ---
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16.0), // Memberi jarak dari tepi layar
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            // Menggunakan withValues sesuai update Flutter terbaru (atau withOpacity untuk versi lama)
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
          hintText: 'Cari Nama atau Email...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = "";
                    });
                  },
                )
              : null,
          border: InputBorder.none, // Menghilangkan garis border bawaan
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: const TextStyle(fontSize: 16),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }
}