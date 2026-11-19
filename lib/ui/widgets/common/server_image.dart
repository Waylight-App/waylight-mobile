import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:waylight_mobile/data/repositories/server/server_repository.dart';
import 'package:waylight_mobile/data/repositories/widget_data/widget_data_repository.dart';
import 'package:waylight_mobile/ui/core/themes/dimens.dart';
import 'package:waylight_mobile/utils/result.dart';

/// An image of the server, loaded with the session like every other call
/// (photos, posters, the rain radar).
class ServerImage extends StatefulWidget {
  /// Creates the image.
  const ServerImage({
    required this.path,
    this.query = const {},
    this.fit = BoxFit.contain,
    this.semanticLabel,
    super.key,
  });

  /// The endpoint of the image.
  final String path;

  /// Its query parameters.
  final Map<String, String> query;

  /// How the image fills its box.
  final BoxFit fit;

  /// What the image shows, for screen readers.
  final String? semanticLabel;

  @override
  State<ServerImage> createState() => _ServerImageState();
}

class _ServerImageState extends State<ServerImage> {
  Future<Result<Uint8List>>? _load;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load ??= _fetch();
  }

  @override
  void didUpdateWidget(ServerImage old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path ||
        old.query.toString() != widget.query.toString()) {
      _load = _fetch();
    }
  }

  Future<Result<Uint8List>> _fetch() async {
    final server = context.read<ServerRepository>().current;
    if (server == null) return const Result.error(NotConnectedException());
    return context.read<WidgetDataRepository>().image(
      server,
      widget.path,
      query: widget.query,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _load,
    builder: (context, snapshot) => switch (snapshot.data) {
      Ok(:final value) => Image.memory(
        value,
        fit: widget.fit,
        gaplessPlayback: true,
        semanticLabel: widget.semanticLabel,
      ),
      Error() => Icon(
        Icons.broken_image_outlined,
        color: Theme.of(context).colorScheme.outline,
      ),
      null => const Center(
        child: SizedBox.square(
          dimension: Dimens.inlineProgress,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    },
  );
}
