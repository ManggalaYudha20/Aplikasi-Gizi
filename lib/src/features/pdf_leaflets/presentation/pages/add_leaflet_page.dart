//lib\src\features\pdf_leaflets\presentation\pages\add_leaflet_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/leaflet_list_model.dart';

class AddLeafletPage extends StatefulWidget {
  final Leaflet? leaflet; // Optional parameter for editing

  const AddLeafletPage({
    super.key,
    this.leaflet, // Pass existing leaflet for editing
  });

  @override
  State<AddLeafletPage> createState() => _AddLeafletPageState();
}

class _AddLeafletPageState extends State<AddLeafletPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    // Check if we're in edit mode
    if (widget.leaflet != null) {
      _isEditing = true;
      _titleController.text = widget.leaflet!.title;
      _descriptionController.text = widget.leaflet!.description;
      _urlController.text = widget.leaflet!.url;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  String _transformGoogleDriveUrl(String url) {
    // Cek apakah URL adalah Google Drive sharing link
    if (url.contains('drive.google.com/file/d/') && url.contains('/view')) {
      // Ekstrak FILE_ID dari URL sharing
      final regex = RegExp(r'/file/d/([^/]+)');
      final match = regex.firstMatch(url);

      if (match != null) {
        final fileId = match.group(1);
        // Ubah ke format direct download
        return 'https://drive.google.com/uc?export=download&id=$fileId';
      }
    }

    // Jika bukan Google Drive sharing link, kembalikan URL asli
    return url;
  }

  Future<void> _submitLeaflet() async {
    // Validasi form terlebih dahulu
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Transform Google Drive URL jika perlu
        final transformedUrl = _transformGoogleDriveUrl(_urlController.text);

        if (_isEditing) {
          // Update existing leaflet
          await FirebaseFirestore.instance
              .collection('leaflets')
              .doc(widget.leaflet!.id)
              .update({
                'title': _titleController.text,
                'description': _descriptionController.text,
                'url': transformedUrl,
              });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Leaflet berhasil diperbarui!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // Add new leaflet
          await FirebaseFirestore.instance.collection('leaflets').add({
            'title': _titleController.text,
            'description': _descriptionController.text,
            'url': transformedUrl,
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Leaflet berhasil ditambahkan!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? 'Gagal memperbarui leaflet: $e'
                    : 'Gagal menambahkan leaflet: $e',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    _urlController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: CustomAppBar(
        title: _isEditing ? 'Edit Leaflet' : 'Tambah Leaflet',
        subtitle: _isEditing
            ? 'Perbarui data leaflet di bawah'
            : 'Isi data leaflet di bawah',
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Leaflet',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Judul tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Singkat',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Deskripsi tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL PDF',
                  hintText:
                      'Link Google Drive akan otomatis diubah ke format download',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'URL tidak boleh kosong';
                  }
                  // Validasi sederhana untuk memastikan ini adalah URL
                  if (!Uri.parse(value).isAbsolute) {
                    return 'Masukkan URL yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              FormActionButtons(
                onReset: _resetForm,
                resetButtonColor: Colors.white, // Background jadi putih
                resetForegroundColor: const Color.fromARGB(255, 0, 148, 68),
                onSubmit: _isLoading ? () {} : _submitLeaflet,
                submitText: _isEditing ? 'Simpan' : 'Tambah',
                submitIcon: _isEditing ? const Icon(Icons.save, color: Colors.white) : const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }
}
