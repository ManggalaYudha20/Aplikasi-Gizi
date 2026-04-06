// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\nutrition_calculation\presentation\widgets\calculation_result_card.dart

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WARNA BRAND
// ─────────────────────────────────────────────────────────────────────────────
const Color _kBrandGreen = Color(0xFF009444);

// =============================================================================
// CalculationResultCard
// =============================================================================

/// Kartu hasil perhitungan kalkulator gizi yang dapat digunakan ulang.
///
/// Menampilkan:
/// - [title]    : Judul kartu (misal "Hasil Perhitungan IMT")
/// - [value]    : Nilai numerik utama (misal "22.50 kg/m²")
/// - [category] : Label kategori status (misal "Normal", "Gizi kurang")
/// - [color]    : Warna indikator. Jika null, digunakan warna brand hijau.
/// - [subtitle] : Deskripsi opsional di bawah kategori.
/// - [extra]    : Widget tambahan opsional (misal baris makronutrien di TDEE).
///
/// Preservasi QA: widget ini menerima [containerKey] (ValueKey) yang
/// diteruskan langsung ke Container, sehingga Katalon/Appium tetap bisa
/// menemukan elemen dengan key yang sama seperti sebelumnya.
///
/// Contoh penggunaan di bmi_form_page.dart:
/// ```dart
/// CalculationResultCard(
///   containerKey: _Keys.bmiResultCard,
///   title:        'Hasil Perhitungan IMT',
///   value:        '${_result!.bmi.toStringAsFixed(2)} kg/m²',
///   category:     _result!.categoryLabel,
///   color:        _resultColor,
///   subtitle:     'Indeks Massa Tubuh (IMT) adalah ukuran...',
/// )
/// ```
@immutable
class CalculationResultCard extends StatelessWidget {
  /// [ValueKey] yang diteruskan ke Container — untuk QA Katalon/Appium.
  final ValueKey<String>? containerKey;

  /// Judul kartu, ditampilkan di baris teratas dengan warna [color].
  final String title;

  /// Nilai hasil perhitungan utama dalam format String siap tampil.
  /// Contoh: '22.50 kg/m²', '1850.75 kkal/hari', '65.00 kg'.
  final String value;

  /// Label kategori status gizi.
  /// Contoh: 'Normal', 'Gizi kurang (wasted)', 'Obesitas'.
  final String? category;

  /// Warna indikator seluruh kartu (border, judul, nilai, kategori).
  /// Default: [_kBrandGreen] (#009444).
  final Color? color;

  /// Teks deskripsi opsional ditampilkan di bawah kategori.
  final String? subtitle;

  /// Widget tambahan opsional di bagian bawah kartu, dipisahkan [Divider].
  /// Digunakan oleh TDEE untuk menampilkan baris makronutrien.
  final Widget? extra;

  /// Label Semantics untuk Screen Reader (TalkBack/VoiceOver).
  /// Jika null, dibentuk otomatis dari [title], [value], dan [category].
  final String? semanticsLabel;

  const CalculationResultCard({
    super.key,
    this.containerKey,
    required this.title,
    required this.value,
    this.category,
    this.color,
    this.subtitle,
    this.extra,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.sizeOf(context).width;
    final Color cardColor = color ?? _kBrandGreen;
    final double pad = sw * 0.04;
    final double fontBase14 = _responsiveFont(sw, base: 14);
    final double fontBase16 = _responsiveFont(sw, base: 16);
    final double fontBase18 = _responsiveFont(sw, base: 18);
    final double fontBase24 = _responsiveFont(sw, base: 24);

    final String autoLabel =
        semanticsLabel ??
        '$title: $value'
            '${category != null ? ", Kategori $category" : ""}';

    return Semantics(
      label: autoLabel,
      liveRegion: true, // Screen-reader otomatis membacakan saat nilai berubah
      child: Container(
        key: containerKey,
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: cardColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cardColor, width: 2.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Judul ──────────────────────────────────────────────────────
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontBase18,
                fontWeight: FontWeight.bold,
                color: cardColor,
              ),
            ),

            SizedBox(height: sw * 0.02),

            // ── Nilai Utama ────────────────────────────────────────────────
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontBase24,
                fontWeight: FontWeight.bold,
                color: cardColor,
              ),
            ),

