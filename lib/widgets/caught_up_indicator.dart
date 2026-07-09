import 'package:flutter/material.dart';

/// A light-green circle with a dark "=" mark, shown when the user is
/// caught up with every aired episode but the season/show isn't finished
/// yet. Visually parallel to [Icons.check_circle] (used for full
/// completion) but with "=" instead of the checkmark.
///
/// Built from an [Icon] (Icons.circle) rather than a plain [Container] so
/// its rendered footprint matches [Icon(Icons.check_circle)] exactly at
/// the same [size] — a Container filled edge-to-edge renders visibly
/// larger than a Material icon glyph, which has its own baked-in padding.
class CaughtUpIndicator extends StatelessWidget {
  final double size;

  const CaughtUpIndicator({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.circle, color: Colors.lightGreen, size: size),
        Text(
          '=',
          style: TextStyle(
            color: Colors.green.shade900,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.5,
            height: 1,
          ),
        ),
      ],
    );
  }
}
