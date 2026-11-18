import 'package:flutter_test/flutter_test.dart';

import 'package:waylight_mobile/domain/models/api_exception.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/ui/connect_server/view_models/connect_server_view_model.dart';
import 'package:waylight_mobile/utils/result.dart';

import '../../testing/fakes/fake_server_repository.dart';

void main() {
  late FakeServerRepository repository;
  late ConnectServerViewModel viewModel;

  setUp(() {
    repository = FakeServerRepository();
    viewModel = ConnectServerViewModel(serverRepository: repository);
  });

  tearDown(() => viewModel.dispose());

  test('connects to a valid address', () async {
    await viewModel.connect.execute(' home.example.org ');

    expect(viewModel.connect.completed, isTrue);
    expect(repository.connectCalls, [testServer()]);
  });

  test('rejects an invalid address without asking the server', () async {
    await viewModel.connect.execute('');

    final error = (viewModel.connect.result! as Error<Object?>).error;
    expect(error, isA<InvalidServerAddress>());
    expect(repository.connectCalls, isEmpty);
  });

  test('passes on the error of the repository', () async {
    repository.statusResult = const Result.error(
      ApiException(ApiFailure.unreachable),
    );

    await viewModel.connect.execute('home.example.org');

    expect(viewModel.connect.error, isTrue);
  });

  test('warns about plain HTTP while typing', () {
    var notified = 0;
    viewModel.addListener(() => notified++);

    viewModel.onAddressChanged('http://192.168.1.2');
    viewModel.onAddressChanged('http://192.168.1.23');

    expect(viewModel.insecure, isTrue);
    expect(notified, 1);

    viewModel.onAddressChanged('https://192.168.1.2');
    expect(viewModel.insecure, isFalse);
  });
}
