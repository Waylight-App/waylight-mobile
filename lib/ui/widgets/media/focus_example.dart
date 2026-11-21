import 'package:waylight_mobile/domain/models/media.dart';

/// Example focus days for the gallery preview (#251): yesterday and two
/// sessions so far [today].
List<FocusDay> exampleFocusDays(DateTime today) => [
  FocusDay(
    date: DateTime(today.year, today.month, today.day - 1),
    minutes: 75,
    sessions: 3,
  ),
  FocusDay(date: today, minutes: 50, sessions: 2),
];
