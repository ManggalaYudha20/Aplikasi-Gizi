import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- Tambahkan ini

// Import model Anda sesuaikan path-nya
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/models/patient_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/models/patient_anak_model.dart';

import 'package:csv/csv.dart';

class BackupRestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. FUNGSI EXPORT (BACKUP)
  Future<void> exportDataToJSON({
    required List<Patient> selectedDewasa,
    required List<PatientAnak> selectedAnak,
  }) async {
    try {
      // Ubah data ke Map, dan pastikan DateTime diubah ke String ISO 8601
      List<Map<String, dynamic>> dewasaList = selectedDewasa.map((p) {
        var map = p.toMap();
        map['tanggalLahir'] = p.tanggalLahir.toIso8601String();
        map['tanggalPemeriksaan'] = p.tanggalPemeriksaan.toIso8601String();
        return map;
      }).toList();

      List<Map<String, dynamic>> anakList = selectedAnak.map((p) {
        var map = p.toMap();
        map['tanggalLahir'] = p.tanggalLahir.toIso8601String();
        map['tanggalPemeriksaan'] = p.tanggalPemeriksaan.toIso8601String();
        return map;
      }).toList();

      // Gabungkan ke dalam satu JSON structure
      Map<String, dynamic> backupData = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'patients_dewasa': dewasaList,
        'patients_anak': anakList,
      };

      String jsonString = jsonEncode(backupData);

      // Simpan ke temporary directory
      final directory = await getTemporaryDirectory();

      // 1. Ambil data user yang sedang login
      final user = FirebaseAuth.instance.currentUser;

      // 2. Ambil displayName. Jika null, gunakan fallback 'Nutrisionis'
      String displayName = user?.displayName ?? 'Nutrisionis';

      // 3. Bersihkan nama dari karakter spasi menjadi underscore agar aman untuk nama file (Misal: "Budi Santoso" -> "Budi_Santoso")
      String safeDisplayName = displayName.replaceAll(' ', '_');

      // 4. Implementasikan ke dalam path file
      final file = File(
        '${directory.path}/Backup_Pasien_Gizi_$safeDisplayName.json',
      );

      await file.writeAsString(jsonString);

      // Bagikan file (bisa di-save ke Google Drive, WhatsApp, atau folder lokal)
      final params = ShareParams(
        text: 'Backup Data Pasien Gizi',
        files: [XFile(file.path)],
      );

      await SharePlus.instance.share(params);
    } catch (e) {
      throw Exception('Gagal melakukan backup: $e');
    }
  }

  Future<void> exportDataToCSV({
    required List<Patient> selectedDewasa,
    required List<PatientAnak> selectedAnak,
  }) async {
    try {
      List<List<dynamic>> rows = [];

      // Helper untuk merapikan format Map Hasil Lab menjadi String
      String formatLab(Map<String, dynamic>? labData) {
        if (labData == null || labData.isEmpty) return '-';
        return labData.entries.map((e) => '${e.key}: ${e.value}').join('; ');
      }

      // Helper untuk format tanggal (hanya ambil YYYY-MM-DD)
      String formatDate(DateTime? date) {
        if (date == null) return '-';
        return date.toIso8601String().split('T')[0];
      }

      // --- HEADER & DATA PASIEN DEWASA ---
     rows.add(['--- DATA PASIEN DEWASA ---']);
      rows.add([
        'No RM', 'Nama Lengkap', 'Tanggal Lahir', 'Jenis Kelamin', 'Diagnosis Medis',
        'Berat Badan (kg)', 'Tinggi Badan (cm)', 'LILA (cm)', 'Tinggi Lutut (cm)', 'BB 3-6 Bln Lalu (kg)',
        'Kehilangan Nafsu Makan', 'Tingkat Aktivitas', 'Faktor Stress', 'Nama Nutrisionis',
        'Alergi Makanan', 'Detail Alergi', 'Pola Makan', 'Suka Manis', 'Suka Asin', 'Makan Berlemak', 'Jarang Olahraga',
        'IMT', 'Skor IMT', 'Skor Kehilangan BB', 'Skor Efek Penyakit', 'Total Skor', 'Status Gizi',
        'Hasil Lab (Biokimia)', 'Klinik TD', 'Klinik Nadi', 'Klinik Suhu', 'Klinik RR', 'Klinik SpO2', 'Klinik KU', 'Klinik KES',
        'Riwayat Penyakit Sekarang', 'Riwayat Penyakit Dahulu', 'Diagnosa Gizi',
        'Intervensi Diet', 'Intervensi Bentuk Makanan', 'Intervensi Via', 'Intervensi Tujuan',
        'Monev Indikator', 'Monev Asupan', 'Monev Hasil Lab', 'Tanggal Pemeriksaan'
      ]);

      for (var p in selectedDewasa) {
        rows.add([
          p.noRM, p.namaLengkap, formatDate(p.tanggalLahir), p.jenisKelamin, p.diagnosisMedis,
          p.beratBadan, p.tinggiBadan, p.lila ?? '-', p.tl ?? '-', p.beratBadanDulu ?? '-',
          p.kehilanganNafsuMakan ?? '-', p.aktivitas, p.faktorStress, p.namaNutrisionis ?? '-',
          p.alergiMakanan ?? '-', p.detailAlergi ?? '-', p.polaMakan ?? '-', 
          p.sukaManis == true ? 'Ya' : 'Tidak', p.sukaAsin == true ? 'Ya' : 'Tidak', 
          p.makanBerlemak == true ? 'Ya' : 'Tidak', p.jarangOlahraga == true ? 'Ya' : 'Tidak',
          p.imt.toStringAsFixed(2), p.skorIMT, p.skorKehilanganBB, p.skorEfekPenyakit, p.totalSkor, p.monevStatusGizi ?? '-',
          formatLab(p.labResults), p.klinikTD ?? '-', p.klinikNadi ?? '-', p.klinikSuhu ?? '-', p.klinikRR ?? '-', 
          p.klinikSPO2 ?? '-', p.klinikKU ?? '-', p.klinikKES ?? '-',
          p.riwayatPenyakitSekarang ?? '-', p.riwayatPenyakitDahulu ?? '-', p.diagnosaGizi ?? '-',
          p.intervensiDiet ?? '-', p.intervensiBentukMakanan ?? '-', p.intervensiVia ?? '-', p.intervensiTujuan ?? '-',
          p.monevIndikator ?? '-', p.monevAsupan ?? '-', p.monevHasilLab ?? '-', formatDate(p.tanggalPemeriksaan)
        ]);
      }

      rows.add([]); // Baris kosong sebagai pemisah
      rows.add([]);

      // ==========================================
      // --- HEADER & DATA PASIEN ANAK ---
      // ==========================================
      rows.add(['--- DATA PASIEN ANAK ---']);
      rows.add([
        'No RM', 'Nama Lengkap', 'Tanggal Lahir', 'Jenis Kelamin', 'Diagnosis Medis',
        'Berat Badan (kg)', 'Tinggi Badan (cm)', 'LILA (cm)', 'Lingkar Kepala (cm)', 'BBI (kg)',
        'Skor Kehilangan BB', 'Skor Kehilangan Nafsu Makan', 'Skor Anak Sakit Berat', 'Nama Nutrisionis',
        'Alergi Makanan', 'Pola Makan',
        'Z-Score BB/U', 'Status BB/U', 'Z-Score TB/U', 'Status TB/U', 
        'Z-Score BB/TB', 'Status BB/TB', 'Z-Score IMT/U', 'Status IMT/U',
        'Hasil Lab (Biokimia)', 'Klinik TD', 'Klinik Nadi', 'Klinik Suhu', 'Klinik RR', 'Klinik SpO2', 'Klinik KU', 'Klinik KES',
        'Riwayat Penyakit Sekarang', 'Riwayat Penyakit Dahulu', 'Diagnosa Gizi',
        'Intervensi Diet', 'Intervensi Bentuk Makanan', 'Intervensi Via', 'Intervensi Tujuan',
        'Monev Indikator', 'Monev Asupan', 'Monev Hasil Lab', 'Tanggal Pemeriksaan'
      ]); 

      for (var p in selectedAnak) {
        rows.add([
          p.noRM, p.namaLengkap, formatDate(p.tanggalLahir), p.jenisKelamin, p.diagnosisMedis,
          p.beratBadan, p.tinggiBadan, p.lila ?? '-', p.lingkarKepala ?? '-', p.bbi ?? '-',
          p.kehilanganBeratBadan ?? '-', p.kehilanganNafsuMakan ?? '-', p.anakSakitBerat ?? '-', p.namaNutrisionis ?? '-',
          p.alergiMakanan ?? '-', p.polaMakan ?? '-',
          p.zScoreBBU ?? '-', p.statusGiziBBU ?? '-', p.zScoreTBU ?? '-', p.statusGiziTBU ?? '-',
          p.zScoreBBTB ?? '-', p.statusGiziBBTB ?? '-', p.zScoreIMTU ?? '-', p.statusGiziIMTU ?? '-',
          formatLab(p.labResults), p.klinikTD ?? '-', p.klinikNadi ?? '-', p.klinikSuhu ?? '-', p.klinikRR ?? '-', 
          p.klinikSPO2 ?? '-', p.klinikKU ?? '-', p.klinikKES ?? '-',
          p.riwayatPenyakitSekarang ?? '-', p.riwayatPenyakitDahulu ?? '-', p.diagnosaGizi ?? '-',
          p.intervensiDiet ?? '-', p.intervensiBentukMakanan ?? '-', p.intervensiVia ?? '-', p.intervensiTujuan ?? '-',
          p.monevIndikator ?? '-', p.monevAsupan ?? '-', p.monevHasilLab ?? '-', formatDate(p.tanggalPemeriksaan)
        ]);
      }

      // Konversi List of List menjadi format string CSV
      String csvData = const ListToCsvConverter().convert(rows);

      // Simpan ke temporary directory
      final directory = await getTemporaryDirectory();
      final user = FirebaseAuth.instance.currentUser;
      String displayName = user?.displayName ?? 'Nutrisionis';
      String safeDisplayName = displayName.replaceAll(' ', '_');

      // Perhatikan ekstensinya sekarang adalah .csv
      final file = File(
        '${directory.path}/Backup_Pasien_Gizi_$safeDisplayName.csv',
      );

      await file.writeAsString(csvData);

      // Bagikan file
      final params = ShareParams(
        text: 'Backup Data Pasien Gizi (Format Excel/CSV)',
        files: [XFile(file.path)],
      );

      await SharePlus.instance.share(params);
    } catch (e) {
      throw Exception('Gagal melakukan backup ke CSV: $e');
    }
  }

  // 2. FUNGSI IMPORT (UPLOAD)
  Future<void> importDataFromJSON(String currentUserId) async {
    try {
      // Pilih file menggunakan file_picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String jsonString = await file.readAsString();
        Map<String, dynamic> backupData = jsonDecode(jsonString);

        // Batch write agar upload efisien
        WriteBatch batch = _firestore.batch();

        // Proses Pasien Dewasa
        if (backupData['patients_dewasa'] != null) {
          List<dynamic> dewasaData = backupData['patients_dewasa'];
          for (var item in dewasaData) {
            Map<String, dynamic> data = Map<String, dynamic>.from(item);

            // Kembalikan String tanggal menjadi Timestamp untuk Firestore
            data['tanggalLahir'] = Timestamp.fromDate(
              DateTime.parse(data['tanggalLahir']),
            );
            data['tanggalPemeriksaan'] = Timestamp.fromDate(
              DateTime.parse(data['tanggalPemeriksaan']),
            );

            // GANTI createdBy menjadi User yang sedang login (Penting!)
            data['createdBy'] = currentUserId;

            DocumentReference docRef = _firestore
                .collection('patients')
                .doc(); // Auto ID baru
            batch.set(docRef, data);
          }
        }

        // Proses Pasien Anak
        if (backupData['patients_anak'] != null) {
          List<dynamic> anakData = backupData['patients_anak'];
          for (var item in anakData) {
            Map<String, dynamic> data = Map<String, dynamic>.from(item);

            data['tanggalLahir'] = Timestamp.fromDate(
              DateTime.parse(data['tanggalLahir']),
            );
            data['tanggalPemeriksaan'] = Timestamp.fromDate(
              DateTime.parse(data['tanggalPemeriksaan']),
            );
            data['createdBy'] = currentUserId;

            DocumentReference docRef = _firestore
                .collection('patients')
                .doc(); // Auto ID baru
            batch.set(docRef, data);
          }
        }

        // Eksekusi semua upload ke Firestore
        await batch.commit();
      }
    } catch (e) {
      throw Exception('Gagal mengupload data: $e');
    }
  }
}
