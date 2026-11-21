import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:waylight_mobile/data/repositories/actions/home_server_actions_repository.dart';
import 'package:waylight_mobile/data/services/api/api_client.dart';
import 'package:waylight_mobile/data/services/api/module_api.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../../testing/fakes/fake_server_repository.dart';

void main() {
  test('pauses the DNS filter the widget names (#280)', () async {
    final requests = <http.Request>[];
    final repo = HomeServerActionsRepositoryRemote(
      api: ModuleApi(
        ApiClient(
          client: MockClient((r) async {
            requests.add(r);
            return http.Response(
              '{}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
      ),
    );

    for (final provider in ['pihole', 'adguard']) {
      final result = await repo.pauseDnsFilter(
        testServer(),
        30,
        provider: provider,
      );
      expect(result, isA<Ok<void>>());
      final request = requests.last;
      expect(request.method, 'POST');
      expect(request.url.path, '/api/adguard/pause');
      expect(request.url.queryParameters, {'provider': provider});
      expect(jsonDecode(request.body), {'minutes': 30});
    }
  });
}
