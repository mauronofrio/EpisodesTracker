import 'package:flutter/material.dart';

/// A light-green circle with a "=" mark, shown when the user is caught up
/// with every aired episode but the season/show isn't finished yet.
/// Visually parallel to [Icons.check_circle] (used for full completion)
/// but with "=" instead of the checkmark.
///
/// Built from an [Icon] (Icons.circle) rather than a plain [Container] so
/// its rendered footprint matches [Icon(Icons.check_circle)] exactly at
/// the same [size] — a Container filled edge-to-edge renders visibly
/// larger than a Material icon glyph, which has its own baked-in padding.
///
/// [Icons.check_circle]'s checkmark isn't drawn in a color of its own —
/// it's a hole in the glyph that lets whatever is behind the icon show
/// through. The "=" mark uses the same trick (painted in the surrounding
/// background color) so the two indicators read as the same family, with
/// only the circle's green shade set apart.
///
/// The "=" is drawn as two plain bars rather than a Text('=') glyph: a
/// font's "=" character has asymmetric ascent/descent padding baked in, so
/// centering it inside the Stack drifted visibly off-center once enlarged.
/// Bars have no such metrics to fight — their bounding box is exactly what
/// we draw, so [Alignment.center] centers them exactly.
class CaughtUpIndicator extends StatelessWidget {
  final double size;

  const CaughtUpIndicator({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final barColor = Theme.of(context).scaffoldBackgroundColor;
    final bar = Container(
      width: size * 0.56,
      height: size * 0.12,
      color: barColor,
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.circle, color: Colors.lightGreen, size: size),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [bar, SizedBox(height: size * 0.16), bar],
        ),
      ],
    );
  }
}
