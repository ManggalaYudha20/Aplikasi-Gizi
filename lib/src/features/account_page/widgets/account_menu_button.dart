import 'package:flutter/material.dart';

class AccountMenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? textColor;
  final Color? iconColor;
  // Tambahkan identifier unik jika diperlukan dari luar
  final String? testId; 

  const AccountMenuButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.textColor,
    this.iconColor,
    this.testId, // ID unik untuk testing
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // 1. Membungkus dengan Semantics agar terdeteksi sebagai satu elemen interaktif
      label: 'button_$label', 
      button: true,
      enabled: true,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          // 2. Menambahkan Key untuk identifikasi spesifik di widget tree Flutter
          key: Key(testId ?? 'btn_$label'), 
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: onPressed,
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 12),
              Expanded( // Menggunakan Expanded agar Text tidak overflow
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}