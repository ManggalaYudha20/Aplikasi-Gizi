import 'package:flutter/material.dart';

class FormActionButtons extends StatelessWidget {
  final VoidCallback? onReset;
  final VoidCallback? onSubmit;
  final String submitText;
  final String resetText;
  final bool isLoading;
  final bool singleButtonMode;
  final Widget? submitIcon;
  final Widget? resetIcon;
  final Color? resetButtonColor;
  final Color? submitButtonColor;
  final Color? resetForegroundColor;

  const FormActionButtons({
    super.key,
    this.onReset,
    this.onSubmit,
    this.submitText = 'Hitung',
    this.resetText = 'Reset',
    this.isLoading = false,
    this.singleButtonMode = false,
    this.submitIcon,
    this.resetIcon,
    this.resetButtonColor,
    this.submitButtonColor,
    this.resetForegroundColor,
  }) : assert(
         singleButtonMode
             ? (onSubmit != null && onReset == null)
             : (onSubmit != null && onReset != null),
         'In single button mode, only onSubmit should be provided. In dual button mode, both onReset and onSubmit are required.',
       );

  @override
  Widget build(BuildContext context) {
    if (singleButtonMode) {
      // Single button mode - return just the submit button
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          key: const ValueKey('btnHitung'),
          onPressed: isLoading ? null : onSubmit,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            backgroundColor: const Color.fromARGB(255, 0, 148, 68),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (submitIcon != null) ...[
                      submitIcon!,
                      const SizedBox(width: 8),
                    ],
                    Text(
                      submitText,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
        ),
      );
    } else {
      // Dual button mode - return both reset and submit buttons
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: isLoading ? null : onReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: resetButtonColor ?? Colors.grey[300],
                // Logika baru: Prioritaskan warna kustom, jika tidak ada, gunakan logika lama
                foregroundColor:
                    resetForegroundColor ??
                    (resetButtonColor == null ? Colors.black87 : Colors.white),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color:
                        resetForegroundColor ??
                        Colors
                            .transparent, // Tambah border jika ada warna custom
                    width: 1.5,
                  ),
                ),
                elevation: resetButtonColor == Colors.white
                    ? 0
                    : 2, // Hilangkan bayangan jika putih
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (resetIcon != null) ...[
                    resetIcon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    resetText,
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              key: const ValueKey('btnHitung'),
              onPressed: isLoading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor:
                    submitButtonColor ?? const Color.fromARGB(255, 0, 148, 68),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (submitIcon != null) ...[
                          submitIcon!,
                          const SizedBox(width: 8),
                        ],
                        Text(
                          submitText,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      );
    }
  }
}
