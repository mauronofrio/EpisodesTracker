import 'package:episodes_tracker/widgets/debounced_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reports the trimmed query 400ms after typing stops', (
    tester,
  ) async {
    final queries = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: DebouncedSearchField(onQueryChanged: queries.add),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '  breaking bad  ');
    // Not yet, still within the debounce window.
    await tester.pump(const Duration(milliseconds: 100));
    expect(queries, isEmpty);

    await tester.pump(const Duration(milliseconds: 350));
    expect(queries, ['breaking bad']);
  });

  testWidgets('reports an empty string immediately when the text is cleared', (
    tester,
  ) async {
    final queries = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: DebouncedSearchField(onQueryChanged: queries.add),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump(const Duration(milliseconds: 450));
    expect(queries, ['a']);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(queries.last, '');
  });

  testWidgets('the clear button appears once there is text and clears it', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: DebouncedSearchField(onQueryChanged: (_) {}),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.clear), findsNothing);

    await tester.enterText(find.byType(TextField), 'x');
    await tester.pump();
    expect(find.byIcon(Icons.clear), findsOneWidget);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();
    expect(find.byIcon(Icons.clear), findsNothing);
    expect(find.text('x'), findsNothing);
  });
}
