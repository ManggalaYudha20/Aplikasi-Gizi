//lib\src\features\nutrition_calculation\presentation\pages\bbi_form_page.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/services.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/patient_picker_widget.dart';

class BbiFormPage extends StatefulWidget {
  const BbiFormPage({super.key});

  @override
  State<BbiFormPage> createState() => _BbiFormPageState();
}

class _BbiFormPageState extends State<BbiFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultCardKey = GlobalKey();
  final _genderController = TextEditingController();
  double? _bbiResult;
  final GlobalKey<PatientPickerWidgetState> _patientPickerKey = GlobalKey();

  @override
  void dispose() {
    _heightController.dispose();
    _scrollController.dispose();
    _genderController.dispose();
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
      final height = double.parse(_heightController.text);

      double bbi;

      if (_genderController.text == 'Laki-laki') {
        // Formula untuk laki-laki: [tinggi badan (cm) - 100] - [(tinggi badan (cm) - 100) × 10%]
        bbi = (height - 100) - ((height - 100) * 0.10);
      } else {
        // Formula untuk perempuan: [tinggi badan (cm) - 100] - [(tinggi badan (cm) - 100) × 15%]
        bbi = (height - 100) - ((height - 100) * 0.15);
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
      _heightController.clear();
      _genderController.clear();
      _bbiResult = null;
      _patientPickerKey.currentState?.resetSelection();
    });
  }

  void _fillDataFromPatient(double weight, double height, String gender, DateTime dob) {
    setState(() {
      _heightController.text = height.toString();
      String incomingGender = gender.toLowerCase();
      String normalizedGender = '';

      // Cek variasi penulisan Laki-laki
      if (incomingGender.contains('laki') || incomingGender.contains('pria') || incomingGender == 'l') {
        normalizedGender = 'Laki-laki';
      } 
      // Cek variasi penulisan Perempuan
      else if (incomingGender.contains('perempuan') || incomingGender.contains('wanita') || incomingGender == 'p') {
        normalizedGender = 'Perempuan';
      } 
      // Jika tidak dikenali, gunakan data asli (mungkin user harus pilih manual)
      else {
        normalizedGender = gender; 
      }
      _genderController.text = normalizedGender;
      
      // Reset hasil perhitungan
      _bbiResult = null;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: const CustomAppBar(title: 'BBI', subtitle: 'Berat Badan Ideal'),
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
                ),
                
                const SizedBox(height: 10), // Sedikit jarak
                const Divider(),
                const SizedBox(height: 20),
                const Text(
                  'Input Data BBI',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Tinggi Badan
                _buildTextFormField(
                  controller: _heightController,
                  label: 'Tinggi Badan',
                  prefixIcon: const Icon(Icons.height),
                  suffixText: 'cm',
                ),
                const SizedBox(height: 16),

                // Jenis Kelamin
                _buildCustomDropdown(
                  controller: _genderController,
                  label: 'Jenis Kelamin',
                  prefixIcon: const Icon(Icons.wc),
                  items: ['Laki-laki', 'Perempuan'],
                ),
                const SizedBox(height: 32),

                // Buttons
                FormActionButtons(
                  onReset: _resetForm,
                  onSubmit: _calculateBBI,
                  resetButtonColor: Colors.white, // Background jadi putih
                  resetForegroundColor: const Color.fromARGB(255, 0, 148, 68),
                  submitIcon: const Icon(Icons.calculate, color: Colors.white),
                ),
                const SizedBox(height: 32),

                // Result
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
                      color: const Color.fromARGB(
                        255,
                        0,
                        148,
                        68,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color.fromARGB(255, 0, 148, 68),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Hasil Perhitungan BBI',
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
                        const Text(
                          'Berat Badan Ideal (BBI) adalah berat badan yang dianggap optimal untuk tinggi badan dan jenis kelamin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black54),
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

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required Icon prefixIcon,
    required String suffixText,
    int maxLength = 5,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        // Batasi panjang karakter agar tidak overflow/error database
        LengthLimitingTextInputFormatter(maxLength),
        // Opsional: Filter agar hanya angka dan titik (untuk desimal) yang bisa diketik
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
          return '$label tidak boleh kosong';
        }
        if (double.tryParse(value) == null) {
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
  }) {
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(showSearchBox: false, fit: FlexFit.loose),
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
