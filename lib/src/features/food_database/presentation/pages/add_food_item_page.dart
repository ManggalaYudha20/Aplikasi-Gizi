import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';

class AddFoodItemPage extends StatefulWidget {
  const AddFoodItemPage({super.key});

  @override
  State<AddFoodItemPage> createState() => _AddFoodItemPageState();
}

class _AddFoodItemPageState extends State<AddFoodItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _kodeController = TextEditingController();
  final _porsiGramController = TextEditingController();
  final _kaloriController = TextEditingController();
  final _proteinController = TextEditingController();
  final _lemakController = TextEditingController();
  final _seratController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _namaController.dispose();
    _kodeController.dispose();
    _porsiGramController.dispose();
    _kaloriController.dispose();
    _proteinController.dispose();
    _lemakController.dispose();
    _seratController.dispose();
    super.dispose();
  }

  Future<void> _submitFoodItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseFirestore.instance.collection('food_items').add({
          'nama': _namaController.text,
          'kode': _kodeController.text,
          'porsi_gram': num.tryParse(_porsiGramController.text) ?? 0,
          'kalori': num.tryParse(_kaloriController.text) ?? 0,
          'protein': num.tryParse(_proteinController.text) ?? 0,
          'lemak': num.tryParse(_lemakController.text) ?? 0,
          'serat': num.tryParse(_seratController.text) ?? 0,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data makanan berhasil ditambahkan!')),
        );
        Navigator.pop(context);

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan data: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _namaController.clear();
    _kodeController.clear();
    _porsiGramController.clear();
    _kaloriController.clear();
    _proteinController.clear();
    _lemakController.clear();
    _seratController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: const CustomAppBar(
        title: 'Tambah Data Makanan',
        subtitle: 'Isi detail bahan makanan',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
                const Text(
                  'Input Data Makanan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
              _buildTextFormField(controller: _namaController, label: 'Nama Makanan', icon: Icons.restaurant),
              _buildTextFormField(controller: _kodeController, label: 'Kode Makanan', icon: Icons.qr_code),
              _buildTextFormField(controller: _porsiGramController, label: 'Porsi (gram)', icon: Icons.scale, isNumber: true),
              _buildTextFormField(controller: _kaloriController, label: 'Kalori (kkal)', icon: Icons.local_fire_department, isNumber: true),
              _buildTextFormField(controller: _proteinController, label: 'Protein (g)', icon: Icons.egg, isNumber: true),
              _buildTextFormField(controller: _lemakController, label: 'Lemak (g)', icon: Icons.water_drop, isNumber: true),
              _buildTextFormField(controller: _seratController, label: 'Serat (g)', icon: Icons.grass, isNumber: true),
              const SizedBox(height: 32),
              FormActionButtons(
                onReset: _resetForm,
                onSubmit: _submitFoodItem,
                submitText: 'Tambah Data',
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon),
        ),
        keyboardType: isNumber ? TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label tidak boleh kosong';
          }
          if (isNumber && double.tryParse(value) == null) {
            return 'Masukkan angka yang valid';
          }
          return null;
        },
      ),
    );
  }
}
