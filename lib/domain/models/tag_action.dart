/// An action a Waylight NFC tag runs (#195). The tag holds only the link
/// of the action, never a secret: someone else's phone without a session
/// for the server can do nothing with it.
sealed class TagAction {
  const TagAction();

  /// The action of a link like `waylight://tag?do=habit&id=h1`, given as
  /// its query parameters; `null` for anything else.
  static TagAction? parse(Map<String, String> query) {
    String? value(String key) => switch (query[key]?.trim()) {
      final v? when v.isNotEmpty => v,
      _ => null,
    };
    return switch ((query['do'], value('id'), value('text'))) {
      ('habit', final id?, _) => HabitTag(id),
      ('smart', final id?, _) => SmartHomeTag(id, ask: query['ask'] != '0'),
      ('shop', _, final text?) => ShoppingTag(text),
      ('tab', final id?, _) => TabTag(id),
      _ => null,
    };
  }

  /// The query parameters of the link.
  Map<String, String> get query;

  /// The link written onto the tag; short, so it fits small stickers.
  Uri get link => Uri(scheme: 'waylight', host: 'tag', queryParameters: query);
}

/// Ticks a habit off for today; a habit already ticked off stays so.
final class HabitTag extends TagAction {
  /// Creates the action for the habit [id].
  const HabitTag(this.id);

  /// The server's id of the habit.
  final String id;

  @override
  Map<String, String> get query => {'do': 'habit', 'id': id};
}

/// Switches or presses a smart home entity.
final class SmartHomeTag extends TagAction {
  /// Creates the action for the entity [id].
  const SmartHomeTag(this.id, {this.ask = true});

  /// The entity id, such as `light.hall`.
  final String id;

  /// Whether the app asks before it changes the device.
  final bool ask;

  @override
  Map<String, String> get query => {
    'do': 'smart',
    'id': id,
    if (!ask) 'ask': '0',
  };
}

/// Adds a fixed item to the current shopping list.
final class ShoppingTag extends TagAction {
  /// Creates the action for [text].
  const ShoppingTag(this.text);

  /// What is added, such as "Coffee".
  final String text;

  @override
  Map<String, String> get query => {'do': 'shop', 'text': text};
}

/// Opens a tab of the dashboard (#260). The router sends the link to the
/// dashboard after sign-in and app lock; an unknown id opens the first tab.
final class TabTag extends TagAction {
  /// Creates the action for the tab [id].
  const TabTag(this.id);

  /// The server's id of the tab.
  final String id;

  @override
  Map<String, String> get query => {'do': 'tab', 'id': id};
}

/// How writing a tag ended.
enum TagWriteOutcome {
  /// The link is on the tag.
  written,

  /// The tag is read-only.
  locked,

  /// The tag has too little memory for the link.
  tooSmall,

  /// The tag is not an NDEF tag and cannot be formatted as one.
  unsupported,

  /// The tag was moved away too early.
  lost,

  /// Writing failed for another reason.
  failed,

  /// The phone has no NFC, or it is turned off.
  unavailable,

  /// The person closed the sheet first.
  cancelled;

  /// The outcome the native side reports; unknown answers count as failed.
  static TagWriteOutcome parse(String? name) => values.firstWhere(
    (o) => o.name == name,
    orElse: () => TagWriteOutcome.failed,
  );
}

/// Whether the phone can write tags right now.
enum NfcState {
  /// NFC is on.
  ready,

  /// NFC is turned off in the system settings.
  off,

  /// The phone has no NFC.
  missing,
}
