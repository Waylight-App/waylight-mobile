import 'package:waylight_mobile/data/repositories/widget_data/queries/json.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/domain/models/actions.dart';
import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// The tracked parcels of the server (#135).
abstract interface class ParcelsRepository {
  /// The parcels.
  Future<Result<List<Parcel>>> parcels(ServerAddress server);

  /// Starts tracking [trackingNumber]; an empty [carrier] lets the server
  /// guess it from the number.
  Future<Result<Parcel>> add(
    ServerAddress server,
    String trackingNumber, {
    String carrier = '',
    String label = '',
  });

  /// Stops tracking a parcel.
  Future<Result<void>> remove(ServerAddress server, String id);
}

/// A [ParcelsRepository] on `/api/parcels`.
class ParcelsRepositoryRemote implements ParcelsRepository {
  /// Creates the repository.
  const ParcelsRepositoryRemote({required this._api});

  final ModuleApi _api;

  @override
  Future<Result<List<Parcel>>> parcels(ServerAddress server) =>
      _api.read(server, '/api/parcels', parseParcels);

  @override
  Future<Result<Parcel>> add(
    ServerAddress server,
    String trackingNumber, {
    String carrier = '',
    String label = '',
  }) async {
    final result = await _api.post(
      server,
      '/api/parcels',
      body: {
        'trackingNumber': trackingNumber,
        'carrier': carrier,
        'label': label,
      },
    );
    return switch (result) {
      Ok(:final value) => switch (_parcel(value)) {
        final p? => Result.ok(p),
        null => const Result.error(ApiException(ApiFailure.server)),
      },
      Error(:final error) => Result.error(error),
    };
  }

  @override
  Future<Result<void>> remove(ServerAddress server, String id) =>
      _api.delete(server, '/api/parcels/${Uri.encodeComponent(id)}');
}

Parcel? _parcel(Object? p) {
  if (p case {
    'id': final String id,
    'trackingNumber': final String number,
    'carrier': final String carrier,
    'status': final String status,
  }) {
    String text(Object? v) => v is String ? v : '';
    return Parcel(
      id: id,
      trackingNumber: number,
      carrier: carrier,
      status: switch (status) {
        'pre-transit' => ParcelStatus.preTransit,
        'transit' => ParcelStatus.transit,
        'delivered' => ParcelStatus.delivered,
        _ => ParcelStatus.other,
      },
      label: text(p['label']),
      description: text(p['description']),
      estimatedDelivery: asDateTime(p['estimatedDelivery'])?.toLocal(),
      trackingUrl: switch (p['trackingUrl']) {
        final String u when u.isNotEmpty => Uri.tryParse(u),
        _ => null,
      },
    );
  }
  return null;
}

/// Maps `GET /api/parcels`.
List<Parcel>? parseParcels(Object? json) => listOf<Parcel>(json, _parcel);
