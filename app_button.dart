// lib/widgets/app_button.dart
import 'package:flutter/material.dart';

class AppButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed; // Nullable to allow disabling the button
  final Color backgroundColor;
  final Color? splashColor; // Optional splash color for feedback
  final Color? textColor; // Optional text color
  final double iconSize; // Control icon size
  final double textSize; // Control text size
  final EdgeInsetsGeometry padding; // Control button padding

  const AppButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    required this.backgroundColor,
    this.splashColor,
    this.textColor,
    this.iconSize = 24.0, // Default icon size
    this.textSize = 18.0, // Default text size
    this.padding = const EdgeInsets.symmetric(
      horizontal: 25,
      vertical: 15,
    ), // Default padding
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 150,
      ), // Quick animation for press feedback
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Handles the press down animation
  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
    }
  }

  // Handles the press up/cancel animation
  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the base color for the gradient and text
    final Color baseColor = widget.backgroundColor;
    final Color foregroundColor =
        widget.textColor ?? Colors.white; // Default to white for text/icon

    // Define the gradient for the enabled state
    final Gradient enabledGradient = LinearGradient(
      colors: [
        // ignore: deprecated_member_use
        baseColor.withOpacity(0.9), // Slightly lighter/more vibrant start
        baseColor,
        // ignore: deprecated_member_use
        baseColor.withOpacity(0.9), // Slightly darker/richer end
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    // Define the gradient for the disabled state
    final Gradient disabledGradient = LinearGradient(
      colors: [
        // ignore: deprecated_member_use
        baseColor.withOpacity(0.4), // Desaturated and less opaque
        // ignore: deprecated_member_use
        baseColor.withOpacity(0.3),
        // ignore: deprecated_member_use
        baseColor.withOpacity(0.4),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    // Determine current gradient and foreground color based on onPressed status
    final currentGradient = widget.onPressed != null
        ? enabledGradient
        : disabledGradient;
    final currentForegroundColor = widget.onPressed != null
        ? foregroundColor
        // ignore: deprecated_member_use
        : foregroundColor.withOpacity(0.6); // Dimmed for disabled

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onPressed, // Actual button press handler
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            gradient: currentGradient,
            borderRadius: BorderRadius.circular(
              15.0,
            ), // Generous rounded corners
            boxShadow: [
              BoxShadow(
                color: widget.onPressed != null
                    // ignore: deprecated_member_use
                    ? baseColor.withOpacity(0.4)
                    // ignore: deprecated_member_use
                    : Colors.black.withOpacity(0.1), // Dynamic shadow color
                blurRadius: widget.onPressed != null
                    ? 15.0
                    : 5.0, // More blur for enabled
                offset: widget.onPressed != null
                    ? const Offset(0, 8)
                    : const Offset(0, 2), // Deeper shadow for enabled
              ),
            ],
            border: Border.all(
              color: widget.onPressed != null
                  // ignore: deprecated_member_use
                  ? foregroundColor.withOpacity(0.2)
                  : Colors.transparent, // Subtle border
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, // Keep content tightly packed
            mainAxisAlignment:
                MainAxisAlignment.center, // Center content horizontally
            children: [
              Icon(
                widget.icon,
                color: currentForegroundColor,
                size: widget.iconSize,
              ),
              SizedBox(
                width: widget.padding.horizontal == 0 ? 0 : 10,
              ), // Spacing between icon and text
              Flexible(
                // Use Flexible to prevent text overflow
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: currentForegroundColor,
                    fontSize: widget.textSize,
                    fontWeight: FontWeight.w600, // Slightly bolder text
                  ),
                  overflow: TextOverflow.ellipsis, // Handle long text
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
