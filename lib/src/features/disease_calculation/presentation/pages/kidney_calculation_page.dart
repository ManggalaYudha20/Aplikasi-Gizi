// lib/src/features/disease_calculation/presentation/pages/kidney_calculation_page.dart

import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/kidney_calculator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:flutter/material.dart';

class KidneyCalculationPage extends StatefulWidget {
  const KidneyCalculationPage({super.key});

  @override
  State<KidneyCalculationPage> createState() => _KidneyCalculationPageState();
}

class _KidneyCalculationPageState extends State<KidneyCalculationPage> {
  final _formKey = GlobalKey<FormState>();
  final _calculatorService = KidneyCalculatorService();

  // Controllers
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  final _scrollController = ScrollController();
  final _resultCardKey = GlobalKey();

  // Form fields state
  bool? _isDialysis;
  String? _gender;
  double? _selectedProteinFactor = 0.6;
  KidneyDietResult? _result;

  @override
  void dispose() {
    _heightController.dispose();
    _ageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _calculateKidneyDiet() {
    if (_formKey.currentState!.validate()) {
      final height = double.tryParse(_heightController.text) ?? 0;
      final age = int.tryParse(_ageController.text) ?? 0;

      final result = _calculatorService.calculate(
        height: height,
        isDialysis: _isDialysis!,
        gender: _gender!,
        proteinFactor: _isDialysis! ? null : _selectedProteinFactor,
        age: age,
      );

      setState(() {
        _result = result;
      });

      _scrollToResult();
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _heightController.clear();
    _ageController.clear();
    setState(() {
      _isDialysis = null;
      _gender = null;
      _selectedProteinFactor = 0.6;
      _result = null;
    });
  }

  void _scrollToResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_resultCardKey.currentContext != null) {
        Scrollable.ensureVisible(
          _resultCardKey.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Diet Ginjal',
        subtitle: 'Kalkulator Kebutuhan Protein',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Input Data Pasien Ginjal',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                // Pertanyaan Kunci: Status Dialisis
                DropdownButtonFormField<bool>(
                  value: _isDialysis,
                  decoration: const InputDecoration(
                    labelText: 'Apakah Pasien menjalani cuci darah?',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.bloodtype_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Ya')),
                    DropdownMenuItem(value: false, child: Text('Tidak')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _isDialysis = value;
                      // Jika memilih 'Tidak', pastikan faktor protein punya nilai default
                      if (value == false) {
                        _selectedProteinFactor ??= 0.6;
                      }
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Pilih status cuci darah' : null,
                ),
                const SizedBox(height: 16),

                // -- FORM OPSI PROTEIN DINAMIS --
                // Muncul hanya jika pasien TIDAK menjalani cuci darah
                if (_isDialysis == false)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: DropdownButtonFormField<double>(
                      value: _selectedProteinFactor,
                      decoration: const InputDecoration(
                        labelText: 'Faktor Kebutuhan Protein',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.rule),
                      ),
                      items: const [
                        DropdownMenuItem(value: 0.6, child: Text('0.6 (Rendah)')),
                        DropdownMenuItem(value: 0.7, child: Text('0.7 (Sedang)')),
                        DropdownMenuItem(value: 0.8, child: Text('0.8 (Tinggi)')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedProteinFactor = value;
                        });
                      },
                      validator: (value) => value == null ? 'Pilih faktor protein' : null,
                    ),
                  ),
                // New: Gender Selection
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Kelamin',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
                    DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
                  ],
                  onChanged: (value) => setState(() => _gender = value),
                  validator: (value) => value == null ? 'Pilih jenis kelamin' : null,
                ),
                const SizedBox(height: 16),
                // Input Tinggi Badan
                TextFormField(
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: 'Tinggi Badan',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.height),
                    suffixText: 'cm',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan tinggi badan';
                    }
                    final height = double.tryParse(value);
                    if (height == null || height <= 0) {
                      return 'Masukkan tinggi badan yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // New: Usia Input
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(
                    labelText: 'Usia',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                    suffixText: 'tahun',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan usia';
                    }
                    final age = int.tryParse(value);
                    if (age == null || age <= 0) {
                      return 'Masukkan usia yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                // Tombol Aksi
                FormActionButtons(
                  onReset: _resetForm,
                  onSubmit: _calculateKidneyDiet,
                ),
                const SizedBox(height: 32),
                // Tampilan Hasil
                if (_result != null) _buildResultCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

 // Salin dan ganti seluruh method _buildResultCard() yang ada dengan kode ini
Widget _buildResultCard() {
    // Membuat variabel untuk teks rekomendasi diet secara dinamis.
    final String recommendationText = _result!.isDialysis
        ? 'Diet Hemodialisis (HD)\nprotein ${_result!.recommendedDiet} gram'
        : 'Diet Protein Rendah ${_result!.recommendedDiet} gram';

    // Membuat variabel untuk teks penjelasan faktor protein secara dinamis.
    final String factorExplanationText = _result!.isDialysis
        ? '*Pasien hemodialisis membutuhkan asupan protein lebih tinggi (1.2 g/kg BBI).'
        : '*Pasien pre-dialisis membutuhkan asupan protein lebih rendah (${_selectedProteinFactor}g/kg BBI) untuk memperlambat laju penyakit.';

    return Container(
      key: _resultCardKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 0, 148, 68).withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color.fromARGB(255, 0, 148, 68)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Hasil Perhitungan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 0, 148, 68),
            ),
          ),
          const Divider(height: 24),
          _buildInfoRow(
            'Berat Badan Ideal (BBI)',
            '${_result!.idealBodyWeight.toStringAsFixed(1)} kg',
          ),
          _buildInfoRow(
            'Kebutuhan Protein Harian',
            '${_result!.proteinNeeds.toStringAsFixed(1)} gram',
          ),
          // Pastikan untuk hanya menampilkan BMR jika nilainya ada di _result
          if (_result!.bmr > 0)
            _buildInfoRow(
              'BMR',
              '${_result!.bmr.toStringAsFixed(1)} kkal/hari',
            ),
          const SizedBox(height: 16),
          const Text(
            'Rekomendasi Diet:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 0, 148, 68),
              borderRadius: BorderRadius.circular(8),
            ),
            // Menggunakan variabel recommendationText yang sudah dinamis
            child: Text(
              recommendationText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Menggunakan variabel factorExplanationText yang sudah dinamis
          Text(
            factorExplanationText,
            style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.black54),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}