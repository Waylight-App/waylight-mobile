import 'package:waylight_mobile/domain/models/presence.dart';

/// An example board for the gallery preview (#251): the viewer in the
/// office with two colleagues, one at home and one away until [today]
/// plus three days.
PresenceBoard examplePresence(DateTime today) {
  const me = PresencePerson(
    accountId: 'e1',
    name: 'Alex',
    status: PresenceStatus.office,
  );
  return PresenceBoard(
    mine: me,
    people: [
      me,
      const PresencePerson(
        accountId: 'e2',
        name: 'Sam',
        status: PresenceStatus.office,
      ),
      const PresencePerson(
        accountId: 'e3',
        name: 'Robin',
        status: PresenceStatus.home,
      ),
      PresencePerson(
        accountId: 'e4',
        name: 'Kim',
        status: PresenceStatus.away,
        returnOn: DateTime(today.year, today.month, today.day + 3),
      ),
    ],
    counts: const {
      PresenceStatus.office: 2,
      PresenceStatus.home: 1,
      PresenceStatus.away: 1,
      PresenceStatus.none: 0,
    },
  );
}
