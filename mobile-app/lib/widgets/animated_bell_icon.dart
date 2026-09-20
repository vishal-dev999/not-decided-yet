import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedBellIconButton extends StatefulWidget {
  final VoidCallback onPressed;

  const AnimatedBellIconButton({super.key, required this.onPressed});

  @override
  State<AnimatedBellIconButton> createState() => _AnimatedBellIconButtonState();
}

class _AnimatedBellIconButtonState extends State<AnimatedBellIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerShake() {
    _controller.forward(from: 0.0);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double rotate =
            math.sin(_controller.value * math.pi * 4) * 0.25;
        return Transform.rotate(
          angle: rotate,
          child: child,
        );
      },
      child: IconButton(
        icon: const Icon(Icons.notifications_none),
        onPressed: _triggerShake,
      ),
    );
  }
}