            // ── Kategori (opsional) ────────────────────────────────────────
            if (category != null) ...[
              SizedBox(height: sw * 0.02),
              Text(
                'Kategori: $category',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontBase16,
                  fontWeight: FontWeight.bold,
                  color: cardColor,
                ),
              ),
            ],

            // ── Subtitle / Deskripsi (opsional) ───────────────────────────
            if (subtitle != null) ...[
              SizedBox(height: sw * 0.02),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: fontBase14, color: Colors.black54),
              ),
            ],

            // ── Extra Widget (opsional, misal baris makronutrien) ──────────
            if (extra != null) ...[
              SizedBox(height: sw * 0.04),
              const Divider(color: Colors.black26),
              SizedBox(height: sw * 0.02),
              extra!,
            ],
          ],
        ),
      ),
    );
  }

  double _responsiveFont(double sw, {required double base}) {
    if (sw <= 360) return base * 0.90;
    if (sw >= 600) return base * 1.20;
    return base;
  }
}

// =============================================================================
// ZScoreResultCard
// =============================================================================

/// Varian kartu hasil untuk tampilan Z-Score (digunakan di Status Gizi & IMT/U).
///
/// Berbeda dari [CalculationResultCard] dalam hal layout:
/// - Judul di kiri (bukan center)
/// - Menampilkan baris Z-Score eksplisit
/// - Tidak menampilkan nilai utama besar di tengah
/// - Mendukung [additionalInfo] (misal "IMT: 18.5 kg/m²")
///
/// Preservasi QA: sama seperti induknya, menerima [containerKey].
@immutable
class ZScoreResultCard extends StatelessWidget {
  final ValueKey<String>? containerKey;
  final String title;
  final double? zScore;
  final String category;
  final Color color;
  final String? additionalInfo;

  /// Label Semantics. Jika null, dibentuk otomatis.
  final String? semanticsLabel;

  const ZScoreResultCard({
    super.key,
    this.containerKey,
    required this.title,
    required this.zScore,
    required this.category,
    required this.color,
    this.additionalInfo,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.sizeOf(context).width;
    final double pad = sw * 0.04;
    final double fontBase14 = _responsiveFont(sw, base: 14);

    final String autoLabel =
        semanticsLabel ??
        '$title — Z-Score: ${zScore?.toStringAsFixed(2) ?? "-"}, '
            'Kategori: $category';

    return Semantics(
      label: autoLabel,
      value:
          'Z-Score: ${zScore?.toStringAsFixed(2) ?? "-"}, Kategori: $category',
      child: Container(
        key: containerKey,
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 2.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Judul ──────────────────────────────────────────────────────
            Text(
              title,
              style: TextStyle(
                fontSize: fontBase14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            SizedBox(height: sw * 0.02),

            // ── Z-Score ────────────────────────────────────────────────────
            Text(
              'Z-Score: ${zScore?.toStringAsFixed(2) ?? "-"}',
              style: TextStyle(
                fontSize: fontBase14,
                color: Colors.grey.shade700,
              ),
            ),

            SizedBox(height: sw * 0.01),

            // ── Kategori ───────────────────────────────────────────────────
            Row(
              children: [
                Text(
                  'Kategori: ',
                  style: TextStyle(
                    fontSize: fontBase14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Expanded(
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: fontBase14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),

            // ── Informasi Tambahan (opsional, misal nilai IMT) ─────────────
            if (additionalInfo != null) ...[
              SizedBox(height: sw * 0.01),
              Text(
                additionalInfo!,
                style: TextStyle(
                  fontSize: fontBase14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _responsiveFont(double sw, {required double base}) {
    if (sw <= 360) return base * 0.90;
    if (sw >= 600) return base * 1.20;
    return base;
  }
}
