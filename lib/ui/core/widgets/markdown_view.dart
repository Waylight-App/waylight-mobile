import 'package:markdown/markdown.dart' as md;
import 'package:material_ui/material_ui.dart';

import 'package:waylight_mobile/ui/core/link_opener.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';

/// Shows Markdown from the server (ADR 0013): paragraphs, headings, lists,
/// emphasis, code, quotes, rules and links. Nothing is loaded from other
/// hosts: images show their alternative text, and links open in the
/// system browser, only for http, https and mailto.
class MarkdownView extends StatelessWidget {
  /// Creates the view of [source].
  const MarkdownView(this.source, {super.key});

  /// The Markdown text.
  final String source;

  static const _schemes = {'http', 'https', 'mailto'};

  @override
  Widget build(BuildContext context) {
    // encodeHtml: false keeps the text as written; inline HTML is not
    // parsed into elements and therefore shows as text.
    final nodes = md.Document(
      extensionSet: md.ExtensionSet.commonMark,
      encodeHtml: false,
    ).parse(source.replaceAll('\r\n', '\n'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _blocks(context, nodes, depth: 0),
    );
  }

  List<Widget> _blocks(
    BuildContext context,
    List<md.Node> nodes, {
    required int depth,
  }) {
    final out = <Widget>[];
    for (final node in nodes) {
      final block = _block(context, node, depth: depth);
      if (block == null) continue;
      if (out.isNotEmpty) out.add(const SizedBox(height: Dimens.gapSmall));
      out.add(block);
    }
    return out;
  }

  Widget? _block(BuildContext context, md.Node node, {required int depth}) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    if (node is md.Text) {
      return node.text.trim().isEmpty ? null : Text(node.text);
    }
    if (node is! md.Element) return null;
    switch (node.tag) {
      case 'h1' || 'h2':
        return _rich(context, node, text.titleLarge);
      case 'h3' || 'h4' || 'h5' || 'h6':
        return _rich(context, node, text.titleMedium);
      case 'p':
        return _rich(context, node, text.bodyMedium);
      case 'hr':
        return const Divider();
      case 'pre':
        return Container(
          padding: const EdgeInsets.all(Dimens.gapSmall),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(Dimens.radiusCard / 2),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              node.textContent.trimRight(),
              style: text.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
          ),
        );
      case 'blockquote':
        return Container(
          padding: const EdgeInsetsDirectional.only(start: Dimens.gap),
          decoration: BoxDecoration(
            border: BorderDirectional(
              start: BorderSide(color: theme.colorScheme.outline, width: 3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _blocks(context, node.children ?? [], depth: depth),
          ),
        );
      case 'ul' || 'ol':
        final ordered = node.tag == 'ol';
        final start = int.tryParse(node.attributes['start'] ?? '') ?? 1;
        final items = [
          for (final c in node.children ?? <md.Node>[])
            if (c is md.Element && c.tag == 'li') c,
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, item) in items.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: Dimens.gap * 1.5,
                      child: Text(ordered ? '${start + i}.' : '•'),
                    ),
                    Expanded(child: _listItem(context, item, depth + 1)),
                  ],
                ),
              ),
          ],
        );
      default:
        return _rich(context, node, text.bodyMedium);
    }
  }

  // A list item holds inline content (tight lists) or blocks (loose ones).
  Widget _listItem(BuildContext context, md.Element item, int depth) {
    final children = item.children ?? [];
    final hasBlocks = children.any(
      (c) =>
          c is md.Element &&
          const {'p', 'ul', 'ol', 'pre', 'blockquote'}.contains(c.tag),
    );
    if (!hasBlocks) {
      return _rich(context, item, Theme.of(context).textTheme.bodyMedium);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _blocks(context, children, depth: depth),
    );
  }

  Widget _rich(BuildContext context, md.Element node, TextStyle? style) =>
      Text.rich(TextSpan(style: style, children: _inline(context, node)));

  List<InlineSpan> _inline(BuildContext context, md.Element parent) {
    final theme = Theme.of(context);
    final spans = <InlineSpan>[];
    for (final node in parent.children ?? <md.Node>[]) {
      if (node is md.Text) {
        spans.add(TextSpan(text: node.text));
        continue;
      }
      if (node is! md.Element) continue;
      switch (node.tag) {
        case 'strong':
          spans.add(
            TextSpan(
              style: const TextStyle(fontWeight: FontWeight.bold),
              children: _inline(context, node),
            ),
          );
        case 'em':
          spans.add(
            TextSpan(
              style: const TextStyle(fontStyle: FontStyle.italic),
              children: _inline(context, node),
            ),
          );
        case 'del':
          spans.add(
            TextSpan(
              style: const TextStyle(decoration: TextDecoration.lineThrough),
              children: _inline(context, node),
            ),
          );
        case 'code':
          spans.add(
            TextSpan(
              text: node.textContent,
              style: TextStyle(
                fontFamily: 'monospace',
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          );
        case 'br':
          spans.add(const TextSpan(text: '\n'));
        case 'img':
          // Images are never loaded (ADR 0013): the alternative text stays.
          final alt = node.attributes['alt'] ?? '';
          if (alt.isNotEmpty) spans.add(TextSpan(text: '[$alt]'));
        case 'a':
          spans.add(_link(context, node));
        default:
          spans.addAll(_inline(context, node));
      }
    }
    return spans;
  }

  // A link is its own small widget in the line: a tap opens it in the
  // browser, and screen readers announce it as a link.
  InlineSpan _link(BuildContext context, md.Element node) {
    final uri = Uri.tryParse(node.attributes['href'] ?? '');
    final children = _inline(context, node);
    if (uri == null || !_schemes.contains(uri.scheme)) {
      return TextSpan(children: children);
    }
    final opener = LinkOpener.of(context);
    final style = DefaultTextStyle.of(context).style.merge(
      TextStyle(
        color: Theme.of(context).colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
    );
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Semantics(
        link: true,
        child: InkWell(
          onTap: () => opener.open(uri).ignore(),
          child: Text.rich(TextSpan(style: style, children: children)),
        ),
      ),
    );
  }
}
