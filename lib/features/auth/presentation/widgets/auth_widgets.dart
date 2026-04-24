import 'package:flutter/material.dart';
import '../../../../core/widgets/clay_widgets.dart';

export '../../../../core/widgets/clay_widgets.dart';

// 1. The "Inset" Input Field (Inner Shadow)
class ClayTextField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextEditingController? controller;
  final bool isNumeric;
  final bool isAllCaps;
  final TextCapitalization? textCapitalization;
  final VoidCallback? onTap;
  final bool readOnly;
  final TextInputType? keyboardType;

  const ClayTextField({
    super.key,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.controller,
    this.isNumeric = false,
    this.isAllCaps = false,
    this.textCapitalization,
    this.onTap,
    this.readOnly = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return ClayInput(
      hint: hint,
      icon: icon,
      isPassword: isPassword,
      controller: controller,
      isNumeric: isNumeric,
      textCapitalization: isAllCaps
          ? TextCapitalization.characters
          : (textCapitalization ?? TextCapitalization.none),
      onTap: onTap,
      readOnly: readOnly,
      keyboardType: keyboardType,
    );
  }
}

// 2. The Primary Action Button (Convex/Popping Out)
class ClayPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const ClayPrimaryButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClayButton(text: text, onTap: onTap, color: const Color(0xFFFFCA28));
  }
}

// 3. Top Toast Helper
void showTopToast(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 60,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isError ? const Color(0xFFFFCDD2) : const Color(0xFFC8E6C9),
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: isError ? Colors.redAccent : Colors.green,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);
  Future.delayed(const Duration(seconds: 3)).then((_) {
    if (overlayEntry.mounted) overlayEntry.remove();
  });
}
