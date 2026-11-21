import 'package:flutter_test/flutter_test.dart';
import 'package:waylight_mobile/domain/models/tracking_number.dart';

/// Tracking numbers from scanned codes (#196).
void main() {
  test('plain barcodes keep their number', () {
    expect(trackingNumberFrom('00340434161094042557'), '00340434161094042557');
    expect(
      trackingNumberFrom(' 1Z 999 AA1 01 2345 6784 '),
      '1Z999AA10123456784',
    );
    expect(trackingNumberFrom('jjd000390007882596'), 'JJD000390007882596');
  });

  test('GS1 identifiers in parentheses are dropped', () {
    expect(trackingNumberFrom('(00)340434161094042557'), '340434161094042557');
  });

  test('carrier links give the number from their query', () {
    expect(
      trackingNumberFrom(
        'https://www.dhl.de/de/privatkunden/pakete-empfangen/verfolgen.html?piececode=00340434161094042557',
      ),
      '00340434161094042557',
    );
    expect(
      trackingNumberFrom(
        'https://example-carrier.com/track?tracknum=AB123456789DE,CD1',
      ),
      'AB123456789DE',
    );
    expect(trackingNumberFrom('https://example.org/shop'), isNull);
  });

  test('anything else is not a tracking number', () {
    expect(trackingNumberFrom(''), isNull);
    expect(trackingNumberFrom('hello'), isNull);
    expect(trackingNumberFrom('WIFI:S:home;T:WPA;P:secret;;'), isNull);
  });
}
