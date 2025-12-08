import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/services.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/patient_picker_widget.dart';

class BbiAnakFormPage extends StatefulWidget {
  final String userRole;

  const BbiAnakFormPage({
    super.key,
    required this.userRole,
  });

  @override
  State<BbiAnakFormPage> createState() => _BbiAnakFormPageState();
}

class _BbiAnakFormPageState extends State<BbiAnakFormPage> {
  final _formKey = GlobalKey<FormState>();
  // Mengganti heightController menjadi ageController karena rumus anak berbasis umur
  final _ageController = TextEditingController(); 
  final _categoryController = TextEditingController(); // Untuk memilih kategori umur
  
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultCardKey = GlobalKey();
  double? _bbiResult;
  final GlobalKey<PatientPickerWidgetState> _patientPickerKey = GlobalKey();

  // Daftar Kategori sesuai permintaan
  final List<String> _ageCategories = [
    '0 - 11 Bulan',
    '1 - 6 Tahun',
    '7 - 12 Tahun',
  ];

  @override
  void dispose() {
    _ageController.dispose();
    _categoryController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _calculateBBI() {
    if (_formKey.currentState!.validate()) {
      final double ageValue = double.parse(_ageController.text);
      final String category = _categoryController.text;
      
      double bbi = 0;

      // Implementasi Rumus BBI Anak
      if (category == '0 - 11 Bulan') {
        // Rumus: (Usia dalam bulan / 2) + 4
        bbi = (ageValue / 2) + 4;
      } else if (category == '1 - 6 Tahun') {
        // Rumus: (2 x Usia dalam tahun) + 8
        bbi = (2 * ageValue) + 8;
      } else if (category == '7 - 12 Tahun') {
        // Rumus: ((7 x Usia dalam tahun) - 5) / 2
        bbi = ((7 * ageValue) - 5) / 2;
      }

      setState(() {
        _bbiResult = bbi;
      });
      _scrollToResult();
    }
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _ageController.clear();
      _categoryController.clear();
      _bbiResult = null;
      _patientPickerKey.currentState?.resetSelection();
    });
  }

  // Modifikasi pengisian data otomatis dari pasien
  void _fillDataFromPatient(double weight, double height, String gender, DateTime dob) {
    final now = DateTime.now();
    
    // Hitung umur dalam bulan dan tahun
    int ageInYears = now.year - dob.year;
    int ageInMonths = (now.year - dob.year) * 12 + (now.month - dob.month);
    if (now.day < dob.day) {
      ageInMonths--;
      if (now.month <= dob.month) { // Koreksi tahun jika belum ulang tahun
         ageInYears--;
      }
    }
    if (ageInYears < 0) ageInYears = 0; // Safety check

    setState(() {
      _bbiResult = null; // Reset hasil sebelumnya

      // Logika penentuan kategori otomatis berdasarkan tanggal lahir
      if (ageInMonths < 12) {
        _categoryController.text = '0 - 11 Bulan';
        _ageController.text = ageInMonths.toString();
      } else if (ageInYears >= 1 && ageInYears <= 6) {
        _categoryController.text = '1 - 6 Tahun';
        _ageController.text = ageInYears.toString();
      } else if (ageInYears >= 7 && ageInYears <= 12) {
        _categoryController.text = '7 - 12 Tahun';
        _ageController.text = ageInYears.toString();
      } else {
        // Jika di luar range (misal > 12 tahun), kosongkan atau beri notifikasi visual
        // Di sini kita pilih reset agar user isi manual atau sadar ini untuk anak
        _categoryController.clear();
        _ageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Umur pasien di luar kategori anak (0-12 tahun)')),
        );
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      // Mengubah Judul AppBar
      appBar: const CustomAppBar(title: 'BBI Anak', subtitle: 'Berat Badan Ideal Anak'),
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PatientPickerWidget(
                  key: _patientPickerKey,
                  onPatientSelected: _fillDataFromPatient,
                  userRole: widget.userRole,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Input Data BBI Anak',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // 1. Pilih Kategori Umur
                _buildCustomDropdown(
                  controller: _categoryController,
                  label: 'Kategori Usia',
                  items: _ageCategories,
                  prefixIcon: const Icon(Icons.category),
                ),
                const SizedBox(height: 16),

                // 2. Input Usia (Angka)
                // Label input akan berubah dinamis tergantung kategori yang dipilih
                _buildTextFormField(
                  controller: _ageController,
                  label: _getAgeLabel(), 
                  prefixIcon: const Icon(Icons.cake),
                  suffixText: _getAgeSuffix(),
                ),
                
                const SizedBox(height: 32),

                // Buttons
                FormActionButtons(
                  onReset: _resetForm,
                  onSubmit: _calculateBBI,
                  resetButtonColor: Colors.white,
                  resetForegroundColor: const Color.fromARGB(255, 0, 148, 68),
                  submitIcon: const Icon(Icons.calculate, color: Colors.white),
                ),
                const SizedBox(height: 32),

                // Result Area
                if (_bbiResult != null) ...[
                  Container(
                    key: _resultCardKey,
                    child: const Column(
                      children: [Divider(), SizedBox(height: 32)],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255,0,148,68).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color.fromARGB(255, 0, 148, 68),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Hasil BBI Anak',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 148, 68),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_bbiResult!.toStringAsFixed(2)} kg',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 148, 68),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getFormulaDescription(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  // Helper untuk label dinamis
  String _getAgeLabel() {
    if (_categoryController.text == '0 - 11 Bulan') {
      return 'Usia (Bulan)';
    } else {
      return 'Usia (Tahun)';
    }
  }

  // Helper untuk suffix dinamis
  String _getAgeSuffix() {
    if (_categoryController.text == '0 - 11 Bulan') {
      return 'bln';
    } else {
      return 'thn';
    }
  }

  // Helper untuk deskripsi rumus yang dipakai
  String _getFormulaDescription() {
    if (_categoryController.text == '0 - 11 Bulan') {
      return 'Rumus: (Usia bulan / 2) + 4';
    } else if (_categoryController.text == '1 - 6 Tahun') {
      return 'Rumus: (2 x Usia tahun) + 8';
    } else if (_categoryController.text == '7 - 12 Tahun') {
      return 'Rumus: ((7 x Usia tahun) - 5) / 2';
    }
    return 'Berat Badan Ideal Anak';
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required Icon prefixIcon,
    required String suffixText,
    int maxLength = 3, // Max length dikurangi karena usia jarang > 3 digit
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        LengthLimitingTextInputFormatter(maxLength),
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: prefixIcon,
        suffixText: suffixText,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Usia tidak boleh kosong';
        }
        if (double.tryParse(value) == null) {
          return 'Masukkan angka valid';
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
  }) {
    return DropdownSearch<String>(
      popupProps: const PopupProps.menu(showSearchBox: false, fit: FlexFit.loose),
      items: items,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: prefixIcon,
        ),
      ),
      onChanged: (String? newValue) {
        setState(() {
          controller.text = newValue ?? '';
          // Reset nilai umur saat ganti kategori agar tidak rancu (misal 10 tahun tapi kategori bulan)
          _ageController.clear(); 
          _bbiResult = null;
        });
      },
      selectedItem: controller.text.isEmpty ? null : controller.text,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label harus dipilih';
        }
        return null;
      },
    );
  }
}