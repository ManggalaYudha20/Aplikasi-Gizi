// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\nutrition_calculation\presentation\widgets\formula_menu_button.dart

import 'package:flutter/material.dart';

// =============================================================================
// FormulaMenuButton
// =============================================================================

/// Tombol menu kalkulator berbentuk ikon lingkaran dengan label di bawahnya.
///
/// Diekstrak dari class [_FormulaMenuCard] di formula_calculation_page.dart.
/// Dipisahkan ke widget mandiri agar:
/// 1. [FormulaCalculationPage] tetap ramping (hanya berisi GridView + logika nav)
/// 2. Widget ini bisa di-test secara independen (widgetTest)
/// 3. Flutter Engine bisa meng-cache widget ini di tree lebih efisien
///
/// Layout:
/// ```
/// ┌────────────────┐
/// │   ○ Icon  ○   │  ← Container lingkaran
/// │   [name]      │  ← Nama singkat di dalam lingkaran
/// │  [fullName]   │  ← Nama lengkap di bawah lingkaran
/// └────────────────┘
/// ```
///
/// Preservasi QA: [keyId] diteruskan ke [ValueKey] pada [GestureDetector]
/// dan ke [Semantics.identifier], sesuai pola aslinya.
///
/// Contoh penggunaan:
/// ```dart
/// FormulaMenuButton(
///   keyId:    'btn_calc_imt',
///   name:     'IMT',
///   fullName: 'Indeks Massa Tubuh',
///   icon:     Icons.calculate,
///   color:    Colors.blue,
///   onTap:    () => Navigator.push(...),
/// )
/// ```
@immutable
class FormulaMenuButton extends StatelessWidget {
  /// ID stabil untuk QA (Katalon Object Spy / Appium).
  final String keyId;

  /// Nama singkat, ditampilkan di dalam lingkaran ikon.
  final String name;

  /// Nama lengkap, ditampilkan di bawah lingkaran. Mendukung '\n'.
  final String fullName;

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const FormulaMenuButton({
    super.key,
    required this.keyId,
    required this.name,
    required this.fullName,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // [QA] label deskriptif untuk TalkBack / VoiceOver
      label: 'Navigasi ke Kalkulator $name',
      // [QA] identifier stabil untuk Katalon Object Spy
      identifier: keyId,
      button: true,
      child: GestureDetector(
        // [QA] key stabil untuk Flutter Integration Test (Flutter Driver)
        key: ValueKey(keyId),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),

            // ── Ikon Lingkaran ─────────────────────────────────────────────
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
                border: Border.all(color: color, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 30, color: color),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Label Nama Lengkap ─────────────────────────────────────────
            Expanded(
              child: Text(
                fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
