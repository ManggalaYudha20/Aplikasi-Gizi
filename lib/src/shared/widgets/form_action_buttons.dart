import 'package:flutter/material.dart';

class FormActionButtons extends StatelessWidget {
  final VoidCallback? onReset;
  final VoidCallback? onSubmit;
  final String submitText;
  final bool isLoading;
  final bool singleButtonMode;
  final Widget? submitIcon;

  const FormActionButtons({
    super.key,
    this.onReset,
    this.onSubmit,
    this.submitText = 'Hitung',
    this.isLoading = false,
    this.singleButtonMode = false,
    this.submitIcon,
  }) : assert(singleButtonMode ? (onSubmit != null && onReset == null) : (onSubmit != null && onReset != null),
           'In single button mode, only onSubmit should be provided. In dual button mode, both onReset and onSubmit are required.');

  @override
  Widget build(BuildContext context) {
    if (singleButtonMode) {
      // Single button mode - return just the submit button
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : onSubmit,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                    Text(submitText, style: const TextStyle(fontSize: 16, color: Colors.white)),
                  ],
                ),
        ),
      );
    } else {
      // Dual button mode - return both reset and submit buttons
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: isLoading ? null : onReset,
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
              onPressed: isLoading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                        Text(submitText, style: const TextStyle(fontSize: 16, color: Colors.white)),
                      ],
                    ),
            ),
          ),
        ],
      );
    }
  }
}