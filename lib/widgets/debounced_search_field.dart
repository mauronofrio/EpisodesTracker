import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// A search text field meant to sit in an AppBar's `title`. Reports the
/// trimmed query 400ms after the user stops typing (not on every
/// keystroke), and an empty string immediately when cleared.
class DebouncedSearchField extends StatefulWidget {
  final ValueChanged<String> onQueryChanged;
  final String? hintText;

  const DebouncedSearchField({
    super.key,
    required this.onQueryChanged,
    this.hintText,
  });

  @override
  State<DebouncedSearchField> createState() => _DebouncedSearchFieldState();
}

class _DebouncedSearchFieldState extends State<DebouncedSearchField> {
  final _controller = TextEditingController();
  Timer? _debounce;

  void _onChanged(String value) {
    setState(() {}); // refresh the clear button's visibility
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      widget.onQueryChanged('');
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => widget.onQueryChanged(value.trim()),
    );
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    widget.onQueryChanged('');
    setState(() {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: widget.hintText ?? AppLocalizations.of(context)!.searchHint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        isDense: true,
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(icon: const Icon(Icons.clear), onPressed: _clear),
      ),
      onChanged: _onChanged,
    );
  }
}
