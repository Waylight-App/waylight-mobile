import 'dart:typed_data';

import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// What a read-only widget asks the server: the endpoint, its query and
/// how its JSON becomes a domain model.
///
/// The queries live next to this repository in `queries/`, one file per
/// module, so mapping JSON stays in the data layer.
final class WidgetQuery<T> {
  /// Creates the query.
  const WidgetQuery(this.path, this.parse, {this.query = const {}});

  /// The endpoint, such as `/api/system`.
  final String path;

  /// Maps the JSON; `null` if it does not match.
  final T? Function(Object? json) parse;

  /// The query parameters.
  final Map<String, String> query;

  /// The same query with other parameters, e.g. from a widget's settings.
  WidgetQuery<T> withQuery(Map<String, String> query) =>
      WidgetQuery(path, parse, query: query);
}

/// Reads the data of read-only widgets (#99).
abstract interface class WidgetDataRepository {
  /// Runs [query] against [server].
  Future<Result<T>> read<T>(ServerAddress server, WidgetQuery<T> query);

  /// Loads an image of a module, such as a photo or the rain radar.
  Future<Result<Uint8List>> image(
    ServerAddress server,
    String path, {
    Map<String, String> query = const {},
  });
}
