import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart'; // Import ini diperlukan untuk WidgetsFlutterBinding
import 'package:aplikasi_diagnosa_gizi/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final CollectionReference foodCollection =
      FirebaseFirestore.instance.collection('food_items');

  debugPrint('Memulai proses pembaruan data porsi_gram...');

  // Mengambil semua dokumen dari koleksi
  final QuerySnapshot snapshot = await foodCollection.get();

  // Membuat batch write
  WriteBatch batch = FirebaseFirestore.instance.batch();
  int updateCount = 0;

  for (var doc in snapshot.docs) {
    // Memperbarui field 'porsi_gram' menjadi 100
    batch.update(doc.reference, {'porsi_gram': 100});
    updateCount++;

    // Commit batch setiap 500 operasi (batas maksimum per batch)
    if (updateCount % 500 == 0) {
      await batch.commit();
      batch = FirebaseFirestore.instance.batch();
      debugPrint('Batch $updateCount dokumen telah di-commit...');
    }
  }

  // Commit sisa operasi yang belum di-commit
  if (updateCount % 500 != 0) {
    await batch.commit();
  }

  debugPrint('Pembaruan selesai. Total $updateCount dokumen telah diperbarui.');
}