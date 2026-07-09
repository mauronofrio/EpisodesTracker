import 'package:episodes_tracker/widgets/poster_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders title and subtitle, calls onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PosterListTile(
            posterPath: null,
            title: 'Breaking Bad',
            subtitle: '5/62 episodi visti',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Breaking Bad'), findsOneWidget);
    expect(find.text('5/62 episodi visti'), findsOneWidget);

    await tester.tap(find.byType(PosterListTile));
    expect(tapped, isTrue);
  });

  testWidgets('renders titleSuffix next to the title when provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PosterListTile(
            posterPath: null,
            title: 'Breaking Bad',
            onTap: () {},
            titleSuffix: const Icon(Icons.check_circle, color: Colors.green),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('renders no titleSuffix icon when not provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PosterListTile(
            posterPath: null,
            title: 'Breaking Bad',
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_circle), findsNothing);
  });
}
