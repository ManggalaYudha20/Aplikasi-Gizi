// lib/src/features/disease_calculation/presentation/pages/kidney_calculation_page.dart

import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/kidney_calculator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/kidney_meal_planner_service.dart';

class KidneyCalculationPage extends StatefulWidget {
  const KidneyCalculationPage({super.key});

  @override
  State<KidneyCalculationPage> createState() => _KidneyCalculationPageState();
}

class _KidneyCalculationPageState extends State<KidneyCalculationPage> {
  final _formKey = GlobalKey<FormState>();
  final _calculatorService = KidneyCalculatorService();
  List<FoodItem>? _mealPlan;

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

      final mealPlan = KidneyMealPlans.getPlan(result.recommendedDiet);

      setState(() {
        _result = result;
        _mealPlan = mealPlan;
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
      _mealPlan = null;
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
        title: 'Diet Ginjal Kronis',
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
                        DropdownMenuItem(
                          value: 0.6,
                          child: Text('0.6 (Rendah)'),
                        ),
                        DropdownMenuItem(
                          value: 0.7,
                          child: Text('0.7 (Sedang)'),
                        ),
                        DropdownMenuItem(
                          value: 0.8,
                          child: Text('0.8 (Tinggi)'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedProteinFactor = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Pilih faktor protein' : null,
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
                    DropdownMenuItem(
                      value: 'Laki-laki',
                      child: Text('Laki-laki'),
                    ),
                    DropdownMenuItem(
                      value: 'Perempuan',
                      child: Text('Perempuan'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _gender = value),
                  validator: (value) =>
                      value == null ? 'Pilih jenis kelamin' : null,
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
                  resetButtonColor: Colors.white, // Background jadi putih
                  resetForegroundColor: const Color.fromARGB(255, 0, 148, 68),
                  submitIcon: const Icon(Icons.calculate, color: Colors.white),
                ),
                const SizedBox(height: 32),
                // Tampilan Hasil
                if (_result != null) ...[
                  const Divider(height: 32),
                  const SizedBox(height: 32),
                  _buildResultCard(),
                  const SizedBox(height: 32),
                  if (_result!.nutritionInfo != null)
                    _buildNutritionCard(_result!.nutritionInfo!),
                  if (_mealPlan != null) ...[
                    const SizedBox(height: 32),
                    _buildMealPlanCard(_mealPlan!),
                  ],
                ] else if (_result != null)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Center(
                      child: Text(
                        'Data nilai gizi untuk diet ini tidak tersedia.',
                      ),
                    ),
                  ),
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
        ? 'Diet Hemodialisis (HD)\nProtein ${_result!.recommendedDiet} gram'
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
          // Pastikan untuk hanya menampilkan BMR jika nilainya ada di _result
          if (_result!.bmr > 0)
            _buildInfoRow(
              'BMR',
              '${_result!.bmr.toStringAsFixed(1)} kkal/hari',
            ),
          _buildInfoRow(
            'Kebutuhan Protein Harian',
            '${_result!.proteinNeeds.toStringAsFixed(1)} gram',
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
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // TAMBAHKAN WIDGET BARU INI (sekitar baris 350)

  Widget _buildNutritionCard(KidneyDietNutrition nutritionInfo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Asupan Gizi per Hari (Diet Protein ${_result!.recommendedDiet}g) ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const Divider(height: 24),
          const SizedBox(height: 12),
          _buildInfoRow('Energi', '${nutritionInfo.energi} kkal'),
          _buildInfoRow('Protein', '${nutritionInfo.protein} g'),
          _buildInfoRow('Lemak', '${nutritionInfo.lemak} g'),
          _buildInfoRow('Karbohidrat', '${nutritionInfo.karbohidrat} g'),
          _buildInfoRow('Kalsium', '${nutritionInfo.kalsium} mg'),
          _buildInfoRow('Zat Besi', '${nutritionInfo.zatBesi} mg'),
          _buildInfoRow('Fosfor', '${nutritionInfo.fosfor} mg'),
          _buildInfoRow('Vitamin A', '${nutritionInfo.vitaminA} RE'),
          _buildInfoRow('Tiamin', '${nutritionInfo.tiamin} mg'),
          _buildInfoRow('Vitamin C', '${nutritionInfo.vitaminC} mg'),
          _buildInfoRow('Natrium', '${nutritionInfo.natrium} mg'),
          _buildInfoRow('Kalium', '${nutritionInfo.kalium} mg'),
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

  // Letakkan method ini di dalam kelas _KidneyCalculationPageState

  Widget _buildMealPlanCard(List<FoodItem> mealPlan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pembagian Makanan Sehari\n(Diet Protein ${_result!.recommendedDiet}g)',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const Divider(height: 24),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(3),
            },
            border: TableBorder.all(color: Colors.purple.shade100, width: 1),
            children: [
              // Table Header
              const TableRow(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 196, 86, 216),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Bahan Makanan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Berat (g)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'URT',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              // Table Rows from data
              ...mealPlan.map((item) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(item.name),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        item.weight.toString(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(item.urt),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
