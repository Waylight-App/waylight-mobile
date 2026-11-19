/// A feed item (`GET /api/rss/items`).
final class FeedArticle {
  /// Creates the item.
  const FeedArticle({
    required this.id,
    required this.title,
    required this.feed,
    this.link,
    this.publishedAt,
    this.read = false,
  });

  /// The server's id.
  final String id;

  /// The headline.
  final String title;

  /// The feed's title.
  final String feed;

  /// The article's address.
  final Uri? link;

  /// When it was published.
  final DateTime? publishedAt;

  /// Whether it is marked read.
  final bool read;

  /// The same item, read or unread.
  FeedArticle withRead(bool value) => FeedArticle(
    id: id,
    title: title,
    feed: feed,
    link: link,
    publishedAt: publishedAt,
    read: value,
  );
}

/// The state of a parcel.
enum ParcelStatus {
  /// Announced, not handed over yet.
  preTransit,

  /// On its way.
  transit,

  /// Delivered.
  delivered,

  /// Anything else the carrier reports, such as a failed attempt.
  other,
}

/// A tracked parcel (`GET /api/parcels`).
final class Parcel {
  /// Creates the parcel.
  const Parcel({
    required this.id,
    required this.trackingNumber,
    required this.carrier,
    required this.status,
    this.label = '',
    this.description = '',
    this.estimatedDelivery,
    this.trackingUrl,
  });

  /// The server's id.
  final String id;

  /// The carrier's tracking number.
  final String trackingNumber;

  /// The carrier, such as "dhl".
  final String carrier;

  /// The state.
  final ParcelStatus status;

  /// What it is, as the user wrote it.
  final String label;

  /// The carrier's last message.
  final String description;

  /// The expected delivery, if the carrier says.
  final DateTime? estimatedDelivery;

  /// The carrier's tracking page.
  final Uri? trackingUrl;
}

/// What a smart home entity offers to do.
enum EntityAction {
  /// Nothing; it is only shown.
  none,

  /// Switch on and off.
  toggle,

  /// Press once, such as a scene or a button.
  press,
}

/// A Home Assistant entity (`GET /api/smarthome/entities`).
final class SmartEntity {
  /// Creates the entity.
  const SmartEntity({
    required this.id,
    required this.name,
    required this.state,
    this.unit = '',
    this.action = EntityAction.none,
  });

  /// The entity id, such as `light.desk_lamp`.
  final String id;

  /// The friendly name.
  final String name;

  /// The state as Home Assistant reports it, such as "on" or "21.4".
  final String state;

  /// The unit of a sensor, such as "W".
  final String unit;

  /// What the owner allowed to do with it.
  final EntityAction action;

  /// Whether a switchable entity is on.
  bool get isOn => state == 'on';

  /// The same entity with another state.
  SmartEntity withState(String value) =>
      SmartEntity(id: id, name: name, state: value, unit: unit, action: action);
}
