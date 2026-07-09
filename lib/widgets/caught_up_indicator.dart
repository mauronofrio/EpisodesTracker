import 'package:flutter/material.dart';

/// A light-green circle with a dark "=" mark, shown when the user is
/// caught up with every aired episode but the season/show isn't finished
/// yet. Visually parallel to [Icons.check_circle] (used for full
/// completion) but with "=" instead of the checkmark.
class CaughtUpIndicator extends StatelessWidget {
  final double size;

  const CaughtUpIndicator({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.lightGreen,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '=',
          style: TextStyle(
            color: Colors.green.shade900,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.6,
            height: 1,
          ),
        ),
      ),
    );
  }
}
