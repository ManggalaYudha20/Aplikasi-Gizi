class TerminologyItem {
  final String domain;      // Contoh: ND (Intervensi) atau FI (Monev)
  final String classCode;   // Contoh: ND-1
  final String category;    // Contoh: Makanan Utama
  final String code;        // Contoh: ND-1.1 atau FI-1.1
  final String label;       // Contoh: Diet makanan biasa

  const TerminologyItem({
    required this.domain,
    required this.classCode,
    required this.category,
    required this.code,
    required this.label,
  });

  // Logika pencarian: Cocokkan Kode, Label, atau Kategori
  bool matches(String query) {
    final lowerQuery = query.toLowerCase();
    return code.toLowerCase().contains(lowerQuery) ||
           label.toLowerCase().contains(lowerQuery) ||
           category.toLowerCase().contains(lowerQuery);
  }

  // Tampilan di Text Field setelah dipilih
  @override
  String toString() => '[$code] $label';
}