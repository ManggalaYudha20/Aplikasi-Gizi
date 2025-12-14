// lib/src/features/home/presentation/pages/data_form_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/models/patient_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/scaffold_with_animated_fab.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_validator_utils.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:aplikasi_diagnosa_gizi/src/login/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/expert_system_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/data/nutrition_reference_data.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/data/diagnosis_terminology.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/data/intervensi_data.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/data/monitoring_data.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/searchable_terminology_field.dart';

class LabInputItem {
  TextEditingController valueController;
  String? selectedType;

  LabInputItem({required this.valueController, this.selectedType});
}

class DiagnosisInput {
  TextEditingController pController; // Problem
  TextEditingController eController; // Etiology
  TextEditingController sController; // Signs/Symptoms

  DiagnosisInput({String? p, String? e, String? s})
    : pController = TextEditingController(text: p),
      eController = TextEditingController(text: e),
      sController = TextEditingController(text: s);

  void dispose() {
    pController.dispose();
    eController.dispose();
    sController.dispose();
  }
}

class DataFormPage extends StatefulWidget {
  final Patient? patient; // Optional patient for editing

  const DataFormPage({super.key, this.patient});

  @override
  State<DataFormPage> createState() => _DataFormPageState();
}

class _DataFormPageState extends State<DataFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  // Controllers for form fields
  final _noRMController = TextEditingController();
  final _namaLengkapController = TextEditingController();
  final _tanggalLahirController = TextEditingController();
  final _diagnosisMedisController = TextEditingController();
  final _beratBadanController = TextEditingController();
  final _tinggiBadanController = TextEditingController();
  // BARU: Controller untuk berat badan 3-6 bulan lalu
  final _beratBadanDuluController = TextEditingController();
  final _lilaController = TextEditingController();
  final _tlController = TextEditingController();
  final List<FocusNode> _focusNodes = [];
  final _jenisKelaminController = TextEditingController();
  final _aktivitasController = TextEditingController();
  final _kehilanganNafsuMakanController = TextEditingController();
  final _alergiMakananController = TextEditingController(text: 'Tidak');
  // BARU: State untuk menyimpan pilihan kehilangan nafsu makan
  DateTime? _selectedDate;
  // BARU: Controllers untuk Asuhan Gizi
  final _detailAlergiController = TextEditingController();
  final _polaMakanController = TextEditingController();
  final _polaMakanFreqController =
      TextEditingController(); // Helper UI: Frekuensi
  final _polaMakanPercentController = TextEditingController();
  final List<LabInputItem> _labItems = [];
  final List<String> _labOptions = [
    'GDS',
    'GDP',
    'HbA1c',
    'Ureum',
    'HGB',
    'ENT',
    'Kolesterol Total',
    'HDL',
    'LDL',
    'Trigliserida',
    'Asam Urat',
    'Kreatinin',
    'SGOT',
    'SGPT',
    'Natrium',
    'Kalium',
    'Leukosit',
    'Trombosit',
  ];
  final _klinikTDController = TextEditingController();
  final _klinikKUController = TextEditingController();
  final _klinikKESController = TextEditingController();
  final _klinikNadiController = TextEditingController();
  final _klinikSuhuController = TextEditingController();
  final _klinikRRController = TextEditingController();
  final _klinikSPO2Controller = TextEditingController();
  final _riwayatPenyakitSekarangController = TextEditingController();
  final _riwayatPenyakitDahuluController = TextEditingController();
  final List<DiagnosisInput> _diagnosisItems = [];
  final _intervensiDietController = TextEditingController();
  final _intervensiBentukMakananController = TextEditingController();
  final _intervensiViaController = TextEditingController();
  final _intervensiTujuanController = TextEditingController();
  final _monevAsupanController = TextEditingController();
  final _monevHasilLabController = TextEditingController();
  final _namaNutrisionisController = TextEditingController();
  final AuthService _authService = AuthService();
  final _monevIndikatorController = TextEditingController();

  bool _sukaManis = false;
  bool _sukaAsin = false;
  bool _makanBerlemak = false;
  bool _jarangOlahraga = false;

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < 50; i++) {
      _focusNodes.add(FocusNode());
    }

    if (widget.patient != null) {
      _initializeFormWithPatientData();
    } else {
      // Jika pasien baru, tambahkan 1 field lab kosong default
      _addLabItem(null, '');
      _addDiagnosisItem();
    }
  }

  void _addLabItem(String? type, String value) {
    if (_labItems.length >= 6) return; // Batasan Max 6
    setState(() {
      _labItems.add(
        LabInputItem(
          valueController: TextEditingController(text: value),
          selectedType: type,
        ),
      );
    });
  }

  // Fungsi untuk menambah form diagnosa baru
  void _addDiagnosisItem({String? p, String? e, String? s}) {
    // BATASAN: Cek jika jumlah sudah 3, hentikan proses
    if (_diagnosisItems.length >= 3) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Maksimal 3 Diagnosa Gizi')));
      return;
    }

    setState(() {
      _diagnosisItems.add(DiagnosisInput(p: p, e: e, s: s));
    });
  }

  // Fungsi untuk menghapus diagnosa
  void _removeDiagnosisItem(int index) {
    setState(() {
      _diagnosisItems[index].dispose();
      _diagnosisItems.removeAt(index);
    });
  }

  void _generateExpertDiagnosis() {
    bool isBasicDataEmpty =
        _beratBadanController.text.isEmpty ||
        _tinggiBadanController.text.isEmpty;
    bool isLabEmpty = _labItems.every(
      (item) => item.valueController.text.isEmpty,
    );
    bool isClinicEmpty = _klinikTDController.text.isEmpty;

    if (isBasicDataEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal: Harap lengkapi Berat Badan dan Tinggi Badan.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (isLabEmpty && isClinicEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Peringatan: Data Lab & Klinis kosong. Hasil diagnosa mungkin kurang spesifik.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }

    // 1. Ambil data fisik
    double? beratBadan = double.tryParse(_beratBadanController.text);
    double? tinggiBadan = double.tryParse(_tinggiBadanController.text);
    double imt = 0;
    if (beratBadan != null && tinggiBadan != null && tinggiBadan > 0) {
      final tbMeter = tinggiBadan / 100;
      imt = beratBadan / (tbMeter * tbMeter);
    }

    // 2. Ambil Data Lab
    double? gds, gdp, hba1c, ureum, kreatinin, kalium, kolesterol;
    for (var item in _labItems) {
      if (item.selectedType != null && item.valueController.text.isNotEmpty) {
        String cleanVal = item.valueController.text.replaceAll(',', '.');
        double? val = double.tryParse(cleanVal);
        if (val != null) {
          String type = item.selectedType!;
          if (type == 'GDS') gds = val;
          if (type == 'GDP') gdp = val;
          if (type == 'HbA1c') hba1c = val;
          if (type == 'Ureum') ureum = val;
          if (type == 'Kreatinin') kreatinin = val;
          if (type == 'Kalium') kalium = val;
          if (type == 'Kolesterol Total') kolesterol = val;
        }
      }
    }

    // 3. Riwayat Makan
    List<String> dietaryHistoryList = [];
    if (_sukaManis) dietaryHistoryList.add('Suka manis');
    if (_sukaAsin) dietaryHistoryList.add('Suka asin');
    if (_makanBerlemak) dietaryHistoryList.add('Suka berlemak');
    if (_jarangOlahraga) dietaryHistoryList.add('Jarang olahraga');

    // 4. Siapkan Input
    final input = ExpertSystemInput(
      imt: imt,
      gds: gds,
      gdp: gdp,
      hba1c: hba1c,
      ureum: ureum,
      kreatinin: kreatinin,
      kalium: kalium,
      cholesterol: kolesterol,
      bloodPressure: _klinikTDController.text,
      dietaryHistory: dietaryHistoryList,
      medicalDiagnosis: _diagnosisMedisController.text,
    );

    // 5. Panggil Service
    final service = DiseaseExpertService();
    final result = service.generateCarePlan(input);

    // 6. Update UI
    setState(() {
      _diagnosisItems.clear(); // Reset form lama

      // --- DIAGNOSA (PES) ---
      for (var diag in result.suggestedDiagnoses) {
        if (_diagnosisItems.length >= 3) break;
        String problem = "[${diag.code}] ${diag.label}";
        String etiology =
            diag.definition; // Menggunakan definisi dari Expert System
        String signs =
            ""; // Signs bisa ditambahkan logika manual jika perlu (seperti lab value)

        // Logika tambahan untuk Signs (Opsional, agar lebih detail)
        if (diag.code == 'NC-2.2') {
          // Kumpulkan semua data lab yang tidak null ke dalam list
          List<String> labFindings = [];
          if (gds != null) labFindings.add("GDS: ${gds.round()}");
          if (gdp != null) labFindings.add("GDP: ${gdp.round()}");
          if (hba1c != null) labFindings.add("HbA1c: $hba1c");
          if (ureum != null) labFindings.add("Ureum: ${ureum.round()}");
          if (kreatinin != null) labFindings.add("Kreatinin: $kreatinin");
          if (kolesterol != null) labFindings.add("Kolesterol: ${kolesterol.round()}");
          if (kalium != null) labFindings.add("Kalium: $kalium");

          if (labFindings.isNotEmpty) {
            signs = "Hasil Lab: ${labFindings.join(', ')}";
          } else {
             // Fallback jika lab kosong tapi diagnosa ini muncul (misal dari diagnosa medis)
            signs = "Perubahan nilai lab terkait"; 
          }
        } 
        // --- Logika Signs Lainnya ---
        else if (diag.code == 'NI-5.8.3') {
           signs = "Riwayat: Suka makanan manis";
        } else if (diag.code == 'NI-5.10.1') {
           if (kalium != null) signs = "Kalium: $kalium";
        } else if (diag.code == 'NI-5.10.2') {
           signs = "Riwayat suka asin, TD: ${_klinikTDController.text}";
        } else if (diag.code == 'NC-3.3' || diag.code == 'NC-3.1') {
           signs = "IMT: ${imt.toStringAsFixed(1)}";
        } else if (diag.code == 'NB-2.1') {
           signs = "Riwayat: Jarang berolahraga";
        }
        _addDiagnosisItem(p: problem, e: etiology, s: signs);
      }
      if (_diagnosisItems.isEmpty) _addDiagnosisItem();

      // --- INTERVENSI ---
      // Format harus: [KODE] Label
      // Agar terbaca otomatis oleh SearchableTerminologyField
      if (_intervensiDietController.text.isEmpty) {
        _intervensiDietController.text = result.suggestedInterventions
            .map((i) => '[${i.code}] ${i.label}')
            .join('; '); // Gunakan ; sebagai pemisah jika ada banyak
      }

      // --- MONITORING (UPDATED) ---
      // Masuk ke _monevIndikatorController (Bukan Asupan)
      if (_monevIndikatorController.text.isEmpty) {
        _monevIndikatorController.text = result.suggestedMonitoring
            .map((m) => '[${m.code}] ${m.label}')
            .join('; ');
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saran Diagnosa otomatis berhasil dimuat.')),
    );
  }

  void _initializeFormWithPatientData() {
    final patient = widget.patient!;
    _noRMController.text = patient.noRM;
    _namaLengkapController.text = patient.namaLengkap;
    _tanggalLahirController.text = patient.tanggalLahirFormatted;
    _diagnosisMedisController.text = patient.diagnosisMedis;
    _beratBadanController.text = patient.beratBadan.toString();
    _tinggiBadanController.text = patient.tinggiBadan.toString();
    _jenisKelaminController.text = patient.jenisKelamin;
    _aktivitasController.text = patient.aktivitas;
    _kehilanganNafsuMakanController.text = patient.kehilanganNafsuMakan ?? '';
    _alergiMakananController.text = patient.alergiMakanan ?? 'Tidak';
    _selectedDate = patient.tanggalLahir;
    // Perbaikan: LILA dan TL harus diambil dari model juga
    if (patient.lila != null) {
      _lilaController.text = patient.lila.toString();
    }
    if (patient.tl != null) {
      _tlController.text = patient.tl.toString();
    }
    // 2. Muat data berat badan dulu jika ada
    if (patient.beratBadanDulu != null) {
      _beratBadanDuluController.text = patient.beratBadanDulu.toString();
    }
    // Note: We don't have beratBadanDulu and kehilanganNafsuMakan in Patient model
    // These fields will remain empty for editing

    // BARU: Inisialisasi data asuhan gizi
    _detailAlergiController.text = patient.detailAlergi ?? '';
    _polaMakanController.text = patient.polaMakan ?? '';
    if (_polaMakanController.text.contains(' // ')) {
      final parts = _polaMakanController.text.split(' // ');
      _polaMakanFreqController.text = parts[0];
      // Ambil bagian persen dan hapus simbol % untuk ditampilkan di input angka
      if (parts.length > 1) {
        _polaMakanPercentController.text = parts[1].replaceAll('%', '');
      }
    } else {
      // Jika format lama (belum dipisah), masukkan semua ke frekuensi
      _polaMakanFreqController.text = _polaMakanController.text;
    }
    _labItems.clear();
    if (patient.labResults.isNotEmpty) {
      patient.labResults.forEach((key, value) {
        _addLabItem(key, value);
      });
    } else {
      _addLabItem(null, '');
    }
    _klinikTDController.text = patient.klinikTD ?? '';
    _klinikNadiController.text = patient.klinikNadi ?? '';
    _klinikSuhuController.text = patient.klinikSuhu ?? '';
    _klinikRRController.text = patient.klinikRR ?? '';
    _riwayatPenyakitSekarangController.text =
        patient.riwayatPenyakitSekarang ?? '';
    _riwayatPenyakitDahuluController.text = patient.riwayatPenyakitDahulu ?? '';

    _intervensiDietController.text = patient.intervensiDiet ?? '';
    _intervensiBentukMakananController.text =
        patient.intervensiBentukMakanan ?? '';
    _intervensiViaController.text = patient.intervensiVia ?? '';
    _intervensiTujuanController.text = patient.intervensiTujuan ?? '';
    _monevAsupanController.text = patient.monevAsupan ?? '';
    _monevHasilLabController.text = patient.monevHasilLab ?? '';
    _monevIndikatorController.text = patient.monevIndikator ?? '';
    _klinikKUController.text = patient.klinikKU ?? '';
    _klinikKESController.text = patient.klinikKES ?? '';
    _klinikSPO2Controller.text = patient.klinikSPO2 ?? '';
    _namaNutrisionisController.text = patient.namaNutrisionis ?? '';

    setState(() {
      _sukaManis = patient.sukaManis ?? false;
      _sukaAsin = patient.sukaAsin ?? false;
      _makanBerlemak = patient.makanBerlemak ?? false;
      _jarangOlahraga = patient.jarangOlahraga ?? false;

      _diagnosisItems.clear();
      // PERBAIKAN ERROR 314: Cek null sebelum cek isNotEmpty
      if (patient.diagnosaGizi != null && patient.diagnosaGizi!.isNotEmpty) {
        final rawText = patient.diagnosaGizi!;
        // Cek apakah formatnya mengandung penomoran (contoh: "1. Problem...")
        bool isFormatted = RegExp(r'^\d+\.').hasMatch(rawText);

        if (isFormatted) {
          final lines = rawText.split('\n');
          String? currentP;
          String? currentE;
          String? currentS;

          for (var line in lines) {
            line = line.trim(); // Hapus spasi depan/belakang
            if (line.isEmpty) continue;

            // Jika baris dimulai dengan angka (1. , 2. ), ini adalah Problem baru
            if (RegExp(r'^\d+\.').hasMatch(line)) {
              // Jika ada data sebelumnya yang belum disimpan, masukkan ke list
              if (currentP != null) {
                // Bypass limit check saat loading data
                _diagnosisItems.add(
                  DiagnosisInput(p: currentP, e: currentE, s: currentS),
                );
              }

              // Reset untuk item baru
              // Hapus nomor urut di depan (misal "1. Masalah" jadi "Masalah")
              currentP = line.replaceFirst(RegExp(r'^\d+\.\s*'), '');
              currentE = null;
              currentS = null;
            }
            // Cek Etiologi
            else if (line.startsWith('Berkaitan dengan:')) {
              currentE = line.replaceFirst('Berkaitan dengan:', '').trim();
            }
            // Cek Signs/Symptoms
            else if (line.startsWith('Ditandai dengan:')) {
              currentS = line.replaceFirst('Ditandai dengan:', '').trim();
            }
          }

          // Jangan lupa tambahkan item terakhir setelah loop selesai
          if (currentP != null) {
            _diagnosisItems.add(
              DiagnosisInput(p: currentP, e: currentE, s: currentS),
            );
          }
        } else {
          // Fallback: Jika format tidak dikenali (data lama/manual), masukkan semua ke P
          _diagnosisItems.add(DiagnosisInput(p: rawText));
        }
      }

      // Jika kosong atau gagal parse, buat 1 field kosong
      if (_diagnosisItems.isEmpty) {
        _diagnosisItems.add(DiagnosisInput());
      }
    });
  }

  @override
  void dispose() {
    _noRMController.dispose();
    _namaLengkapController.dispose();
    _tanggalLahirController.dispose();
    _diagnosisMedisController.dispose();
    _beratBadanController.dispose();
    _tinggiBadanController.dispose();
    // BARU: Dispose controller baru
    _beratBadanDuluController.dispose();
    _lilaController.dispose();
    _tlController.dispose();
    // BARU: Dispose controllers asuhan gizi
    _detailAlergiController.dispose();
    _polaMakanController.dispose();
    _polaMakanFreqController.dispose();
    _polaMakanPercentController.dispose();

    for (var item in _labItems) {
      item.valueController.dispose();
    }

    _klinikTDController.dispose();
    _klinikNadiController.dispose();
    _klinikSuhuController.dispose();
    _klinikRRController.dispose();
    _riwayatPenyakitSekarangController.dispose();
    _riwayatPenyakitDahuluController.dispose();

    for (var item in _diagnosisItems) {
      item.dispose();
    }
    _intervensiDietController.dispose();
    _intervensiBentukMakananController.dispose();
    _intervensiViaController.dispose();
    _intervensiTujuanController.dispose();
    _monevAsupanController.dispose();
    _monevHasilLabController.dispose();
    _klinikKUController.dispose();
    _klinikKESController.dispose();
    _klinikSPO2Controller.dispose();
    _namaNutrisionisController.dispose();
    _jenisKelaminController.dispose();
    _aktivitasController.dispose();
    _kehilanganNafsuMakanController.dispose();
    _alergiMakananController.dispose();
    _monevIndikatorController.dispose();

    // Dispose semua FocusNode
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Fungsi untuk mereset semua field
  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _noRMController.clear();
      _namaLengkapController.clear();
      _tanggalLahirController.clear();
      _diagnosisMedisController.clear();
      _beratBadanController.clear();
      _tinggiBadanController.clear();
      // BARU: Reset field baru
      _beratBadanDuluController.clear();
      _lilaController.clear();
      _tlController.clear();
      _kehilanganNafsuMakanController.clear();
      _jenisKelaminController.clear();
      _aktivitasController.clear();
      _alergiMakananController.text = 'Tidak';
      _selectedDate = null;
      _detailAlergiController.clear();
      _polaMakanController.clear();
      _polaMakanFreqController.clear();
      _polaMakanPercentController.clear();

      _sukaManis = false;
      _sukaAsin = false;
      _makanBerlemak = false;
      _jarangOlahraga = false;

      for (var item in _labItems) {
        item.valueController.dispose();
      }
      _labItems.clear();
      _addLabItem(null, '');

      _klinikTDController.clear();
      _klinikNadiController.clear();
      _klinikSuhuController.clear();
      _klinikRRController.clear();
      _riwayatPenyakitSekarangController.clear();
      _riwayatPenyakitDahuluController.clear();
      _diagnosisItems.clear();
      _addDiagnosisItem();
      _intervensiDietController.clear();
      _intervensiBentukMakananController.clear();
      _intervensiViaController.clear();
      _intervensiTujuanController.clear();
      _monevAsupanController.clear();
      _monevHasilLabController.clear();
      _klinikKUController.clear();
      _klinikKESController.clear();
      _klinikSPO2Controller.clear();
      _namaNutrisionisController.clear();
      _monevIndikatorController.clear();
    });
  }

  int _calculateAgeInYears(DateTime? birthDate) {
    if (birthDate == null) return 0;
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _savePatientData() async {
    if (FormValidatorUtils.validateAndScroll(
      context: context,
      formKey: _formKey,
      focusNodes: _focusNodes,
    )) {
      setState(() => _isLoading = true);

      final User? currentUser = _authService.getCurrentUser();
      if (currentUser == null) {
        // Jika karena suatu alasan pengguna tidak login, hentikan proses
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi Anda telah berakhir. Silakan login kembali.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      try {
        // --- Pengumpulan Data ---
        final noRM = _noRMController.text;
        final namaLengkap = _namaLengkapController.text;
        final diagnosisMedis = _diagnosisMedisController.text;
        // BARU: Ambil data berat badan dulu
        final beratBadanDulu = double.tryParse(_beratBadanDuluController.text);
        final usia = _calculateAgeInYears(_selectedDate);

        double? beratBadan;
        double? tinggiBadan;

        // BARU: Logika untuk menentukan BB dan TB
        if (_beratBadanController.text.isNotEmpty) {
          beratBadan = double.parse(_beratBadanController.text);
        } else if (_lilaController.text.isNotEmpty) {
          final lila = double.parse(_lilaController.text);
          // Menggunakan rumus yang disederhanakan sesuai permintaan
          beratBadan = (2.81 * lila) - 18.6;
        }

        if (_tinggiBadanController.text.isNotEmpty) {
          tinggiBadan = double.parse(_tinggiBadanController.text);
        } else if (_tlController.text.isNotEmpty &&
            _jenisKelaminController.text.isNotEmpty &&
            usia > 0) {
          // Gunakan rumus estimasi TB dari TL jika TB tidak ada
          final tl = double.parse(_tlController.text);
          if (_jenisKelaminController.text == 'Laki-laki') {
            tinggiBadan = (2.02 * tl) - (0.04 * usia) + 64.19;
          } else {
            tinggiBadan = (1.83 * tl) - (0.24 * usia) + 84.88;
          }
        }

        // Final check to ensure we have both values
        if (beratBadan == null || tinggiBadan == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tinggi dan Berat badan tidak boleh kosong.'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() => _isLoading = false);
          }
          return;
        }

        // --- Perhitungan ---
        final tinggiBadanMeter = tinggiBadan / 100;
        final imt = beratBadan / (tinggiBadanMeter * tinggiBadanMeter);

        // DIUBAH: Logika skor IMT
        final int skorIMT;
        if (imt < 18.5) {
          skorIMT = 2;
        } else if (imt >= 18.5 && imt < 25) {
          skorIMT = 1;
        } else {
          // imt >= 25
          skorIMT = 0;
        }

        // BARU: Logika untuk menentukan Status Gizi berdasarkan IMT
        String statusGizi;
        if (imt < 18.5) {
          statusGizi = 'Gizi Kurang (Underweight)';
        } else if (imt >= 18.5 && imt <= 24.9) {
          statusGizi = 'Gizi Baik (Normal)';
        } else if (imt >= 25 && imt <= 29.9) {
          statusGizi = 'Gizi Lebih (Overweight)';
        } else {
          // imt >= 30
          statusGizi = 'Obesitas';
        }

        // DIUBAH: Logika perhitungan skor kehilangan BB
        int skorKehilanganBB = 0; // Default skor 0
        if (beratBadanDulu != null && beratBadanDulu > 0) {
          final persentaseKehilangan =
              ((beratBadanDulu - beratBadan) / beratBadanDulu) * 100;
          if (persentaseKehilangan > 10) {
            skorKehilanganBB = 2;
          } else if (persentaseKehilangan >= 5) {
            skorKehilanganBB = 1;
          }
        }

        // DIUBAH: Logika skor efek penyakit dari input kehilangan nafsu makan
        final skorEfekPenyakit = (_kehilanganNafsuMakanController.text == 'Ya')
            ? 0
            : 2;

        final totalSkor = skorIMT + skorKehilanganBB + skorEfekPenyakit;

        // 1. Parsing Data Lab & Fisik
        Map<String, String> labResultsMap = {};
        for (var item in _labItems) {
          if (item.selectedType != null &&
              item.valueController.text.isNotEmpty) {
            labResultsMap[item.selectedType!] = item.valueController.text;
          }
        }

        StringBuffer diagnosaString = StringBuffer();
        for (int i = 0; i < _diagnosisItems.length; i++) {
          var item = _diagnosisItems[i];
          if (item.pController.text.isNotEmpty) {
            diagnosaString.writeln('${i + 1}. ${item.pController.text}');
            if (item.eController.text.isNotEmpty) {
              // [PERBAIKAN] Bersihkan teks dari spasi dan titik dua di awal
              String cleanE = item.eController.text.trim();
              if (cleanE.startsWith(':')) {
                cleanE = cleanE.substring(1).trim();
              }
              diagnosaString.writeln('   Berkaitan dengan: $cleanE');
            }
            if (item.sController.text.isNotEmpty) {
              diagnosaString.writeln(
                '   Ditandai dengan: ${item.sController.text}',
              );
            }
            diagnosaString.writeln();
          }
        }

        String polaMakanFinal = '';
        if (_polaMakanFreqController.text.isNotEmpty) {
          polaMakanFinal = _polaMakanFreqController.text;
          if (_polaMakanPercentController.text.isNotEmpty) {
            polaMakanFinal += ' // ${_polaMakanPercentController.text}%';
          }
        } else if (_polaMakanPercentController.text.isNotEmpty) {
          polaMakanFinal = ' // ${_polaMakanPercentController.text}%';
        }
        _polaMakanController.text = polaMakanFinal;

        // --- Siapkan data untuk Firestore ---
        final patientData = {
          'noRM': noRM,
          'namaLengkap': namaLengkap,
          'tanggalLahir': _selectedDate != null
              ? Timestamp.fromDate(_selectedDate!)
              : null,
          'diagnosisMedis': diagnosisMedis,
          'beratBadan': beratBadan,
          'tinggiBadan': tinggiBadan,
          'imt': imt,
          'skorIMT': skorIMT,
          'skorKehilanganBB': skorKehilanganBB,
          'skorEfekPenyakit': skorEfekPenyakit,
          'totalSkor': totalSkor,
          'tanggalPemeriksaan': Timestamp.now(),
          'lila': double.tryParse(
            _lilaController.text,
          ), // BARU: Simpan LILA ke Firestore
          'tl': double.tryParse(_tlController.text),
          'beratBadanDulu': double.tryParse(_beratBadanDuluController.text),
          'jenisKelamin': _jenisKelaminController.text,
          'aktivitas': _aktivitasController.text,
          'kehilanganNafsuMakan': _kehilanganNafsuMakanController.text,
          'alergiMakanan': _alergiMakananController.text,

          'sukaManis': _sukaManis,
          'sukaAsin': _sukaAsin,
          'makanBerlemak': _makanBerlemak,
          'jarangOlahraga': _jarangOlahraga,

          // BARU: Data Asuhan Gizi
          'detailAlergi': _detailAlergiController.text,
          'polaMakan': _polaMakanController.text,
          'labResults': labResultsMap,
          'klinikTD': _klinikTDController.text,
          'klinikNadi': _klinikNadiController.text,
          'klinikSuhu': _klinikSuhuController.text,
          'klinikRR': _klinikRRController.text,
          'riwayatPenyakitSekarang': _riwayatPenyakitSekarangController.text,
          'riwayatPenyakitDahulu': _riwayatPenyakitDahuluController.text,
          'diagnosaGizi': diagnosaString.toString().trim(),
          'intervensiDiet': _intervensiDietController.text,
          'intervensiBentukMakanan': _intervensiBentukMakananController.text,
          'intervensiVia': _intervensiViaController.text,
          'intervensiTujuan': _intervensiTujuanController.text,
          'monevIndikator': _monevIndikatorController.text,
          'monevAsupan': _monevAsupanController.text,
          'monevHasilLab': _monevHasilLabController.text,
          'monevStatusGizi': statusGizi,
          'klinikKU': _klinikKUController.text,
          'klinikKES': _klinikKESController.text,
          'klinikSPO2': _klinikSPO2Controller.text,
          'namaNutrisionis': _namaNutrisionisController.text,
          'createdBy': currentUser.uid,
          'tipePasien': 'dewasa',
        };

        // --- Kirim ke Firestore (MODIFIKASI OFFLINE SUPPORT) ---
        try {
          // Tentukan batas waktu tunggu (misal 3 detik)
          const timeoutDuration = Duration(seconds: 3);

          if (widget.patient != null) {
            // Update existing patient dengan Timeout
            await FirebaseFirestore.instance
                .collection('patients')
                .doc(widget.patient!.id)
                .update(patientData)
                .timeout(timeoutDuration);
          } else {
            // Create new patient dengan Timeout
            await FirebaseFirestore.instance
                .collection('patients')
                .add(patientData)
                .timeout(timeoutDuration);
          }

          // Jika berhasil konek ke server (Online)
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.patient != null
                      ? 'Data pasien berhasil diperbarui!'
                      : 'Data pasien berhasil disimpan!',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } on TimeoutException catch (_) {
          // Jika Internet Mati / Lambat (Masuk ke sini setelah 3 detik)
          // Data tetap tersimpan di lokal (cache) berkat persistenceEnabled: true
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Mode Offline: Data disimpan lokal dan akan diupload saat ada internet.',
                ),
                backgroundColor: Colors.orange, // Warna pembeda
                duration: Duration(seconds: 3),
              ),
            );
          }
          // Kita biarkan kode lanjut ke bawah untuk menutup halaman (pop)
        }

        // --- Bagian Navigasi Kembali (Tetap dijalankan baik Online maupun Offline) ---
        if (mounted) {
          // Create updated patient object to return
          final updatedPatient = Patient(
            id: widget.patient?.id ?? '', // Will be empty for new patients
            noRM: noRM,
            namaLengkap: namaLengkap,
            tanggalLahir: _selectedDate ?? DateTime.now(),
            diagnosisMedis: diagnosisMedis,
            beratBadan: beratBadan,
            tinggiBadan: tinggiBadan,
            jenisKelamin: _jenisKelaminController.text,
            aktivitas: _aktivitasController.text,
            kehilanganNafsuMakan: _kehilanganNafsuMakanController.text,
            imt: imt,
            skorIMT: skorIMT,
            skorKehilanganBB: skorKehilanganBB,
            skorEfekPenyakit: skorEfekPenyakit,
            totalSkor: totalSkor,
            tanggalPemeriksaan: DateTime.now(),
            lila: double.tryParse(_lilaController.text),
            tl: double.tryParse(_tlController.text),
            beratBadanDulu: double.tryParse(_beratBadanDuluController.text),
            alergiMakanan: _alergiMakananController.text,
            detailAlergi: _detailAlergiController.text,
            polaMakan: _polaMakanController.text,
            labResults: labResultsMap,
            klinikTD: _klinikTDController.text,
            klinikNadi: _klinikNadiController.text,
            klinikSuhu: _klinikSuhuController.text,
            klinikRR: _klinikRRController.text,
            riwayatPenyakitSekarang: _riwayatPenyakitSekarangController.text,
            riwayatPenyakitDahulu: _riwayatPenyakitDahuluController.text,
            diagnosaGizi: diagnosaString.toString().trim(),
            intervensiDiet: _intervensiDietController.text,
            intervensiBentukMakanan: _intervensiBentukMakananController.text,
            intervensiVia: _intervensiViaController.text,
            intervensiTujuan: _intervensiTujuanController.text,
            monevAsupan: _monevAsupanController.text,
            monevHasilLab: _monevHasilLabController.text,
            monevStatusGizi: statusGizi,
            klinikKU: _klinikKUController.text,
            klinikKES: _klinikKESController.text,
            klinikSPO2: _klinikSPO2Controller.text,
            namaNutrisionis: _namaNutrisionisController.text,
            createdBy: currentUser.uid,
            sukaManis: _sukaManis,
            sukaAsin: _sukaAsin,
            makanBerlemak: _makanBerlemak,
            jarangOlahraga: _jarangOlahraga,
            monevIndikator: _monevIndikatorController.text,
          );

          // Navigate back to previous screen with updated patient data
          Navigator.of(context).pop(updatedPatient);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _tanggalLahirController.text = DateFormat(
          'd MMMM y',
          'id_ID',
        ).format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithAnimatedFab(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: CustomAppBar(
        title: widget.patient != null
            ? 'Edit Data Pasien'
            : 'Tambah Pasien Baru',
        subtitle: widget.patient != null
            ? 'Perbarui data pasien'
            : 'Isi data dengan lengkap',
      ),
      floatingActionButton: FormActionButtons(
        onReset: _resetForm,
        onSubmit: _savePatientData,
        resetButtonColor: Colors.white, // Background jadi putih
        resetForegroundColor: const Color.fromARGB(255, 0, 148, 68),
        submitIcon: widget.patient != null
            ? const Icon(Icons.save, color: Colors.white)
            : const Icon(Icons.add, color: Colors.white),
        submitText: widget.patient != null ? 'Simpan' : 'Tambah',
        isLoading: _isLoading,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Input Data Pasien',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  _buildTextFormField(
                    controller: _noRMController,
                    label: 'No. Rekam Medis (RM)',
                    prefixIcon: const Icon(Icons.medical_information),
                    focusNode: _focusNodes[0],
                    maxLength: 20,
                  ),
                  const SizedBox(height: 16),

                  _buildTextFormField(
                    controller: _namaLengkapController,
                    label: 'Nama Lengkap',
                    prefixIcon: const Icon(Icons.person),
                    focusNode: _focusNodes[1],
                    maxLength: 100,
                  ),
                  const SizedBox(height: 16),

                  _buildTextFormField(
                    controller: _tanggalLahirController,
                    label: 'Tanggal Lahir',
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    prefixIcon: const Icon(Icons.calendar_today),
                    focusNode: _focusNodes[2],
                  ),
                  const SizedBox(height: 16),

                  _buildCustomDropdown(
                    controller: _jenisKelaminController,
                    label: 'Jenis Kelamin',
                    prefixIcon: const Icon(Icons.wc),
                    items: ['Laki-laki', 'Perempuan'],
                    focusNode: _focusNodes[3],
                  ),
                  const SizedBox(height: 16),

                  _buildTextFormField(
                    controller: _diagnosisMedisController,
                    label: 'Diagnosis Medis',
                    prefixIcon: const Icon(Icons.sick),
                    focusNode: _focusNodes[4],
                    maxLength: 500,
                  ),
                  const SizedBox(height: 16),

                  _buildTextFormField(
                    controller: _beratBadanController,
                    label: 'Berat Badan Saat Ini',
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.monitor_weight),
                    focusNode: _focusNodes[5],
                    suffixText: 'kg',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return null; // Izinkan kosong jika menggunakan LILA
                      }
                      if (double.tryParse(value) == null) {
                        return 'Masukkan angka yang valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // BARU: Form untuk LILA
                  _buildTextFormField(
                    controller: _lilaController,
                    label: 'Lingkar Lengan Atas (Opsional)',
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.fitness_center),
                    focusNode: _focusNodes[6],
                    suffixText: 'cm',
                    maxLength: 6,
                    validator: (value) {
                      if (_beratBadanController.text.isEmpty &&
                          (value == null || value.isEmpty)) {
                        return 'LILA tidak boleh kosong jika BB tidak diisi';
                      }
                      if (value != null &&
                          value.isNotEmpty &&
                          double.tryParse(value) == null) {
                        return 'Masukkan angka yang valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // BARU: Form untuk berat badan terdahulu
                  _buildTextFormField(
                    controller: _beratBadanDuluController,
                    label: 'Berat Badan 3-6 Bulan Lalu (Opsional)',
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.history),
                    focusNode: _focusNodes[7],
                    suffixText: 'kg',
                    maxLength: 6,
                    // Validator ini opsional, data tetap bisa disimpan jika kosong
                    validator: (value) {
                      if (value != null &&
                          value.isNotEmpty &&
                          double.tryParse(value) == null) {
                        return 'Masukkan angka yang valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Field untuk Tinggi Badan normal
                  _buildTextFormField(
                    controller: _tinggiBadanController,
                    label: 'Tinggi Badan',
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.height),
                    focusNode: _focusNodes[8],
                    suffixText: 'cm',
                    maxLength: 6,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return null; // Izinkan kosong jika menggunakan TL
                      }
                      if (double.tryParse(value) == null) {
                        return 'Masukkan angka yang valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // BARU: Form untuk Tinggi Lutut
                  _buildTextFormField(
                    controller: _tlController,
                    label: 'Tinggi Lutut (Opsional)',
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.accessibility),
                    focusNode: _focusNodes[9],
                    suffixText: 'cm',
                    maxLength: 6,
                    validator: (value) {
                      if (_tinggiBadanController.text.isEmpty &&
                          (value == null || value.isEmpty)) {
                        return 'TL tidak boleh kosong jika Tinggi Badan tidak diisi';
                      }
                      if (value != null &&
                          value.isNotEmpty &&
                          double.tryParse(value) == null) {
                        return 'Masukkan angka yang valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // BARU: Dropdown untuk kehilangan nafsu makan
                  _buildCustomDropdown(
                    controller: _kehilanganNafsuMakanController,
                    label: 'Ada asupan nutrisi > 5 hari?',
                    prefixIcon: const Icon(Icons.food_bank_outlined),
                    items: ['Ya', 'Tidak Ada'],
                    focusNode:
                        _focusNodes[10], // Ganti 10 dengan index yang benar
                  ),
                  const SizedBox(height: 16),

                  _buildCustomDropdown(
                    controller: _aktivitasController,
                    label: 'Tingkat Aktivitas',
                    prefixIcon: const Icon(Icons.directions_run),
                    items: [
                      'Sangat Jarang',
                      'Ringan',
                      'Sedang',
                      'Berat',
                      'Sangat Aktif',
                    ],
                    focusNode:
                        _focusNodes[11], // Ganti 11 dengan index yang benar
                    showSearch: false, // Aktifkan pencarian
                  ),
                  const SizedBox(height: 16),

                  _buildTextFormField(
                    controller: _namaNutrisionisController,
                    label: 'Nama Nutrisionis',
                    prefixIcon: const Icon(Icons.person),
                    focusNode: _focusNodes[12],
                    validator: (value) => null,
                    maxLength: 100,
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Input Data Asuhan Gizi (Opsional)',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  // Gunakan Column untuk mengelompokkan widget
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Riwayat Gizi/FH'),

                      _buildCustomDropdown(
                        controller: _alergiMakananController,
                        label: 'Alergi Makanan',
                        prefixIcon: const Icon(Icons.no_food),
                        items: ['Ya', 'Tidak'],
                        focusNode:
                            _focusNodes[13], // Ganti 12 dengan index yang benar
                        onChanged: (value) {
                          // onChanged khusus untuk memicu setState agar field di bawahnya muncul/hilang
                          setState(() {
                            _alergiMakananController.text = value ?? 'Tidak';
                            if (value == 'Tidak') {
                              _detailAlergiController.clear();
                            }
                          });
                        },
                      ),

                      // 2. Gunakan controller untuk memeriksa kondisi
                      if (_alergiMakananController.text == 'Ya')
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: _buildTextFormField(
                            controller: _detailAlergiController,
                            label: 'Jika Ya, sebutkan alerginya',
                            prefixIcon: const Icon(Icons.description),
                            maxLength: 100,
                            focusNode:
                                _focusNodes[14], // Ganti 13 dengan index yang benar
                            validator: (value) {
                              // Validasi ini hanya berjalan jika field-nya terlihat
                              if (value == null || value.isEmpty) {
                                return 'Detail alergi tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kolom 1: Frekuensi
                      Expanded(
                        flex: 2,
                        child: _buildTextFormField(
                          controller: _polaMakanFreqController,
                          label: 'Pola Makan', // Agar Jelas
                          prefixIcon: const Icon(Icons.restaurant_menu),
                          focusNode: _focusNodes[15],
                          validator: (v) => null,
                          maxLength: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Kolom 2: Asupan (%)
                      Expanded(
                        flex: 1,
                        child: _buildTextFormField(
                          controller: _polaMakanPercentController,
                          label: 'Asupan',
                          suffixText: '%', // Agar Jelas
                          keyboardType: TextInputType.number,
                          focusNode:
                              _focusNodes[16], // Focus node baru agar tidak tabrakan
                          validator: (v) => null,
                          maxLength: 3,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Kebiasaan Makan & Aktivitas (Centang yang sesuai):',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  CheckboxListTile(
                    title: const Text(
                      'Sering konsumsi manis (Gula/Minuman Manis)',
                    ),
                    value: _sukaManis,
                    onChanged: (bool? value) {
                      setState(() {
                        _sukaManis = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),

                  CheckboxListTile(
                    title: const Text('Sering konsumsi asin/garam tinggi'),
                    value: _sukaAsin,
                    onChanged: (bool? value) {
                      setState(() {
                        _sukaAsin = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),

                  CheckboxListTile(
                    title: const Text(
                      'Sering konsumsi makanan berlemak/gorengan',
                    ),
                    value: _makanBerlemak,
                    onChanged: (bool? value) {
                      setState(() {
                        _makanBerlemak = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),

                  CheckboxListTile(
                    title: const Text(
                      'Jarang berolahraga (< 150 menit/minggu)',
                    ),
                    value: _jarangOlahraga,
                    onChanged: (bool? value) {
                      setState(() {
                        _jarangOlahraga = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),

                  _buildSectionHeader('Biokimia/BD'),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _labItems.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // DROPDOWN JENIS LAB
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Jenis Tes',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 15,
                                  ),
                                ),
                                // Pastikan value ada di list items atau null
                                initialValue: _labItems[index].selectedType,
                                items: _labOptions.map((String type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(
                                      type,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _labItems[index].selectedType = val;
                                  });
                                },
                                validator: (val) {
                                  if (_labItems[index]
                                          .valueController
                                          .text
                                          .isNotEmpty &&
                                      val == null) {
                                    return 'Pilih jenis';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),

                            // INPUT HASIL LAB
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _labItems[index].valueController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Hasil',
                                  border: OutlineInputBorder(),
                                  suffixText: 'mg/dL',
                                ),
                                validator: (val) {
                                  if (_labItems[index].selectedType != null &&
                                      (val == null || val.isEmpty)) {
                                    return 'Isi nilai';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            // TOMBOL HAPUS (Muncul jika item > 1)
                            if (_labItems.length > 1 || index > 0)
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _labItems[index].valueController.dispose();
                                    _labItems.removeAt(index);
                                  });
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (_labItems.length < 6)
                    OutlinedButton.icon(
                      onPressed: () => _addLabItem(null, ''),
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Hasil Lab Lain'),
                    ),

                  _buildSectionHeader('Klinik/Fisik/PD'),

                  _buildTextFormField(
                    controller: _klinikTDController,
                    label: 'Tekanan Darah (TD)',
                    prefixIcon: const Icon(Icons.favorite),
                    suffixText: 'mmHg',
                    focusNode: _focusNodes[17],
                    maxLength: 8,
                    validator: (value) => null, // Opsional
                  ),
                  const SizedBox(height: 16),

                  _buildTextFormField(
                    controller: _klinikNadiController,
                    label: 'Nadi (N)',
                    prefixIcon: const Icon(Icons.monitor_heart),
                    suffixText: 'x/menit',
                    focusNode: _focusNodes[18],
                    maxLength: 4,
                    validator: (value) => null, // Opsional
                  ),
                  const SizedBox(height: 16),

                  _buildTextFormField(
                    controller: _klinikSuhuController,
                    label: 'Suhu Badan (SB)',
                    prefixIcon: const Icon(Icons.thermostat),
                    suffixText: '°C',
                    focusNode: _focusNodes[19],
                    maxLength: 4,
                    validator: (value) => null,
                  ),
                  const SizedBox(height: 16),

                  _buildTextFormField(
                    controller: _klinikRRController,
                    label: 'Respirasi (R)',
                    prefixIcon: const Icon(Icons.air),
                    suffixText: 'x/menit',
                    focusNode: _focusNodes[20],
                    maxLength: 4,
                    validator: (value) => null,
                  ),
                  const SizedBox(height: 16),

                  _buildTextFormField(
                    controller: _klinikSPO2Controller,
                    label: 'Saturasi Oksigen (SpO2)',
                    prefixIcon: const Icon(Icons.air),
                    suffixText: '%',
                    focusNode: _focusNodes[21],
                    maxLength: 4,
                    validator: (value) => null,
                  ),
                  const SizedBox(height: 16),

                  _buildTextFormField(
                    controller: _klinikKUController,
                    label: 'Keadaan Umum (KU)',
                    prefixIcon: const Icon(Icons.accessibility_new),
                    focusNode: _focusNodes[22],
                    validator: (value) => null,
                    maxLength: 20,
                  ),
                  const SizedBox(height: 16),

                  _buildTextFormField(
                    controller: _klinikKESController,
                    label: 'Kesadaran (KES)',
                    prefixIcon: const Icon(Icons.psychology),
                    focusNode: _focusNodes[23],
                    validator: (value) => null,
                    maxLength: 20,
                  ),

                  _buildSectionHeader('Riwayat Personal/CH'),

                  _buildTextFormField(
                    controller: _riwayatPenyakitSekarangController,
                    label: 'Riwayat Penyakit Sekarang (RPS)',
                    prefixIcon: const Icon(Icons.history_edu),
                    focusNode: _focusNodes[24],
                    maxLength: 500,
                    validator: (value) => null,
                  ),
                  const SizedBox(height: 16),

                  _buildTextFormField(
                    controller: _riwayatPenyakitDahuluController,
                    label: 'Riwayat Penyakit Dahulu (RPD)',
                    prefixIcon: const Icon(Icons.history),
                    focusNode: _focusNodes[25],
                    maxLength: 500,
                    validator: (value) => null,
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Diagnosa Gizi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _generateExpertDiagnosis,
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text('Bantu Diagnosa Otomatis'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[50], // Warna soft
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _diagnosisItems.length,
                    itemBuilder: (context, index) {
                      return Card(
                        key: ObjectKey(_diagnosisItems[index]),
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.grey[50],
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Diagnosa #${index + 1}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_diagnosisItems.length > 1)
                                    InkWell(
                                      onTap: () => _removeDiagnosisItem(index),
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // P
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return Autocomplete<NutritionReferenceItem>(
                                    // 1. Data yang akan ditampilkan berdasarkan ketikan user
                                    optionsBuilder:
                                        (TextEditingValue textEditingValue) {
                                          if (textEditingValue.text.isEmpty) {
                                            return const Iterable<
                                              NutritionReferenceItem
                                            >.empty();
                                          }
                                          // Logika pencarian: Cocokkan Label, Kode, atau Definisi
                                          return DiagnosisTerminology
                                              .allDiagnoses
                                              .where((
                                                NutritionReferenceItem option,
                                              ) {
                                                final String keyword =
                                                    textEditingValue.text
                                                        .toLowerCase();
                                                return option.label
                                                        .toLowerCase()
                                                        .contains(keyword) ||
                                                    option.code
                                                        .toLowerCase()
                                                        .contains(keyword) ||
                                                    (option.definition
                                                        .toLowerCase()
                                                        .contains(keyword));
                                              });
                                        },

                                    // 2. Apa yang ditampilkan di text field saat item dipilih
                                    displayStringForOption:
                                        (NutritionReferenceItem option) =>
                                            '[${option.code}] ${option.label}',

                                    // 3. Aksi saat item dipilih
                                    onSelected: (NutritionReferenceItem selection) {
                                      // Update controller manual agar tersimpan di state
                                      _diagnosisItems[index].pController.text =
                                          '[${selection.code}] ${selection.label}';

                                      // (Opsional) Otomatis isi Etiologi atau Signs jika mau
                                      // _diagnosisItems[index].eController.text = selection.definition ?? '';
                                    },

                                    // 4. Membangun Text Field-nya (Agar tetap terlihat sama dengan style aplikasi)
                                    fieldViewBuilder:
                                        (
                                          context,
                                          fieldTextEditingController,
                                          fieldFocusNode,
                                          onFieldSubmitted,
                                        ) {
                                          // PENTING: Sinkronisasi controller bawaan Autocomplete dengan controller kita
                                          // Jika controller kita sudah ada isinya (misal dari edit pasien), pasang ke controller autocomplete
                                          if (_diagnosisItems[index]
                                                  .pController
                                                  .text
                                                  .isNotEmpty &&
                                              fieldTextEditingController
                                                  .text
                                                  .isEmpty) {
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                                  if (context.mounted) {
                                                    fieldTextEditingController
                                                            .text =
                                                        _diagnosisItems[index]
                                                            .pController
                                                            .text;
                                                  }
                                                });
                                          }

                                          // Listener: Jika user mengetik manual (bukan pilih opsi), tetap simpan ke controller utama
                                          fieldTextEditingController
                                              .addListener(() {
                                                _diagnosisItems[index]
                                                        .pController
                                                        .text =
                                                    fieldTextEditingController
                                                        .text;
                                              });

                                          return TextFormField(
                                            controller:
                                                fieldTextEditingController,
                                            focusNode: fieldFocusNode,
                                            maxLength: 200,
                                            textInputAction:
                                                TextInputAction.done,
                                            decoration: const InputDecoration(
                                              labelText: 'Problem (P)',
                                              isDense: true,
                                              border: OutlineInputBorder(),
                                              suffixIcon: Icon(
                                                Icons.search,
                                              ), // Indikator bahwa ini bisa dicari
                                            ),
                                            maxLines: null,
                                          );
                                        },

                                    // 5. Tampilan List Saran (Dropdown di bawah)
                                    optionsViewBuilder: (context, onSelected, options) {
                                      return Align(
                                        alignment: Alignment.topLeft,
                                        child: Material(
                                          elevation: 4.0,
                                          child: SizedBox(
                                            width: constraints
                                                .maxWidth, // Lebar menyesuaikan form
                                            height:
                                                100, // Tinggi maksimal dropdown
                                            child: ListView.builder(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              itemCount: options.length,
                                              itemBuilder:
                                                  (
                                                    BuildContext context,
                                                    int i,
                                                  ) {
                                                    final NutritionReferenceItem
                                                    option = options.elementAt(
                                                      i,
                                                    );
                                                    return ListTile(
                                                      title: Text(
                                                        '${option.code} - ${option.label}',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      subtitle: Text(
                                                        option.definition,
                                                      ),
                                                      onTap: () {
                                                        onSelected(option);
                                                      },
                                                    );
                                                  },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              // E
                              TextFormField(
                                controller: _diagnosisItems[index].eController,
                                maxLength: 200,
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(
                                  labelText: 'Berkaitan dengan - Etiology (E)',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: null,
                              ),
                              const SizedBox(height: 8),
                              // S
                              TextFormField(
                                controller: _diagnosisItems[index].sController,
                                maxLength: 200,
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(
                                  labelText:
                                      'Ditandai dengan - Signs/Symptoms (S)',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Tombol Tambah Diagnosa
                  if (_diagnosisItems.length < 3)
                    OutlinedButton.icon(
                      onPressed: () => _addDiagnosisItem(),
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Diagnosa'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green[700],
                        side: BorderSide(color: Colors.green[700]!),
                      ),
                    ),

                  // Opsional: Tampilkan pesan jika sudah penuh (biar UI tidak terlihat kosong tiba-tiba)
                  if (_diagnosisItems.length >= 3)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Center(
                        child: Text(
                          "Batas maksimal 3 diagnosa tercapai",
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),

                  _buildSectionHeader('Intervensi Gizi'),

                  SearchableTerminologyField(
                    label: 'Jenis Diet / Intervensi',
                    controller: _intervensiDietController,
                    dataList: IntervensiData
                        .allInterventions, // Pastikan tipe datanya TerminologyItem
                    prefixIcon: const Icon(Icons.food_bank),
                    focusNode: _focusNodes[27],
                    maxLength: 200,
                    validator: (value) => null,
                  ),
                  const SizedBox(height: 16),

                  _buildTextFormField(
                    controller: _intervensiBentukMakananController,
                    label: 'Bentuk Makanan',
                    prefixIcon: const Icon(Icons.fastfood),
                    focusNode: _focusNodes[28],
                    maxLength: 200,
                    validator: (value) => null,
                  ),
                  const SizedBox(height: 16),

                  _buildTextFormField(
                    controller: _intervensiTujuanController,
                    label: 'Tujuan Diet',
                    prefixIcon: const Icon(Icons.flag),
                    focusNode: _focusNodes[29],
                    maxLength: 500,
                    validator: (value) => null,
                  ),
                  const SizedBox(height: 16),

                  _buildCustomDropdown(
                    controller: _intervensiViaController,
                    label: 'Via',
                    prefixIcon: const Icon(Icons.route),
                    focusNode: _focusNodes[30],
                    items: const ['Oral', 'Enteral', 'Parenteral'],
                    validator: (value) => null,
                  ),

                  _buildSectionHeader('Monitoring & Evaluasi'),

                  SearchableTerminologyField(
                    label: 'Indikator Monitoring',
                    controller: _monevIndikatorController,
                    dataList: MonitoringData.allMonitoringItems,
                    prefixIcon: const Icon(Icons.monitor_heart),
                    focusNode: _focusNodes[31],
                    maxLength: 500,
                    validator: (value) => null,
                  ),
                  const SizedBox(height: 16),

                  _buildTextFormField(
                    controller: _monevAsupanController,
                    label: 'Asupan Makanan',
                    prefixIcon: const Icon(Icons.monitor),
                    focusNode: _focusNodes[32],
                    maxLength: 500,
                    validator: (value) => null,
                  ),
                  const SizedBox(height: 16),

                  _buildTextFormField(
                    controller: _monevHasilLabController,
                    label: 'Hasil Lab',
                    prefixIcon: const Icon(Icons.document_scanner),
                    focusNode: _focusNodes[33],
                    maxLength: 500,
                    validator: (value) => null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required FocusNode focusNode,
    bool readOnly = false,
    VoidCallback? onTap,
    Icon? prefixIcon,
    TextInputType? keyboardType,
    String? suffixText,
    // DIUBAH: Tambahkan parameter validator
    String? Function(String?)? validator,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      inputFormatters: [
        // 1. Jika tipe input angka, hanya boleh digit dan titik
        if (keyboardType == TextInputType.number)
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        // 2. Batasi panjang karakter jika maxLength diberikan
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: prefixIcon,
        suffixText: suffixText,
      ),
      // DIUBAH: Gunakan validator yang diberikan atau default validator
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return '$label tidak boleh kosong';
            }
            if (keyboardType == TextInputType.number &&
                double.tryParse(value) == null) {
              return 'Masukkan angka yang valid';
            }
            return null;
          },
    );
  }

  Widget _buildCustomDropdown({
    required TextEditingController controller,
    required String label,
    required List<String> items,
    required Icon prefixIcon,
    required FocusNode focusNode,
    bool showSearch = false,
    void Function(String?)? onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: false,
        fit: FlexFit.loose,
        constraints: const BoxConstraints(maxHeight: 240),
      ),
      items: items,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: prefixIcon,
        ),
      ),
      onChanged:
          onChanged ??
          (String? newValue) {
            setState(() {
              controller.text = newValue ?? '';
            });
          },
      selectedItem: controller.text.isEmpty ? null : controller.text,
      validator:
          validator ??
          (value) =>
              (value == null || value.isEmpty) ? '$label harus dipilih' : null,
    );
  }
}
