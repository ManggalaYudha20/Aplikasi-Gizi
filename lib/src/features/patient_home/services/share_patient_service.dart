import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SharePatientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Ambil daftar Nutrisionis & Admin (Kecuali diri sendiri)
  Future<List<Map<String, dynamic>>> getAvailableNutritionists() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', whereIn: ['ahli_gizi', 'admin','nutrisionis'])
          .get();

      return snapshot.docs
          .where((doc) => doc.id != currentUser.uid) // Filter diri sendiri
          .map((doc) => {
                'uid': doc.id,
                'name': doc.data()['displayName'] ?? 'Tanpa Nama',
                'email': doc.data()['email'] ?? '',
              })
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data nutrisionis: $e');
    }
  }

  // 2. Kirim data pasien ke Inbox penerima
  Future<void> sendPatientData({
    required List<String> receiverIds,
    required Map<String, dynamic> patientData,
    required String patientName,
    required String patientType, // 'dewasa' atau 'anak'
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("Sesi telah berakhir, silakan login ulang.");

    final senderName = currentUser.displayName ?? 'Rekan Nutrisionis';

    // Gunakan batch agar pengiriman multi-user dieksekusi bersamaan
    WriteBatch batch = _firestore.batch();

    for (String receiverId in receiverIds) {
      DocumentReference docRef = _firestore.collection('share_requests').doc();
      
      batch.set(docRef, {
        'senderId': currentUser.uid,
        'senderName': senderName,
        'receiverId': receiverId,
        'patientName': patientName,
        'patientType': patientType,
        'patientData': patientData, // Seluruh isi data pasien
        'status': 'pending', // Status awal
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // 3. Mengambil daftar request yang masuk (Real-time Stream)
  Stream<QuerySnapshot> getPendingRequests() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream.empty();

    return _firestore
        .collection('share_requests')
        .where('receiverId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // 4. Menerima Data (Menyalin ke koleksi pasien penerima)
  Future<void> acceptRequest(String requestId, Map<String, dynamic> patientData, String patientType) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("Sesi berakhir");

    // Buat salinan Map agar data asli tidak terganggu
    Map<String, dynamic> newData = Map<String, dynamic>.from(patientData);

    // 1. Bersihkan ID lama
    newData.remove('id');

    // 2. GANTI createdBy menjadi UID Nutrisionis yang MENERIMA (B)
    newData['createdBy'] = currentUser.uid; 

    // 3. Pastikan tipePasien tersimpan sesuai data aslinya ('dewasa' atau 'anak')
    newData['tipePasien'] = patientType;

    // 4. Konversi format tanggal kembali ke Timestamp Firestore
    if (newData['tanggalLahir'] is String) {
      newData['tanggalLahir'] = Timestamp.fromDate(DateTime.parse(newData['tanggalLahir']));
    }
    newData['tanggalPemeriksaan'] = FieldValue.serverTimestamp(); 

    WriteBatch batch = _firestore.batch();

   // 1. Simpan data ke koleksi pasien tujuan
    DocumentReference newPatientRef = _firestore.collection('patients').doc();
    batch.set(newPatientRef, newData);

    // 2. HAPUS dokumen dari share_requests daripada hanya update status
    // Dengan dihapus, data tidak akan menumpuk di Firebase
    DocumentReference requestRef = _firestore.collection('share_requests').doc(requestId);
    batch.delete(requestRef);

    await batch.commit();
  }

  // 5. Menolak Data
  Future<void> rejectRequest(String requestId) async {
    await _firestore.collection('share_requests').doc(requestId).delete();
  }
}