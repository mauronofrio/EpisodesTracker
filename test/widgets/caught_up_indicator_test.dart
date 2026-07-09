import 'package:episodes_tracker/widgets/caught_up_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'renders a light-green circle with two bars matching the background',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(scaffoldBackgroundColor: Colors.black),
          home: const Scaffold(body: CaughtUpIndicator()),
        ),
      );

      final circle = tester.widget<Icon>(find.byIcon(Icons.circle));
      expect(circle.color, Colors.lightGreen);
      expect(circle.size, 24);

      final bars = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(CaughtUpIndicator),
              matching: find.byType(Container),
            ),
          )
          .toList();
      expect(bars, hasLength(2));
      for (final bar in bars) {
        expect(bar.color, Colors.black);
        expect(bar.constraints?.maxWidth, 24 * 0.56);
        expect(bar.constraints?.maxHeight, 24 * 0.12);
      }
    },
  );

  testWidgets('scales the bar size with the size parameter', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CaughtUpIndicator(size: 18))),
    );

    final circle = tester.widget<Icon>(find.byIcon(Icons.circle));
    expect(circle.size, 18);

    final bars = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(CaughtUpIndicator),
            matching: find.byType(Container),
          ),
        )
        .toList();
    for (final bar in bars) {
      expect(bar.constraints?.maxWidth, 18 * 0.56);
      expect(bar.constraints?.maxHeight, 18 * 0.12);
    }
  });

  testWidgets(
    'has the exact same footprint as Icon(Icons.check_circle) at the same size',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CaughtUpIndicator(),
                Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
          ),
        ),
      );

      final caughtUpSize = tester.getSize(find.byType(CaughtUpIndicator));
      final checkCircleSize = tester.getSize(find.byIcon(Icons.check_circle));
      expect(caughtUpSize, checkCircleSize);
    },
  );

  testWidgets('centers the bars exactly within the circle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: CaughtUpIndicator()))),
    );

    final circleCenter = tester.getCenter(find.byIcon(Icons.circle));
    final columnCenter = tester.getCenter(
      find.descendant(
        of: find.byType(CaughtUpIndicator),
        matching: find.byType(Column),
      ),
    );
    expect(columnCenter, circleCenter);
  });
}
