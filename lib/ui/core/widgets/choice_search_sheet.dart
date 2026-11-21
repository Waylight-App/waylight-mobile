import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/ui/core/error_messages.dart';
import 'package:waylight_mobile/ui/core/localization.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/utils/result.dart';

/// A bottom sheet that searches as the user types and returns the entry
/// tapped, e.g. a stop or a place when a widget is set up (#230).
class ChoiceSearchSheet<T> extends StatefulWidget {
  const ChoiceSearchSheet._({
    required this.title,
    required this.search,
    required this.label,
    this.detail,
  });

  /// The heading of the sheet.
  final String title;

  /// Searches for a query of at least [minLength] characters.
  final Future<Result<List<T>>> Function(String query) search;

  /// The text of an entry.
  final String Function(T entry) label;

  /// An optional second line of an entry.
  final String Function(T entry)? detail;

  /// Queries shorter than this are not sent; the server needs two letters.
  static const minLength = 2;

  /// The pause after the last key before a search starts.
  static const debounce = Duration(milliseconds: 300);

  /// Shows the sheet; the entry tapped, or `null` when it was closed.
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Future<Result<List<T>>> Function(String query) search,
    required String Function(T entry) label,
    String Function(T entry)? detail,
  }) => showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => ChoiceSearchSheet<T>._(
      title: title,
      search: search,
      label: label,
      detail: detail,
    ),
  );

  @override
  State<ChoiceSearchSheet<T>> createState() => _ChoiceSearchSheetState<T>();
}

class _ChoiceSearchSheetState<T> extends State<ChoiceSearchSheet<T>> {
  Timer? _timer;
  Result<List<T>>? _result;
  bool _searching = false;
  // Answers to older queries that arrive late are dropped.
  int _generation = 0;

  void _changed(String text) {
    _timer?.cancel();
    final query = text.trim();
    if (query.length < ChoiceSearchSheet.minLength) {
      setState(() {
        _result = null;
        _searching = false;
      });
      return;
    }
    _timer = Timer(ChoiceSearchSheet.debounce, () => _search(query).ignore());
  }

  Future<void> _search(String query) async {
    final generation = ++_generation;
    setState(() => _searching = true);
    final result = await widget.search(query);
    if (!mounted || generation != _generation) return;
    setState(() {
      _result = result;
      _searching = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: Dimens.gap,
        right: Dimens.gap,
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: Dimens.gap),
            TextField(
              key: const ValueKey('choiceSearch.field'),
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.setUpSearchHint,
              ),
              onChanged: _changed,
            ),
            const SizedBox(height: Dimens.gapSmall),
            if (_searching) const LinearProgressIndicator(),
            Expanded(
              child: switch (_result) {
                null => const SizedBox.shrink(),
                Error(:final error) => Text(l10n.errorMessage(error)),
                Ok(:final value) when value.isEmpty => Text(
                  l10n.setUpNoResults,
                ),
                Ok(:final value) => ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, i) {
                    final entry = value[i];
                    final detail = widget.detail?.call(entry) ?? '';
                    return ListTile(
                      key: ValueKey('choiceSearch.$i'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(widget.label(entry)),
                      subtitle: detail.isEmpty ? null : Text(detail),
                      onTap: () => Navigator.of(context).pop(entry),
                    );
                  },
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}
