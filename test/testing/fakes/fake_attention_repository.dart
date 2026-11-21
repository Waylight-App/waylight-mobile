import 'package:flutter/foundation.dart';
import 'package:waylight_mobile/data/repositories/attention/attention_repository.dart';
import 'package:waylight_mobile/domain/models/attention.dart';
import 'package:waylight_mobile/domain/models/server_address.dart';
import 'package:waylight_mobile/utils/result.dart';

/// An [AttentionRepository] in memory.
class FakeAttentionRepository extends ChangeNotifier
    implements AttentionRepository {
  /// Creates the fake; [refresh] answers with [result].
  FakeAttentionRepository({List<AttentionItem> items = const []})
    : result = Result.ok(items);

  /// What [refresh] returns; an [Ok] also replaces [items].
  Result<List<AttentionItem>> result;

  /// How often [refresh] ran.
  int refreshes = 0;

  List<AttentionItem> _items = const [];

  @override
  List<AttentionItem> get items => _items;

  @override
  Future<Result<List<AttentionItem>>> refresh(ServerAddress server) async {
    refreshes++;
    if (result case Ok(:final value)) {
      _items = value;
      notifyListeners();
    }
    return result;
  }

  @override
  Future<void> clear() async {
    _items = const [];
    notifyListeners();
  }
}
