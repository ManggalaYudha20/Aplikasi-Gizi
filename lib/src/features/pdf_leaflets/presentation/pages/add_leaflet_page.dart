// lib\src\features\pdf_leaflets\presentation\pages\add_leaflet_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/leaflet_list_model.dart';

class AddLeafletPage extends StatefulWidget {
  final Leaflet? leaflet;

  const AddLeafletPage({
    super.key,
    this.leaflet,
  });

  @override
  State<AddLeafletPage> createState() => _AddLeafletPageState();
}

class _AddLeafletPageState extends State<AddLeafletPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _urlController;
  
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.leaflet != null;
    
    _titleController = TextEditingController(text: widget.leaflet?.title ?? '');
    _descriptionController = TextEditingController(text: widget.leaflet?.description ?? '');
    _urlController = TextEditingController(text: widget.leaflet?.url ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _submitLeaflet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Logic convert Google Drive link (tetap dipertahankan sesuai aslinya)
      String processedUrl = _urlController.text.trim();
      if (processedUrl.contains('drive.google.com') && processedUrl.contains('/view')) {
        processedUrl = processedUrl.replaceAll('/view', '/preview');
      }

      final leafletData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'url': processedUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEditing) {
        await FirebaseFirestore.instance
            .collection('leaflets')
            .doc(widget.leaflet!.id)
            .update(leafletData);
      } else {
        leafletData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('leaflets').add(leafletData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Data berhasil diperbarui!' : 'Leaflet berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _urlController.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive Dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final paddingValue = screenWidth * 0.04;
    final spacerSmall = SizedBox(height: screenWidth * 0.04);
    final spacerMedium = SizedBox(height: screenWidth * 0.08);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(title: _isEditing ? 'Edit Leaflet' : 'Tambah Leaflet', subtitle:'Lengkapi Data Leaflet dibawah'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(paddingValue),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(
                  key: const Key('leaflet_title_input'),
                  controller: _titleController,
                  label: 'Judul Leaflet',
                  icon: Icons.title,
                  maxLines: 3,
                ),
                spacerSmall,
                _buildTextField(
                  key: const Key('leaflet_desc_input'),
                  controller: _descriptionController,
                  label: 'Deskripsi',
                  icon: Icons.description,
                  maxLines: 3,
                ),
                spacerSmall,
                _buildTextField(
                  key: const Key('leaflet_url_input'),
                  controller: _urlController,
                  label: 'URL PDF',
                  hint: 'Link Google Drive akan otomatis diubah ke format preview',
                  icon: Icons.link,
                  isUrl: true,
                  maxLines: 3,
                ),
                spacerMedium,
                Semantics(
                  label: _isEditing ? 'Tombol simpan perubahan' : 'Tombol tambah leaflet',
                  button: true,
                  child: FormActionButtons(
                    // Key pada FormActionButtons mungkin perlu diteruskan ke dalam widget jika custom, 
                    // tapi wrapper semantics sudah membantu.
                    onReset: _resetForm,
                    resetButtonColor: Colors.white,
                    resetForegroundColor: const Color.fromARGB(255, 0, 148, 68),
                    onSubmit: _isLoading ? () {} : _submitLeaflet,
                    submitText: _isEditing ? 'Simpan' : 'Tambah',
                    submitIcon: _isEditing 
                        ? const Icon(Icons.save, color: Colors.white) 
                        : const Icon(Icons.add, color: Colors.white, key: Key('submit_icon')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required Key key,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    bool isUrl = false,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label tidak boleh kosong';
        }
        if (isUrl && !Uri.parse(value).isAbsolute) {
          return 'Masukkan URL yang valid';
        }
        return null;
      },
    );
  }
}