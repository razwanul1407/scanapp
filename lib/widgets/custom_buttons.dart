import 'package:flutter/material.dart';

class CustomButtons {
  /// Primary Button
  static Widget primaryButton({
    required String label,
    required VoidCallback onPressed,
    bool isLoading = false,
    double width = double.infinity,
    double height = 48,
    Widget? icon,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : (icon ?? SizedBox.shrink()),
        label: isLoading
            ? SizedBox.shrink()
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  /// Secondary Button
  static Widget secondaryButton({
    required String label,
    required VoidCallback onPressed,
    Widget? icon,
    double width = double.infinity,
  }) {
    return SizedBox(
      width: width,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon ?? SizedBox.shrink(),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Icon Button with Badge
  static Widget iconButtonWithBadge({
    required IconData icon,
    required VoidCallback onPressed,
    String? badge,
    Color? badgeColor,
  }) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
        ),
        if (badge != null)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: badgeColor ?? Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  /// Floating Action Button
  static Widget fab({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    Color? backgroundColor,
  }) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      tooltip: tooltip,
      child: Icon(icon),
    );
  }

  /// Text Button
  static Widget textButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
