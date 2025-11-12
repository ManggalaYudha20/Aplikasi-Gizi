import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final String logoPath = 'assets/images/logo.png';

  const CustomAppBar({super.key, required this.title, required this.subtitle});

  // Fungsi untuk menampilkan dialog
  void _showLogoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: GestureDetector(
              // Agar bisa ditutup dengan klik gambar
              onTap: () {
                Navigator.of(dialogContext).pop();
              },
              child: Image.asset(
                logoPath, // Gunakan path yang sama
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 100,
      backgroundColor: const Color.fromARGB(255, 0, 148, 68),
      iconTheme: const IconThemeData(color: Colors.white),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: InkWell(
            // <-- DIBUNGKUS DENGAN INKWELL
            onTap: () {
              // <-- INI FUNGSI YANG DIPANGGIL SAAT DIKLIK
              _showLogoDialog(context);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(logoPath, fit: BoxFit.contain),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
}
