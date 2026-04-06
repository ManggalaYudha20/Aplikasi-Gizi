// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\account_page\logic\role_formatter.dart

class RoleFormatter {
  // Buat daftar (Map) untuk role yang punya nama khusus
  static const Map<String, String> _customRoles = {
    'ahli_gizi': 'Nutrisionis',
    // 'role_lain': 'Nama Lainnya', <-- Anda bisa tambah dengan mudah di sini nanti
  };

  static String format(String rawRole) {
    if (rawRole.isEmpty) return 'Pengguna';

    // Cek apakah role tersebut ada di daftar pengecualian
    if (_customRoles.containsKey(rawRole)) {
      return _customRoles[rawRole]!;
    }

    // Jika tidak ada di daftar pengecualian, format seperti biasa
    return rawRole
        .split('_')
        .map((word) {
          if (word.isEmpty) return '';
          return "${word[0].toUpperCase()}${word.substring(1).toLowerCase()}";
        })
        .join(' ');
  }
}
