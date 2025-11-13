import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionInfoWidget extends StatelessWidget {
  const VersionInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        // 1. Cek apakah ada Error
        if (snapshot.hasError) {
          // Tampilkan pesan error kecil untuk debugging (opsional, bisa dihapus saat rilis)
          return Text(
            'Error memuat versi', 
            style: TextStyle(color: Colors.red[200], fontSize: 10),
          );
        }

        // 2. Cek apakah sedang loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 10,
            width: 10,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        // 3. Cek apakah data ada
        if (snapshot.hasData) {
          final info = snapshot.data!;
          // Fallback jika version string kosong (terkadang terjadi di debug mode)
          final version = info.version.isNotEmpty ? info.version : '1.0.0';
          final buildNumber = info.buildNumber.isNotEmpty ? info.buildNumber : '1';

          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Text(
              'Versi $version (Build $buildNumber)',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          );
        } 
        
        // 4. Default return (jangan return SizedBox kosong agar layout tidak 'jump')
        return const Padding(
           padding: EdgeInsets.only(bottom: 20.0),
           child: Text('Memuat versi...', style: TextStyle(color: Colors.grey, fontSize: 12)),
        );
      },
    );
  }
}