import 'package:episodes_tracker/widgets/caught_up_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders a light-green circle with a dark "=" mark', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CaughtUpIndicator())),
    );

    expect(find.text('='), findsOneWidget);

    final circle = tester.widget<Icon>(find.byIcon(Icons.circle));
    expect(circle.color, Colors.lightGreen);
    expect(circle.size, 24);

    final text = tester.widget<Text>(find.text('='));
    expect(text.style?.color, Colors.green.shade900);
  });

  testWidgets('scales the mark size with the size parameter', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CaughtUpIndicator(size: 18))),
    );

    final circle = tester.widget<Icon>(find.byIcon(Icons.circle));
    expect(circle.size, 18);

    final text = tester.widget<Text>(find.text('='));
    expect(text.style?.fontSize, 18 * 0.5);
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
}
