// lib/src/features/kidney_calculation/data/models/kidney_standard_food_model.dart

/// Merepresentasikan satu bahan makanan mentah dalam standar diet ginjal.
///
/// Berbeda dari [FoodItem] di database utama (`food_list_models.dart`),
/// model ini hanya menyimpan data referensi buku (nama, berat, URT) dan
/// tidak memiliki data gizi detail dari Firestore.
class KidneyStandardFoodItem {
  final String name;   // Nama bahan makanan, mis. 'Beras'
  final int weight;    // Berat dalam gram
  final String urt;    // Ukuran Rumah Tangga, mis. '1 ½ gls nasi'

  const KidneyStandardFoodItem({
    required this.name,
    required this.weight,
    required this.urt,
  });
}