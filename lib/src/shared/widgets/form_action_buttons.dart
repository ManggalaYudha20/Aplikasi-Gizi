import 'package:flutter/material.dart';

class FormActionButtons extends StatelessWidget {
  final VoidCallback onReset;
  final VoidCallback onSubmit;
  final String submitText;

  const FormActionButtons({
    super.key,
    required this.onReset,
    required this.onSubmit,
    this.submitText = 'Hitung',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onReset,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              side: const BorderSide(color: Color.fromARGB(255, 0, 148, 68)),
            ),
            child: const Text('Reset', style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 0, 148, 68))),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              backgroundColor: const Color.fromARGB(255, 0, 148, 68),
            ),
            child: Text(submitText, style: const TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}