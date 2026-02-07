class RoleFormatter {
  /// Mengubah format seperti "ahli_gizi" menjadi "Ahli Gizi"
  static String format(String rawRole) {
    if (rawRole.isEmpty) return 'Pengguna';
    
    return rawRole
        .split('_')
        .map((word) {
          if (word.isEmpty) return '';
          return "${word[0].toUpperCase()}${word.substring(1).toLowerCase()}";
        })
        .join(' ');
  }
}