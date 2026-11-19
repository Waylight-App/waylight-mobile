import 'package:waylight_mobile/data/services/home_widgets/home_widget_store.dart';
import 'package:waylight_mobile/domain/models/home_snapshot.dart';

/// A [HomeWidgetStore] in memory.
class FakeHomeWidgetStore implements HomeWidgetStore {
  /// The saved cards by widget.
  final Map<HomeWidgetKind, HomeWidgetCard> cards = {};

  /// Whether the refresh in the background is on.
  bool scheduled = false;

  @override
  Future<void> save(HomeWidgetKind kind, HomeWidgetCard card) async =>
      cards[kind] = card;

  @override
  Future<void> clear() async => cards.clear();

  @override
  Future<void> schedule({required bool enabled}) async => scheduled = enabled;

  /// How often a background refresh reported its end.
  int finishedCount = 0;

  @override
  Future<void> finished() async => finishedCount++;
}
