import 'package:flutter/material.dart';
import 'package:clay_containers/clay_containers.dart';
export 'package:clay_containers/clay_containers.dart';

/// A consistent set of Claymorphic (3D) widgets migrated from BVM.
/// These can be used for specific "premium" cards or legacy screens.

const Color kClayBaseColor = Color(0xFFF2F4F8);

class ClayCard extends StatelessWidget {
  final Widget child;
  final double depth;
  final double borderRadius;
  final double spread;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double? width;

  const ClayCard({
    super.key,
    required this.child,
    this.depth = 12,
    this.borderRadius = 16,
    this.spread = 4,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return ClayContainer(
      color: color ?? kClayBaseColor,
      depth: depth.toInt(),
      borderRadius: borderRadius,
      spread: spread,
      width: width,
      child: Padding(padding: padding, child: child),
    );
  }
}

class ClayTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final IconData? icon;
  final ValueChanged<String>? onChanged;
  final bool isNumeric;
  final bool isPassword;
  final TextCapitalization textCapitalization;
  final VoidCallback? onTap;
  final bool readOnly;

  const ClayTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.hint,
    this.keyboardType,
    this.validator,
    this.icon,
    this.onChanged,
    this.isNumeric = false,
    this.isPassword = false,
    this.textCapitalization = TextCapitalization.none,
    this.onTap,
    this.readOnly = false,
  });

  @override
  State<ClayTextField> createState() => _ClayTextFieldState();
}

class _ClayTextFieldState extends State<ClayTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return ClayContainer(
      depth: -10,
      borderRadius: 12,
      color: kClayBaseColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType ??
              (widget.isNumeric ? TextInputType.number : null),
          validator: widget.validator,
          onChanged: widget.onChanged,
          obscureText: _obscureText,
          textCapitalization: widget.textCapitalization,
          onTap: widget.onTap,
          readOnly: widget.readOnly,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: widget.placeholder ?? widget.hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            prefixIcon: widget.icon != null
                ? Icon(widget.icon, size: 20, color: Colors.grey)
                : null,
            suffixIcon: widget.isPassword
                ? GestureDetector(
                    onTap: () => setState(() => _obscureText = !_obscureText),
                    child: Icon(
                      _obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: Colors.grey,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class ClayPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color? color;
  final bool fullWidth;
  final IconData? icon;

  const ClayPrimaryButton({
    super.key,
    required this.text,
    required this.onTap,
    this.color,
    this.fullWidth = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final btn = ClayContainer(
      surfaceColor: color ?? Colors.deepOrange,
      parentColor: kClayBaseColor,
      borderRadius: 12,
      depth: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                text.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: fullWidth ? SizedBox(width: double.infinity, child: btn) : btn,
    );
  }
}

// Backward Compatibility Aliases
typedef ClayButton = ClayPrimaryButton;
typedef ClayInput = ClayTextField;
