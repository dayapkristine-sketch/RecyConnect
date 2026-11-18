import 'dart:typed_data';

import 'package:latlong2/latlong.dart';

enum PostStatus { posted, accepted, collected, sold, cancelled }

extension PostStatusX on PostStatus {
  String get label {
    switch (this) {
      case PostStatus.posted:
        return 'Posted';
      case PostStatus.accepted:
        return 'Accepted';
      case PostStatus.collected:
        return 'Collected';
      case PostStatus.sold:
        return 'Sold';
      case PostStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isClosed =>
      this == PostStatus.collected ||
      this == PostStatus.sold ||
      this == PostStatus.cancelled;
}

enum OfferStatus { pending, accepted, declined }

const kOfferUnits = ['total', 'per kg', 'per piece'];

class PriceOffer {
  PriceOffer({
    required this.id,
    required this.postId,
    required this.collectorUsername,
    required this.collectorName,
    required this.collectorPhone,
    required this.isJunkShop,
    this.providerUid,
    required this.amount,
    required this.unit,
    this.message = '',
    this.status = OfferStatus.pending,
    DateTime? sentAt,
  }) : sentAt = sentAt ?? DateTime.now();

  final String id;
  final String postId;
  final String collectorUsername;
  final String collectorName;
  final String collectorPhone;
  final bool isJunkShop;
  final String? providerUid;
  final double amount;
  final String unit;
  final String message;
  OfferStatus status;
  final DateTime sentAt;

  String get label => '₱${fmtMoney(amount)} $unit';
}

class RecyclablePost {
  RecyclablePost({
    required this.id,
    required this.householdUsername,
    required this.householdName,
    required this.householdPhone,
    required this.material,
    required this.quantity,
    required this.unit,
    required this.location,
    required this.address,
    required this.scheduleLabel,
    this.scheduledAt,
    this.notes = '',
    this.photo,
    this.priceRequested = false,
    this.highValue = false,
    this.anonymous = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String householdUsername;
  final String householdName;
  final String householdPhone;
  final String material;
  final double quantity;
  final String unit; // 'kg' or 'pcs'
  final LatLng location; // exact pin (ERD: PICKUP_LOCATION)
  final String address; // barangay / area, shown to collectors
  final String scheduleLabel;
  final DateTime? scheduledAt;
  final String notes;
  final Uint8List? photo;
  final bool priceRequested;
  final bool highValue;
  final bool anonymous;
  final DateTime createdAt;

  PostStatus status = PostStatus.posted;
  final List<PriceOffer> offers = [];
  String? acceptedOfferId;
  String? collectorUsername;
  String? cancelReason;
  String? cancelledBy;
  DateTime? completedAt;

  String get quantityLabel =>
      '${quantity % 1 == 0 ? quantity.toInt() : quantity} $unit';

  String get displayHouseholdName => anonymous && status != PostStatus.accepted
      ? 'Anonymous household'
      : householdName;

  /// Rounded to ~1 km so collectors cannot see the exact house before accepting.
  LatLng get approxLocation => LatLng(
    (location.latitude * 100).round() / 100,
    (location.longitude * 100).round() / 100,
  );

  PriceOffer? get acceptedOffer {
    for (final o in offers) {
      if (o.id == acceptedOfferId) return o;
    }
    return null;
  }

  PriceOffer? offerBy(String username) {
    PriceOffer? found;
    for (final o in offers) {
      if (o.collectorUsername == username) found = o; // latest wins
    }
    return found;
  }
}

class SukiContact {
  SukiContact({
    required this.id,
    required this.ownerUsername,
    required this.name,
    required this.phone,
    this.address = '',
    this.linkedUsername,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  final String id;
  final String ownerUsername;
  final String name;
  final String phone;
  final String address;
  final String? linkedUsername;
  final DateTime addedAt;

  bool matches(String username, String otherPhone) =>
      (linkedUsername != null && linkedUsername == username) ||
      (phone.trim().isNotEmpty && phone.trim() == otherPhone.trim());
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.toUsername,
    required this.message,
    this.postId,
    DateTime? sentAt,
  }) : sentAt = sentAt ?? DateTime.now();

  final String id;
  final String toUsername;
  final String message;
  final String? postId;
  final DateTime sentAt;
  bool read = false;
}

class DirectMessage {
  DirectMessage({
    required this.id,
    required this.fromUsername,
    required this.fromName,
    required this.toUsername,
    required this.text,
    DateTime? sentAt,
  }) : sentAt = sentAt ?? DateTime.now();

  final String id;
  final String fromUsername;
  final String fromName;
  final String toUsername;
  final String text;
  final DateTime sentAt;
}

class PostMessage {
  PostMessage({
    required this.id,
    required this.postId,
    required this.fromUsername,
    required this.fromName,
    required this.toUsername,
    required this.text,
    DateTime? sentAt,
  }) : sentAt = sentAt ?? DateTime.now();

  final String id;
  final String postId;
  final String fromUsername;
  final String fromName;
  final String toUsername;
  final String text;
  final DateTime sentAt;
}

// ---------- formatting helpers ----------
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String fmtDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

String fmtTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
}

String fmtDateTime(DateTime d) => '${fmtDate(d)}, ${fmtTime(d)}';

String fmtKm(double km) =>
    km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';

String fmtMoney(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
