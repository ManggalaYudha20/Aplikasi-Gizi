// lib/src/features/disease_calculation/presentation/pages/kidney_calculation_page.dart

import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/kidney_calculator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/kidney_meal_planner_service.dart';
import 'package:dropdown_search/dropdown_search.dart';

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
  final _dialysisController = TextEditingController();
  final _genderController = TextEditingController();
  final _proteinFactorController = TextEditingController(text: '0.6 (Rendah)');
  KidneyDietResult? _result;

  @override
  void dispose() {
    _heightController.dispose();
    _ageController.dispose();
    _scrollController.dispose();
    _dialysisController.dispose();
    _genderController.dispose();
    _proteinFactorController.dispose();
    super.dispose();
  }

  void _calculateKidneyDiet() {
    if (_formKey.currentState!.validate()) {
      final height = double.tryParse(_heightController.text) ?? 0;
      final age = int.tryParse(_ageController.text) ?? 0;
      // Ubah nilai string dari controller menjadi tipe data yang benar
      final isDialysis = _dialysisController.text == 'Ya';
      final gender = _genderController.text;

      // Ambil angka dari string faktor protein
      final proteinFactorString = _proteinFactorController.text.split(' ')[0];
      final proteinFactor = double.tryParse(proteinFactorString);

      final result = _calculatorService.calculate(
        height: height,
        isDialysis: isDialysis,
        gender: gender,
        proteinFactor: isDialysis ? null : proteinFactor,
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
      _dialysisController.clear();
      _genderController.clear();
      _proteinFactorController.text = '0.6 (Rendah)';
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
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
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

                  // Dropdown Status Dialisis
                  _buildCustomDropdown<String>(
                    controller: _dialysisController,
                    label: 'Apakah Pasien menjalani cuci darah?',
                    prefixIcon: const Icon(Icons.bloodtype_outlined),
                    items: ['Ya', 'Tidak'],
                    itemAsString: (item) => item,
                    onChanged: (value) {
                      setState(() {
                        _dialysisController.text = value ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Dropdown Faktor Protein (kondisional)
                  if (_dialysisController.text == 'Tidak')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildCustomDropdown<String>(
                        controller: _proteinFactorController,
                        label: 'Faktor Kebutuhan Protein',
                        prefixIcon: const Icon(Icons.rule),
                        items: ['0.6 (Rendah)', '0.7 (Sedang)', '0.8 (Tinggi)'],
                        itemAsString: (item) => item,
                        onChanged: (value) {
                          setState(() {
                            _proteinFactorController.text =
                                value ?? '0.6 (Rendah)';
                          });
                        },
                      ),
                    ),
                  // Dropdown Jenis Kelamin
                  _buildCustomDropdown<String>(
                    controller: _genderController,
                    label: 'Jenis Kelamin',
                    prefixIcon: const Icon(Icons.person),
                    items: ['Laki-laki', 'Perempuan'],
                    itemAsString: (item) => item,
                    onChanged: (value) {
                      setState(() {
                        _genderController.text = value ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Input Tinggi Badan
                  _buildTextFormField(
                    controller: _heightController,
                    label: 'Tinggi Badan',
                    prefixIcon: const Icon(Icons.height),
                    suffixText: 'cm',
                  ),
                  const SizedBox(height: 16),

                  // Input Usia
                  _buildTextFormField(
                    controller: _ageController,
                    label: 'Usia',
                    prefixIcon: const Icon(Icons.calendar_today),
                    suffixText: 'tahun',
                  ),
                  const SizedBox(height: 32),

                  // Tombol Aksi
                  FormActionButtons(
                    onReset: _resetForm,
                    onSubmit: _calculateKidneyDiet,
                    resetButtonColor: Colors.white, // Background jadi putih
                    resetForegroundColor: const Color.fromARGB(255, 0, 148, 68),
                    submitIcon: const Icon(
                      Icons.calculate,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Tampilan Hasil
                  if (_result != null) ...[
                    const Divider(height: 32),
                    const SizedBox(height: 25),
                    _buildResultCard(),
                    const SizedBox(height: 25),
                    ExpansionTile(
                      title: Text(
                        'Asupan Gizi per Hari (Diet Protein ${_result!.recommendedDiet}g)',
                      ),
                      children: [
                        if (_result!.nutritionInfo != null)
                        const SizedBox(height: 10),
                        _buildNutritionCard(_result!.nutritionInfo!),
                        const SizedBox(height: 10),
                      ],
                    ),
                    if (_mealPlan != null) ...[
                      ExpansionTile(
                        title: Text('Pembagian Makanan\nSehari (Diet Protein ${_result!.recommendedDiet}g)'),
                        children: [
                          const SizedBox(height: 10),
                          _buildMealPlanCard(_mealPlan!),
                        const SizedBox(height: 10),
                        ],
                      ),
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
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required Icon prefixIcon,
    required String suffixText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: prefixIcon,
        suffixText: suffixText,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return '$label tidak boleh kosong';
        if (double.tryParse(value) == null) return 'Masukkan angka yang valid';
        return null;
      },
    );
  }

  // Widget untuk Dropdown
  Widget _buildCustomDropdown<T>({
    required TextEditingController controller,
    required String label,
    required List<T> items,
    required Icon prefixIcon,
    required String Function(T) itemAsString,
    void Function(T?)? onChanged,
  }) {
    // --- PERBAIKAN LOGIKA DIMULAI DI SINI ---
    T? selectedItem;
    try {
      // Coba temukan item yang cocok dengan teks di controller
      selectedItem = items.firstWhere(
        (item) => itemAsString(item) == controller.text,
      );
    } catch (e) {
      // Jika tidak ada yang cocok (firstWhere error), biarkan selectedItem bernilai null
      selectedItem = null;
    }
    // --- PERBAIKAN LOGIKA SELESAI ---

    return DropdownSearch<T>(
      popupProps: const PopupProps.menu(
        showSearchBox: false,
        fit: FlexFit.loose,
      ),
      items: items,
      itemAsString: itemAsString,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: prefixIcon,
        ),
      ),
      onChanged: onChanged,
      // Gunakan variabel selectedItem yang sudah kita proses
      selectedItem: selectedItem,
      validator: (value) => (value == null && controller.text.isEmpty)
          ? '$label harus dipilih'
          : null,
    );
  }

  // Salin dan ganti seluruh method _buildResultCard() yang ada dengan kode ini
  Widget _buildResultCard() {
    final proteinFactorValue = _proteinFactorController.text.split(' ')[0];
    // Membuat variabel untuk teks rekomendasi diet secara dinamis.
    final String recommendationText = _result!.isDialysis
        ? 'Diet Hemodialisis (HD)\nProtein ${_result!.recommendedDiet} gram'
        : 'Diet Protein Rendah ${_result!.recommendedDiet} gram';

    // Membuat variabel untuk teks penjelasan faktor protein secara dinamis.
    final String factorExplanationText = _result!.isDialysis
        ? '*Pasien hemodialisis membutuhkan asupan protein lebih tinggi (1.2 g/kg BBI).'
        : '*Pasien pre-dialisis membutuhkan asupan protein lebih rendah (${proteinFactorValue}g/kg BBI) untuk memperlambat laju penyakit.';

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
