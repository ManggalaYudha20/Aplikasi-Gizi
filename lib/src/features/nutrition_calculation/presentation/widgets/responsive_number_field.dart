// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\nutrition_calculation\presentation\widgets\responsive_number_field.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// =============================================================================
// ResponsiveNumberField
// =============================================================================

/// TextFormField numerik yang seragam dipakai di seluruh form kalkulator gizi.
///
/// Merangkum pola yang berulang di setiap halaman form:
/// - [Semantics] wrapper dengan [label] dan [hint]
/// - [LengthLimitingTextInputFormatter]
/// - Mode desimal (`r'[0-9.]'`) atau integer-only
/// - [OutlineInputBorder] dengan prefixIcon & suffixText
/// - Validator angka bawaan (kosong + non-numerik)
///
/// Preservasi QA: [widgetKey] diteruskan langsung ke [TextFormField],
/// sehingga ValueKey yang sudah terdaftar di Katalon Object Spy tetap valid.
///
/// Contoh penggunaan minimal:
/// ```dart
/// ResponsiveNumberField(
///   widgetKey:     _Keys.weightField,
///   controller:    _weightController,
///   label:         'Berat Badan',
///   suffixText:    'kg',
///   semanticLabel: 'Input Berat Badan',
///   semanticHint:  'Masukkan berat badan dalam kilogram',
/// )
/// ```
///
/// Contoh dengan validator kustom (field suhu di TDEE):
/// ```dart
/// ResponsiveNumberField(
///   widgetKey:       _Keys.tempField,
///   controller:      _tempController,
///   label:           'Suhu Tubuh',
///   suffixText:      '°C',
///   semanticLabel:   'Input Suhu Tubuh',
///   semanticHint:    'Masukkan suhu dalam derajat Celsius',
///   customValidator: (v) {
///     if (v == null || v.isEmpty) return 'Suhu tidak boleh kosong';
///     if (double.tryParse(v) == null) return 'Angka tidak valid';
///     return null;
///   },
/// )
/// ```
@immutable
class ResponsiveNumberField extends StatelessWidget {
  // ── Parameter Wajib ──────────────────────────────────────────────────────

  /// [ValueKey] diteruskan ke [TextFormField] — untuk QA Katalon/Flutter Driver.
  final ValueKey<String> widgetKey;

  final TextEditingController controller;

  /// Teks label di dalam field (floating label).
  final String label;

  // ── Parameter Opsional ────────────────────────────────────────────────────

  /// Icon di sisi kiri field. Default: null (tanpa icon).
  final Icon? prefixIcon;

  /// Teks suffix (satuan) di sisi kanan field. Contoh: 'kg', 'cm', 'tahun'.
  final String? suffixText;

  /// Label Semantics untuk Screen Reader.
  final String? semanticLabel;

  /// Hint Semantics untuk Screen Reader.
  final String? semanticHint;

  /// Jika true, hanya menerima digit integer (tanpa titik desimal).
  /// Default: false (mode desimal).
  final bool isInteger;

  /// Batas maksimum karakter yang dapat dimasukkan. Default: 5.
  final int maxLength;

  /// Validator kustom. Jika null, digunakan validator bawaan:
  ///   - Tidak boleh kosong
  ///   - Harus bisa di-parse ke double
  final String? Function(String?)? customValidator;

  /// Apakah field dinonaktifkan (read-only). Default: false.
  final bool readOnly;

  /// Callback saat field di-tap (berguna untuk date picker).
  final VoidCallback? onTap;

  const ResponsiveNumberField({
    super.key,
    required this.widgetKey,
    required this.controller,
    required this.label,
    this.prefixIcon,
    this.suffixText,
    this.semanticLabel,
    this.semanticHint,
    this.isInteger = false,
    this.maxLength = 5,
    this.customValidator,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Jika tidak ada label Semantics, widget tetap dibungkus Semantics agar
    // patern pemanggilan dari page konsisten — tidak perlu kondisional di page.
    final Widget field = TextFormField(
      key: widgetKey,
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: isInteger
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        LengthLimitingTextInputFormatter(maxLength),
        if (isInteger)
          FilteringTextInputFormatter.digitsOnly
        else
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: prefixIcon,
        suffixText: suffixText,
      ),
      validator: customValidator ?? _defaultValidator,
    );

    // Hanya bungkus Semantics jika label/hint tersedia — menghindari
    // Semantics node kosong yang bisa membingungkan screen reader.
    if (semanticLabel != null || semanticHint != null) {
      return Semantics(
        label: semanticLabel,
        hint: semanticHint,
        textField: true,
        child: field,
      );
    }

    return field;
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.isEmpty) return '$label tidak boleh kosong';
    if (double.tryParse(value) == null) return 'Masukkan angka yang valid';
    return null;
  }
}
