import 'package:flutter/material.dart';

class NutritionistCard extends StatelessWidget {
  final String name;
  final String role;
  final String experience;
  final String rating;
  final String imageUrl;
  final VoidCallback onChatPressed;
  final VoidCallback onCardTap;

  const NutritionistCard({
    super.key,
    required this.name,
    required this.role,
    required this.experience,
    required this.rating,
    required this.imageUrl,
    required this.onChatPressed,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16.0),
      clipBehavior: Clip.antiAlias, // Agar efek inkwell tidak keluar batas border
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: InkWell(
        onTap: onCardTap,
        key: ValueKey('card_nutritionist_${name.replaceAll(' ', '_')}'), // Key untuk Katalon
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto Profil
              Container(
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Detail Informasi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Tag Pengalaman & Rating
                    Row(
                      children: [
                        _buildInfoTag(Icons.work, experience),
                        const SizedBox(width: 8),
                        _buildInfoTag(Icons.thumb_up, rating),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Tombol Chat (Harga Dihapus)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end, // Memastikan tombol tetap di kanan
                      children: [
                        Semantics(
                          label: 'Tombol mulai chat dengan $name',
                          button: true,
                          child: ElevatedButton(
                            key: ValueKey('btn_chat_${name.replaceAll(' ', '_')}'),
                            onPressed: onChatPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              'Chat',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // _buildInfoTag tetap sama...
  Widget _buildInfoTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}