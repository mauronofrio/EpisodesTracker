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

    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.shape, BoxShape.circle);
    expect(decoration.color, Colors.lightGreen);

    final text = tester.widget<Text>(find.text('='));
    expect(text.style?.color, Colors.green.shade900);
  });

  testWidgets('scales the mark size with the size parameter', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CaughtUpIndicator(size: 18)),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container));
    expect(container.constraints?.maxWidth, 18);
    expect(container.constraints?.maxHeight, 18);

    final text = tester.widget<Text>(find.text('='));
    expect(text.style?.fontSize, 18 * 0.6);
  });
}
