// lib\src\features\patient_home\presentation\pages\data_form_anak_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_diagnosa_gizi/src/login/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/models/patient_anak_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/scaffold_with_animated_fab.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_validator_utils.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/data/models/nutrition_calculation_helper.dart';
import 'dart:async';

class DataFormAnakPage extends StatefulWidget {
  final PatientAnak? patient;

  const DataFormAnakPage({super.key, this.patient});

  @override
  State<DataFormAnakPage> createState() => _DataFormAnakPageState();
}

class _DataFormAnakPageState extends State<DataFormAnakPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  final List<FocusNode> _focusNodes = [];

  // Controllers Data Dasar
  final _noRMController = TextEditingController();
  final _namaLengkapController = TextEditingController();
  final _tanggalLahirController = TextEditingController();
  final _jenisKelaminController = TextEditingController();
  final _beratBadanController = TextEditingController();
  final _tinggiBadanController = TextEditingController();
  final _namaNutrisionisController = TextEditingController();
  final _diagnosisMedisController = TextEditingController();

  // Controllers Skrining
  final _kehilanganBeratBadanController = TextEditingController();
  final _kehilanganNafsuMakanController = TextEditingController();
  final _anakSakitBeratController = TextEditingController();

  // Controllers Tambahan (Antropometri Lanjut)
  final _lilaController = TextEditingController();
  final _lingkarKepalaController = TextEditingController();
  final _bbiController = TextEditingController();

  // Controllers Asuhan Gizi - Biokimia
  final _biokimiaGDSController = TextEditingController();
  final _biokimiaUreumController = TextEditingController();
  final _biokimiaHGBController = TextEditingController();
  final _biokimiaENTController = TextEditingController();

  // Controllers Asuhan Gizi - Klinik/Fisik
  final _klinikTDController = TextEditingController();
  final _klinikNadiController = TextEditingController();
  final _klinikSuhuController = TextEditingController();
  final _klinikRRController = TextEditingController();
  final _klinikSPO2Controller = TextEditingController();
  final _klinikKUController = TextEditingController();
  final _klinikKESController = TextEditingController();

  // Controllers Riwayat Personal & Gizi
  final _riwayatPenyakitSekarangController = TextEditingController();
  final _riwayatPenyakitDahuluController = TextEditingController();
  final _alergiMakananController = TextEditingController(text: 'Tidak');
  final _polaMakanController = TextEditingController();

  // Controllers Diagnosa & Intervensi & Monev
  final _diagnosaGiziController = TextEditingController();
  final _intervensiDietController = TextEditingController();
  final _intervensiBentukMakananController = TextEditingController();
  final _intervensiViaController = TextEditingController();
  final _intervensiTujuanController = TextEditingController();
  final _monevAsupanController = TextEditingController();

  bool _alergiTelur = false;
  bool _alergiSusu = false;
  bool _alergiKacang = false;
  bool _alergiGluten = false;
  bool _alergiUdang = false;
  bool _alergiIkan = false;
  bool _alergiHazelnut = false;

  final _alergiLainnyaController = TextEditingController();

  DateTime? _selectedDate;

  final Map<String, int> _bbLossMap = {'Tidak': 0, 'Ya': 2};
  final Map<String, int> _appetiteMap = {
    'Makan seperti biasa': 0,
    'Ada penurunan': 1,
    'Tidak makan sama sekali/sedikit': 2,
  };
  final Map<String, int> _sickMap = {'Tidak': 0, 'Ya': 2};

  @override
  void initState() {
    super.initState();
    final controllers = [
      _noRMController,
      _namaLengkapController,
      _tanggalLahirController,
      _jenisKelaminController,
      _beratBadanController,
      _tinggiBadanController,
      _namaNutrisionisController,
      _diagnosisMedisController,
      _kehilanganBeratBadanController,
      _kehilanganNafsuMakanController,
      _anakSakitBeratController,
      _lilaController,
      _lingkarKepalaController,
      _bbiController,
      _biokimiaGDSController,
      _biokimiaUreumController,
      _biokimiaHGBController,
      _biokimiaENTController,
      _klinikTDController,
      _klinikNadiController,
      _klinikSuhuController,
      _klinikRRController,
      _klinikSPO2Controller,
      _klinikKUController,
      _klinikKESController,
      _riwayatPenyakitSekarangController,
      _riwayatPenyakitDahuluController,
      _alergiMakananController,
      _polaMakanController,
      _diagnosaGiziController,
      _intervensiDietController,
      _intervensiBentukMakananController,
      _intervensiViaController,
      _intervensiTujuanController,
      _monevAsupanController,
    ];

    // Buat FocusNode untuk setiap controller
    for (int i = 0; i < controllers.length; i++) {
      _focusNodes.add(FocusNode());
    }

    if (widget.patient != null) {
      _initializeForm(widget.patient!);
    }
  }

  void _initializeForm(PatientAnak patient) {
    _noRMController.text = patient.noRM;
    _namaLengkapController.text = patient.namaLengkap;
    _tanggalLahirController.text = patient.tanggalLahirFormatted;
    _selectedDate = patient.tanggalLahir;
    _jenisKelaminController.text = patient.jenisKelamin;
    _beratBadanController.text = patient.beratBadan.toString();
    _tinggiBadanController.text = patient.tinggiBadan.toString();
    _namaNutrisionisController.text = patient.namaNutrisionis ?? '';
    _diagnosisMedisController.text = patient.diagnosisMedis;
    _kehilanganBeratBadanController.text =
        _getKeyFromValue(_bbLossMap, patient.kehilanganBeratBadan) ?? '';
    _kehilanganNafsuMakanController.text =
        _getKeyFromValue(_appetiteMap, patient.kehilanganNafsuMakan) ?? '';
    _anakSakitBeratController.text =
        _getKeyFromValue(_sickMap, patient.anakSakitBerat) ?? '';
    _lilaController.text = patient.lila?.toString() ?? '';
    _lingkarKepalaController.text = patient.lingkarKepala?.toString() ?? '';
    _bbiController.text = patient.bbi?.toString() ?? '';

    _biokimiaGDSController.text = patient.biokimiaGDS ?? '';
    _biokimiaUreumController.text = patient.biokimiaUreum ?? '';
    _biokimiaHGBController.text = patient.biokimiaHGB ?? '';
    _biokimiaENTController.text = patient.biokimiaENT ?? '';

    _klinikTDController.text = patient.klinikTD ?? '';
    _klinikNadiController.text = patient.klinikNadi ?? '';
    _klinikSuhuController.text = patient.klinikSuhu ?? '';
    _klinikRRController.text = patient.klinikRR ?? '';
    _klinikSPO2Controller.text = patient.klinikSPO2 ?? '';
    _klinikKUController.text = patient.klinikKU ?? '';
    _klinikKESController.text = patient.klinikKES ?? '';

    _riwayatPenyakitSekarangController.text =
        patient.riwayatPenyakitSekarang ?? '';
    _riwayatPenyakitDahuluController.text = patient.riwayatPenyakitDahulu ?? '';
    _polaMakanController.text = patient.polaMakan ?? '';

    _diagnosaGiziController.text = patient.diagnosaGizi ?? '';

    _intervensiDietController.text = patient.intervensiDiet ?? '';
    _intervensiBentukMakananController.text =
        patient.intervensiBentukMakanan ?? '';
    _intervensiViaController.text = patient.intervensiVia ?? '';
    _intervensiTujuanController.text = patient.intervensiTujuan ?? '';

    _monevAsupanController.text = patient.monevAsupan ?? '';

    if (patient.alergiMakanan != null && patient.alergiMakanan != 'Tidak') {
      // Pecah string menjadi list, misal: ["Telur", "Kacang", "Stroberi"]
      _alergiMakananController.text = 'Ya';
      List<String> items = patient.alergiMakanan!.split(', ');
      List<String> otherItems = [];

      setState(() {
        for (var item in items) {
          String lower = item.toLowerCase();
          
          // Cek satu per satu
          if (lower.contains('telur')) {
            _alergiTelur = true;
          } else if (lower.contains('susu')) {
            _alergiSusu = true;
          } else if (lower.contains('kacang')) {
            _alergiKacang = true;
          } else if (lower.contains('gluten') || lower.contains('gandum')) {
            _alergiGluten = true;
          } else if (lower.contains('udang')) {
            _alergiUdang = true;
          } else if (lower.contains('ikan')) {
            _alergiIkan = true;
          } else if (lower.contains('hazelnut') || lower.contains('almond')) {
            _alergiHazelnut = true;
          } else {
            // Jika tidak termasuk kategori di atas, masukkan ke list 'Lainnya'
            if (item.trim().isNotEmpty) {
              otherItems.add(item);
            }
          }
        }
        
        // Gabungkan sisa item ke text controller 'Lainnya'
        if (otherItems.isNotEmpty) {
          _alergiLainnyaController.text = otherItems.join(', ');
        }
      });
    } else {
      // Jika datanya 'Tidak' atau null
      _alergiMakananController.text = 'Tidak';
    }
  }

  String? _getKeyFromValue(Map<String, int> map, int? value) {
    if (value == null) return null;
    for (var entry in map.entries) {
      if (entry.value == value) return entry.key;
    }
    return null;
  }

  @override
  void dispose() {
    _noRMController.dispose();
    _namaLengkapController.dispose();
    _tanggalLahirController.dispose();
    _beratBadanController.dispose();
    _tinggiBadanController.dispose();
    _namaNutrisionisController.dispose();
    _jenisKelaminController.dispose();
    _diagnosisMedisController.dispose();
    _kehilanganBeratBadanController.dispose();
    _kehilanganNafsuMakanController.dispose();
    _anakSakitBeratController.dispose();
    _lilaController.dispose();
    _lingkarKepalaController.dispose();
    _bbiController.dispose();
    _biokimiaGDSController.dispose();
    _biokimiaUreumController.dispose();
    _biokimiaHGBController.dispose();
    _biokimiaENTController.dispose();
    _klinikTDController.dispose();
    _klinikNadiController.dispose();
    _klinikSuhuController.dispose();
    _klinikRRController.dispose();
    _klinikSPO2Controller.dispose();
    _klinikKUController.dispose();
    _klinikKESController.dispose();
    _riwayatPenyakitSekarangController.dispose();
    _riwayatPenyakitDahuluController.dispose();
    _alergiMakananController.dispose();
    _polaMakanController.dispose();
    _diagnosaGiziController.dispose();
    _intervensiDietController.dispose();
    _intervensiBentukMakananController.dispose();
    _intervensiViaController.dispose();
    _intervensiTujuanController.dispose();
    _monevAsupanController.dispose();
    // Dispose semua FocusNode
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _noRMController.clear();
      _namaLengkapController.clear();
      _tanggalLahirController.clear();
      _beratBadanController.clear();
      _tinggiBadanController.clear();
      _jenisKelaminController.clear();
      _selectedDate = null;
      _namaNutrisionisController.clear();
      _diagnosisMedisController.clear();
      _kehilanganBeratBadanController.clear();
      _kehilanganNafsuMakanController.clear();
      _anakSakitBeratController.clear();
      _lilaController.clear();
      _lingkarKepalaController.clear();
      _bbiController.clear();
      _biokimiaGDSController.clear();
      _biokimiaUreumController.clear();
      _biokimiaHGBController.clear();
      _biokimiaENTController.clear();
      _klinikTDController.clear();
      _klinikNadiController.clear();
      _klinikSuhuController.clear();
      _klinikRRController.clear();
      _klinikSPO2Controller.clear();
      _klinikKUController.clear();
      _klinikKESController.clear();
      _riwayatPenyakitSekarangController.clear();
      _riwayatPenyakitDahuluController.clear();
      _alergiMakananController.text = 'Tidak';
      _polaMakanController.clear();
      _diagnosaGiziController.clear();
      _intervensiDietController.clear();
      _intervensiBentukMakananController.clear();
      _intervensiViaController.clear();
      _intervensiTujuanController.clear();
      _monevAsupanController.clear();
    });
  }

  // (Pastikan untuk dispose semua controller di @override dispose)

  Future<void> _savePatientAnakData() async {
    List<String> listAlergi = [];
    if (_alergiTelur) listAlergi.add('Telur');
    if (_alergiSusu) listAlergi.add('Susu Sapi');
    if (_alergiKacang) listAlergi.add('Kacang');
    if (_alergiGluten) listAlergi.add('Gluten/Gandum');
    if (_alergiUdang) listAlergi.add('Udang');
    if (_alergiIkan) listAlergi.add('Ikan');
    if (_alergiHazelnut) listAlergi.add('Hazelnut/Almond');

    // Tambahkan manual text
    if (_alergiLainnyaController.text.isNotEmpty) {
      listAlergi.add(_alergiLainnyaController.text);
    }
    String stringAlergiFinal = listAlergi.isEmpty ? 'Tidak' : listAlergi.join(', ');

    if (FormValidatorUtils.validateAndScroll(
      context: context,
      formKey: _formKey,
      focusNodes: _focusNodes,
    )) {
      setState(() => _isLoading = true);

      final User? currentUser = _authService.getCurrentUser();
      if (currentUser == null) {
        // Handle error: user not logged in
        setState(() => _isLoading = false);
        return;
      }

      try {
        final beratBadan = double.parse(_beratBadanController.text);
        final tinggiBadan = double.parse(_tinggiBadanController.text);

        double calculatedBBI = 0;
        if (_selectedDate != null) {
          calculatedBBI = _hitungBBIAnak(_selectedDate!);
        }

        final calculationResult = NutritionCalculationHelper.calculateAll(
          birthDate: _selectedDate!,
          checkDate: DateTime.now(),
          weight: beratBadan,
          height: tinggiBadan,
          gender: _jenisKelaminController.text,
        );

        // Ambil hasil kalkulasi
        final resultBBU = calculationResult['bbPerU'];
        final resultTBU = calculationResult['tbPerU'];
        final resultBBTB = calculationResult['bbPerTB'];
        final resultIMTU = calculationResult['imtPerU'];

        final patientAnakData = {
          'noRM': _noRMController.text,
          'namaLengkap': _namaLengkapController.text,
          'tanggalLahir': Timestamp.fromDate(_selectedDate!),
          'jenisKelamin': _jenisKelaminController.text,
          'beratBadan': beratBadan,
          'tinggiBadan': tinggiBadan,
          'namaNutrisionis': _namaNutrisionisController.text,
          'tanggalPemeriksaan': Timestamp.now(),
          'createdBy': currentUser.uid,
          'tipePasien': 'anak',
          'diagnosisMedis': _diagnosisMedisController.text,
          'kehilanganBeratBadan':
              _bbLossMap[_kehilanganBeratBadanController.text] ?? 0,
          'kehilanganNafsuMakan':
              _appetiteMap[_kehilanganNafsuMakanController.text] ?? 0,
          'anakSakitBerat': _sickMap[_anakSakitBeratController.text] ?? 0,
          'zScoreBBU': resultBBU['zScore'], // BB/U Z-Score
          'statusGiziBBU': resultBBU['category'], // BB/U Status

          'zScoreTBU': resultTBU['zScore'], // TB/U Z-Score
          'statusGiziTBU': resultTBU['category'],
          'zScoreBBTB': resultBBTB['zScore'], // BB/TB (Gizi Buruk/Baik check)
          'statusGiziBBTB': resultBBTB['category'],

          'zScoreIMTU': resultIMTU['zScore'], // IMT/U
          'statusGiziIMTU': resultIMTU['category'],

          'lila': double.tryParse(_lilaController.text),
          'lingkarKepala': double.tryParse(_lingkarKepalaController.text),
          'bbi': calculatedBBI,

          'biokimiaGDS': _biokimiaGDSController.text,
          'biokimiaUreum': _biokimiaUreumController.text,
          'biokimiaHGB': _biokimiaHGBController.text,
          'biokimiaENT': _biokimiaENTController.text,

          'klinikTD': _klinikTDController.text,
          'klinikNadi': _klinikNadiController.text,
          'klinikSuhu': _klinikSuhuController.text,
          'klinikRR': _klinikRRController.text,
          'klinikSPO2': _klinikSPO2Controller.text,
          'klinikKU': _klinikKUController.text,
          'klinikKES': _klinikKESController.text,

          'riwayatPenyakitSekarang': _riwayatPenyakitSekarangController.text,
          'riwayatPenyakitDahulu': _riwayatPenyakitDahuluController.text,
          'alergiMakanan': stringAlergiFinal,
          'polaMakan': _polaMakanController.text,

          'diagnosaGizi': _diagnosaGiziController.text,

          'intervensiDiet': _intervensiDietController.text,
          'intervensiBentukMakanan': _intervensiBentukMakananController.text,
          'intervensiVia': _intervensiViaController.text,
          'intervensiTujuan': _intervensiTujuanController.text,

          'monevAsupan': _monevAsupanController.text,
        };

        try {
          // Batas waktu tunggu 3 detik
          const timeoutDuration = Duration(seconds: 3);

          if (widget.patient != null) {
            // Update dengan Timeout
            await FirebaseFirestore.instance
                .collection('patients')
                .doc(widget.patient!.id)
                .update(patientAnakData)
                .timeout(timeoutDuration);
          } else {
            // Create dengan Timeout
            await FirebaseFirestore.instance
                .collection('patients')
                .add(patientAnakData)
                .timeout(timeoutDuration);
          }

          // Jika berhasil online (tidak timeout)
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.patient != null
                      ? 'Data pasien anak berhasil diperbarui!'
                      : 'Data pasien anak berhasil disimpan!',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } on TimeoutException catch (_) {
          // Jika koneksi lambat/mati, masuk ke sini
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Mode Offline: Data disimpan lokal dan akan diupload saat ada internet.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }

        final updatedPatientObj = PatientAnak(
          id: widget.patient?.id ?? '',
          noRM: _noRMController.text,
          namaLengkap: _namaLengkapController.text,
          tanggalLahir: _selectedDate!,
          jenisKelamin: _jenisKelaminController.text,
          beratBadan: beratBadan,
          tinggiBadan: tinggiBadan,
          tanggalPemeriksaan: DateTime.now(),
          createdBy: widget.patient?.createdBy ?? currentUser.uid,
          diagnosisMedis: _diagnosisMedisController.text,
          tipePasien: 'anak',
          zScoreBBU: resultBBU['zScore'],
          statusGiziBBU: resultBBU['category'],
          zScoreTBU: resultTBU['zScore'],
          statusGiziTBU: resultTBU['category'],
          zScoreBBTB: resultBBTB['zScore'], // BB/TB (Gizi Buruk/Baik check)
          statusGiziBBTB: resultBBTB['category'],

          zScoreIMTU: resultIMTU['zScore'], // IMT/U
          statusGiziIMTU: resultIMTU['category'],

          namaNutrisionis: _namaNutrisionisController.text,
          kehilanganBeratBadan:
              _bbLossMap[_kehilanganBeratBadanController.text],
          kehilanganNafsuMakan:
              _appetiteMap[_kehilanganNafsuMakanController.text],
          anakSakitBerat: _sickMap[_anakSakitBeratController.text],
          lila: double.tryParse(_lilaController.text),
          lingkarKepala: double.tryParse(_lingkarKepalaController.text),
          bbi: calculatedBBI,

          // 2. Biokimia
          biokimiaGDS: _biokimiaGDSController.text,
          biokimiaUreum: _biokimiaUreumController.text,
          biokimiaHGB: _biokimiaHGBController.text,
          biokimiaENT: _biokimiaENTController.text,

          // 3. Klinik/Fisik
          klinikTD: _klinikTDController.text,
          klinikNadi: _klinikNadiController.text,
          klinikSuhu: _klinikSuhuController.text,
          klinikRR: _klinikRRController.text,
          klinikSPO2: _klinikSPO2Controller.text,
          klinikKU: _klinikKUController.text,
          klinikKES: _klinikKESController.text,

          // 4. Riwayat
          riwayatPenyakitSekarang: _riwayatPenyakitSekarangController.text,
          riwayatPenyakitDahulu: _riwayatPenyakitDahuluController.text,
          alergiMakanan: _alergiMakananController.text,
          polaMakan: _polaMakanController.text,

          // 5. Diagnosa
          diagnosaGizi: _diagnosaGiziController.text,

          // 6. Intervensi
          intervensiDiet: _intervensiDietController.text,
          intervensiBentukMakanan: _intervensiBentukMakananController.text,
          intervensiVia: _intervensiViaController.text,
          intervensiTujuan: _intervensiTujuanController.text,

          // 7. Monev
          monevAsupan: _monevAsupanController.text,
        );

        if (mounted) {
          Navigator.of(context).pop(updatedPatientObj);
        }

      } on TimeoutException catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Mode Offline: Data disimpan lokal.'),
            backgroundColor: Colors.orange,
          ));
          // Tetap kembali meskipun offline (opsional)
          Navigator.of(context).pop();
        }
      } catch (e) {
        // Catch error selain timeout (misal permission error)
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
      firstDate: DateTime(DateTime.now().year - 18), // Maks 5 tahun lalu
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

 double _hitungBBIAnak(DateTime tanggalLahir) {
    final now = DateTime.now();

    // 1. Hitung selisih tahun dan bulan
    int years = now.year - tanggalLahir.year;
    int months = now.month - tanggalLahir.month;
    int days = now.day - tanggalLahir.day;

    // Koreksi jika bulan/hari belum genap
    if (days < 0) {
      months--;
    }
    if (months < 0) {
      years--;
      months += 12;
    }

    double bbi = 0.0;

    // --- LOGIKA PERHITUNGAN BERDASARKAN USIA ---

    // KATEGORI 1: Usia 0 - 11 Bulan
    // Rumus: (n + 9) / 2
    // n dalam bulan
    if (years == 0) {
      // Menggunakan bulan yang sudah berjalan (completed months)
      double n = months.toDouble(); 
      // Opsi alternatif: double n = months + (days / 30.0); jika ingin desimal
      
      bbi = (n + 9) / 2;
    }
    
    // KATEGORI 2: Usia 1 - 6 Tahun (Rumus Behrman)
    // Rumus: 2n + 8
    // n dalam tahun (gunakan desimal untuk presisi, misal 1 tahun 6 bulan = 1.5)
    else if (years >= 1 && years <= 6) {
      double n = years + (months / 12.0);
      bbi = (2 * n) + 8;
    }
    
    // KATEGORI 3: Usia 7 - 12 Tahun
    // Rumus: (7n - 5) / 2
    // n dalam tahun
    else if (years >= 7 && years <= 12) {
      double n = years + (months / 12.0);
      bbi = ((7 * n) - 5) / 2;
    }
    
    // KATEGORI 4: Usia > 12 Tahun (Rumus Broca)
    // Rumus: (TB - 100) - (TB - 100) * 10% (atau 15% untuk wanita)
    else {
      // Mengambil data Tinggi Badan dari controller
      double tb = double.tryParse(_tinggiBadanController.text) ?? 0;

      if (tb > 0) {
        // Cek Jenis Kelamin
        bool isPerempuan = _jenisKelaminController.text.toLowerCase().contains('perempuan') || 
                           _jenisKelaminController.text.toLowerCase().contains('wanita');

        // --- MODIFIKASI BROCA ---
        // Jika Wanita < 150 cm ATAU Pria < 160 cm
        // Rumus: (TB - 100) * 1
        if ((isPerempuan && tb < 150) || (!isPerempuan && tb < 160)) {
           bbi = (tb - 100) * 1.0;
        } 
        // --- BROCA STANDAR ---
        // Jika Tinggi Badan Normal/Tinggi
        // Wanita: (TB-100) - 15%
        // Pria: (TB-100) - 10%
        else {
           double percentage = isPerempuan ? 0.15 : 0.10;
           bbi = (tb - 100) - ((tb - 100) * percentage);
        }
      } else {
        // Fallback jika TB belum diisi, kembalikan 0
        return 0.0;
      }
    }

    // Pembulatan 2 angka di belakang koma
    return double.parse(bbi.toStringAsFixed(2));
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithAnimatedFab(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: CustomAppBar(
        title: widget.patient != null ? 'Edit Data Anak' : 'Tambah Pasien Anak',
        subtitle: 'Isi data dengan lengkap',
      ),
      floatingActionButton: FormActionButtons(
        onReset: _resetForm,
        onSubmit: _savePatientAnakData,
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
                    'Input Data Pasien Anak',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildTextFormField(
                    controller: _noRMController,
                    label: 'No. Rekam Medis (RM)',
                    focusNode: _focusNodes[0],
                    prefixIcon: const Icon(Icons.medical_information),
                    maxLength: 20,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _namaLengkapController,
                    label: 'Nama Lengkap',
                    focusNode: _focusNodes[1],
                    prefixIcon: const Icon(Icons.person),
                    maxLength: 100,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _tanggalLahirController,
                    label: 'Tanggal Lahir',
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    focusNode: _focusNodes[2],
                    prefixIcon: const Icon(Icons.calendar_today),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildCustomDropdown(
                    controller: _jenisKelaminController,
                    label: 'Jenis Kelamin',
                    items: ['Laki-laki', 'Perempuan'],
                    prefixIcon: const Icon(Icons.wc),
                    focusNode: _focusNodes[3],
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Harus dipilih'
                        : null,
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
                    label: 'Berat Badan',
                    focusNode: _focusNodes[5],
                    prefixIcon: const Icon(Icons.monitor_weight),
                    suffixText: 'kg',
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _tinggiBadanController,
                    label: 'Panjang/Tinggi Badan',
                    focusNode: _focusNodes[6],
                    prefixIcon: const Icon(Icons.height),
                    suffixText: 'cm',
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _lilaController,
                    label: 'Lingkar Lengan Atas (LILA)',
                    focusNode: _focusNodes[7],
                    prefixIcon: const Icon(Icons.fitness_center),
                    suffixText: 'cm',
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: (v) => null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _lingkarKepalaController,
                    label: 'Lingkar Kepala (LK)',
                    focusNode: _focusNodes[8],
                    prefixIcon: const Icon(Icons.face),
                    suffixText: 'cm',
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: (v) => null,
                  ),
                  const SizedBox(height: 16),
                  _buildCustomDropdown(
                    controller: _kehilanganBeratBadanController,
                    label: 'Penurunan berat badan akhir-akhir ini?',
                    prefixIcon: const Icon(Icons.trending_down),
                    items: ['Ya', 'Tidak'],
                    focusNode: _focusNodes[9],
                  ),
                  const SizedBox(height: 16),

                  _buildCustomDropdown(
                    controller: _kehilanganNafsuMakanController,
                    label: 'Ada asupan makan dalam satu minggu terakhir?',
                    prefixIcon: const Icon(Icons.restaurant),
                    items: [
                      'Makan seperti biasa',
                      'Ada penurunan',
                      'Tidak makan sama sekali atau sangat sedikit',
                    ],
                    focusNode: _focusNodes[10],
                  ),
                  const SizedBox(height: 16),

                  _buildCustomDropdown(
                    controller: _anakSakitBeratController,
                    label: 'Anak sakit berat?',
                    prefixIcon: const Icon(Icons.local_hospital),
                    items: ['Ya', 'Tidak'],
                    focusNode: _focusNodes[11],
                  ),
                  const SizedBox(height: 16),

                  _buildTextFormField(
                    controller: _namaNutrisionisController,
                    label: 'Nama Nutrisionis',
                    focusNode: _focusNodes[12],
                    prefixIcon: const Icon(Icons.person),
                    validator: (value) => null,
                    maxLength: 100,
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Input Data Asuhan Gizi (Opsional)',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  _buildSectionHeader('Riwayat Gizi & Personal'),
                  
                  _buildCustomDropdown(
                    controller: _alergiMakananController, // Gunakan controller ini untuk trigger
                    label: 'Apakah anak memiliki alergi makanan?',
                    prefixIcon: const Icon(Icons.no_food),
                    items: ['Ya', 'Tidak'],
                    focusNode: _focusNodes[13], // Pastikan index focus node sesuai
                    onChanged: (val) {
                      setState(() {
                        _alergiMakananController.text = val ?? 'Tidak';
                        // Opsional: Reset checkbox jika memilih "Tidak"
                        if (val == 'Tidak') {
                          _alergiTelur = false;
                          _alergiSusu = false;
                          _alergiKacang = false;
                          _alergiGluten = false;
                          _alergiUdang = false;
                          _alergiIkan = false;
                          _alergiHazelnut = false;
                          _alergiLainnyaController.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_alergiMakananController.text == 'Ya') ...[
                    const Text(
                      'Pilih jenis alergi yang sesuai:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    CheckboxListTile(
                      title: const Text("Telur"),
                      value: _alergiTelur,
                      onChanged: (val) => setState(() => _alergiTelur = val!),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                    CheckboxListTile(
                      title: const Text("Susu Sapi"),
                      value: _alergiSusu,
                      onChanged: (val) => setState(() => _alergiSusu = val!),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                    CheckboxListTile(
                      title: const Text("Kacang Kedelai/Tanah"),
                      value: _alergiKacang,
                      onChanged: (val) => setState(() => _alergiKacang = val!),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                    CheckboxListTile(
                      title: const Text("Gluten/Gandum"),
                      value: _alergiGluten,
                      onChanged: (val) => setState(() => _alergiGluten = val!),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                    CheckboxListTile(
                      title: const Text("Udang"),
                      value: _alergiUdang,
                      onChanged: (val) => setState(() => _alergiUdang = val!),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                    CheckboxListTile(
                      title: const Text("Ikan"),
                      value: _alergiIkan,
                      onChanged: (val) => setState(() => _alergiIkan = val!),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                    CheckboxListTile(
                      title: const Text("Hazelnut/Almond"),
                      value: _alergiHazelnut, // Pastikan variabel ini benar
                      onChanged: (val) => setState(() => _alergiHazelnut = val!),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                    
                    // Input Lainnya
                    _buildTextFormField(
                      controller: _alergiLainnyaController,
                      label: 'Alergi Lainnya (jika ada)',
                      focusNode: FocusNode(), 
                      prefixIcon: const Icon(Icons.edit_note),
                    ),
                  ],

                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _polaMakanController,
                    label: 'Pola Makan / Asupan',
                    prefixIcon: const Icon(Icons.restaurant_menu),
                    focusNode: _focusNodes[14],
                    validator: (v) => null,
                    maxLength: 20,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _riwayatPenyakitSekarangController,
                    label: 'Riwayat Penyakit Sekarang (RPS)',
                    prefixIcon: const Icon(Icons.history_edu),
                    focusNode: _focusNodes[15],
                    validator: (v) => null,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _riwayatPenyakitDahuluController,
                    label: 'Riwayat Penyakit Dahulu (RPD)',
                    prefixIcon: const Icon(Icons.history),
                    focusNode: _focusNodes[16],
                    validator: (v) => null,
                    maxLength: 500,
                  ),

                  // 2. Biokimia
                  _buildSectionHeader('Biokimia/BD'),
                  
                  _buildTextFormField(
                    controller: _biokimiaGDSController,
                    label: 'GDS',
                    prefixIcon: const Icon(Icons.science),
                    suffixText: 'mg/dl',
                    keyboardType: TextInputType.number,
                    focusNode: _focusNodes[17],
                    validator: (v) => null,
                    maxLength: 8,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _biokimiaUreumController,
                    label: 'Ureum',
                    prefixIcon: const Icon(Icons.science),
                    suffixText: 'mg/dl',
                    keyboardType: TextInputType.number,
                    focusNode: _focusNodes[18],
                    validator: (v) => null,
                    maxLength: 8,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _biokimiaHGBController,
                    label: 'HGB',
                    prefixIcon: const Icon(Icons.science),
                    keyboardType: TextInputType.number,
                    focusNode: _focusNodes[19],
                    validator: (v) => null,
                    maxLength: 8,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _biokimiaENTController,
                    label: 'ENT',
                    prefixIcon: const Icon(Icons.science),
                    keyboardType: TextInputType.number,
                    focusNode: _focusNodes[20],
                    validator: (v) => null,
                    maxLength: 8,
                  ),

                  // 3. Klinik / Fisik
                  _buildSectionHeader('Klinik/Fisik/PD'),

                  _buildTextFormField(
                    controller: _klinikTDController,
                    label: 'Tekanan Darah (TD)',
                    prefixIcon: const Icon(Icons.favorite),
                    suffixText: 'mmHg',
                    keyboardType: TextInputType.number,
                    focusNode: _focusNodes[21],
                    validator: (v) => null,
                    maxLength: 8,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _klinikNadiController,
                    label: 'Nadi (N)',
                    prefixIcon: const Icon(Icons.monitor_heart),
                    suffixText: 'x/menit',
                    keyboardType: TextInputType.number,
                    focusNode: _focusNodes[22],
                    validator: (v) => null,
                    maxLength: 4,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _klinikSuhuController,
                    label: 'Suhu Badan (SB)',
                    prefixIcon: const Icon(Icons.thermostat),
                    suffixText: '°C',
                    keyboardType: TextInputType.number,
                    focusNode: _focusNodes[23],
                    validator: (v) => null,
                    maxLength: 4,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _klinikRRController,
                    label: 'Respirasi (R)',
                    prefixIcon: const Icon(Icons.air),
                    suffixText: 'x/menit',
                    keyboardType: TextInputType.number,
                    focusNode: _focusNodes[24],
                    validator: (v) => null,
                    maxLength: 4,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _klinikSPO2Controller,
                    label: 'Saturasi Oksigen (SpO2)',
                    prefixIcon: const Icon(Icons.air),
                    suffixText: '%',
                    keyboardType: TextInputType.number,
                    focusNode: _focusNodes[25],
                    validator: (v) => null,
                    maxLength: 4,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _klinikKUController,
                    label: 'Keadaan Umum (KU)',
                    prefixIcon: const Icon(Icons.accessibility_new),
                    focusNode: _focusNodes[26],
                    validator: (v) => null,
                    maxLength: 20,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _klinikKESController,
                    label: 'Kesadaran (KES)',
                    prefixIcon: const Icon(Icons.psychology),
                    focusNode: _focusNodes[27],
                    validator: (v) => null,
                    maxLength: 20,
                  ),

                  // 4. Diagnosa Gizi
                  _buildSectionHeader('Diagnosa Gizi'),

                  _buildTextFormField(
                    controller: _diagnosaGiziController,
                    label: 'Diagnosa Gizi',
                    prefixIcon: const Icon(Icons.medical_services),
                    focusNode: _focusNodes[28],
                    validator: (v) => null,
                    maxLength: 500,
                  ),

                  _buildSectionHeader('Intervensi Gizi'),

                  _buildTextFormField(
                    controller: _intervensiDietController,
                    label: 'Jenis Diet',
                    prefixIcon: const Icon(Icons.food_bank),
                    focusNode: _focusNodes[29],
                    maxLength: 200,
                    validator: (v) => null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _intervensiBentukMakananController,
                    label: 'Bentuk Makanan (BM)',
                    prefixIcon: const Icon(Icons.rice_bowl),
                    focusNode: _focusNodes[30],
                    maxLength: 200,
                    validator: (v) => null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _intervensiTujuanController,
                    label: 'Tujuan Diet',
                    prefixIcon: const Icon(Icons.flag),
                    focusNode: _focusNodes[31],
                    maxLength: 500,
                    validator: (v) => null,
                  ),
                  const SizedBox(height: 16),
                  _buildCustomDropdown(
                    controller: _intervensiViaController,
                    label: 'Via',
                    prefixIcon: const Icon(Icons.route),
                    items: ['Oral', 'Enteral', 'Parenteral'],
                    focusNode: _focusNodes[32],
                    validator: (v) => null,
                  ),

                  // 6. Monev
                  _buildSectionHeader('Monitoring & Evaluasi'),
                  _buildTextFormField(
                    controller: _monevAsupanController,
                    label: 'Asupan Makanan',
                    prefixIcon: const Icon(Icons.analytics),
                    focusNode: _focusNodes[33],
                    maxLength: 500,
                    validator: (v) => null,
                  ),
                  const SizedBox(height: 32),
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
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
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
    //bool showSearch = false,
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
