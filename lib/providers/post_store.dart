import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/recyclable_post.dart';
import '../services/firebase_service.dart';

/// In-memory store for posts, offers, notifications, and Suki contacts.
/// Replace this with a repository when backend persistence is added.
class PostStore extends ChangeNotifier {
  final List<RecyclablePost> _posts = [];
  final List<AppNotification> _notifications = [];
  final List<SukiContact> _suki = [];
  final List<PostMessage> _messages = [];
  final List<DirectMessage> _directMessages = [];
  final Set<String> _providers = {};
  int _nextId = 0;

  FirebaseFirestore get _db => FirebaseService.db;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  String newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_nextId++}';

  List<RecyclablePost> forHousehold(String username) =>
      _posts.where((p) => p.householdUsername == username).toList();

  List<RecyclablePost> openPosts() =>
      _posts.where((p) => p.status == PostStatus.posted).toList();

  List<RecyclablePost> acceptedFor(String username) => _posts
      .where(
        (p) =>
            p.collectorUsername == username && p.status == PostStatus.accepted,
      )
      .toList();

  List<RecyclablePost> offeredBy(String username) => _posts
      .where((p) => p.offers.any((o) => o.collectorUsername == username))
      .toList();

  List<RecyclablePost> historyFor(String username) => _posts
      .where((p) => p.collectorUsername == username && p.status.isClosed)
      .toList();

  List<RecyclablePost> postsForUser(String username) => _posts
      .where(
        (p) =>
            p.householdUsername == username ||
            p.collectorUsername == username ||
            p.offers.any((o) => o.collectorUsername == username),
      )
      .toList();

  RecyclablePost? postById(String id) {
    for (final post in _posts) {
      if (post.id == id) return post;
    }
    return null;
  }

  List<AppNotification> notificationsFor(String username) =>
      _notifications.where((n) => n.toUsername == username).toList()
        ..sort((a, b) => b.sentAt.compareTo(a.sentAt));

  int unreadFor(String username) =>
      _notifications.where((n) => n.toUsername == username && !n.read).length;

  void addPost(RecyclablePost post) {
    _posts.add(post);
    unawaited(_savePost(post));
    if (post.highValue) {
      for (final username in _providers) {
        _notify(
          username,
          'High-value material posted: ${post.material}. You may want to send an offer.',
          postId: post.id,
        );
      }
    }
    notifyListeners();
  }

  void registerProvider(String username) {
    if (username.trim().isNotEmpty) _providers.add(username);
  }

  List<PostMessage> messagesFor(String postId, String username) =>
      _messages
          .where(
            (m) =>
                m.postId == postId &&
                (m.fromUsername == username || m.toUsername == username),
          )
          .toList()
        ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

  String? sendMessage({
    required RecyclablePost post,
    required String fromUsername,
    required String fromName,
    required String text,
    String? recipientUsername,
  }) {
    final clean = text.trim();
    if (clean.isEmpty) return 'Message cannot be empty.';
    final toUsername =
        recipientUsername ??
        (fromUsername == post.householdUsername
            ? post.collectorUsername
            : post.householdUsername);
    if (toUsername == null || toUsername.isEmpty) {
      return 'Send an offer first so the household can identify the provider.';
    }
    _messages.add(
      PostMessage(
        id: newId('message'),
        postId: post.id,
        fromUsername: fromUsername,
        fromName: fromName,
        toUsername: toUsername,
        text: clean,
      ),
    );
    unawaited(_savePostMessage(_messages.last));
    _notify(
      toUsername,
      'New message from $fromName about ${post.material}.',
      postId: post.id,
    );
    notifyListeners();
    return null;
  }

  List<DirectMessage> directMessagesFor(
    String username,
    String otherUsername,
  ) =>
      _directMessages
          .where(
            (m) =>
                (m.fromUsername == username && m.toUsername == otherUsername) ||
                (m.fromUsername == otherUsername && m.toUsername == username),
          )
          .toList()
        ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

  Set<String> directContactsFor(String username) => _directMessages
      .where((m) => m.fromUsername == username || m.toUsername == username)
      .map((m) => m.fromUsername == username ? m.toUsername : m.fromUsername)
      .toSet();

  String? sendDirectMessage({
    required String fromUsername,
    required String fromName,
    required String toUsername,
    required String text,
  }) {
    final clean = text.trim();
    if (clean.isEmpty) return 'Message cannot be empty.';
    if (fromUsername == toUsername) return 'You cannot message yourself.';
    _directMessages.add(
      DirectMessage(
        id: newId('direct-message'),
        fromUsername: fromUsername,
        fromName: fromName,
        toUsername: toUsername,
        text: clean,
      ),
    );
    unawaited(_saveDirectMessage(_directMessages.last));
    _notify(toUsername, 'New message from $fromName.');
    notifyListeners();
    return null;
  }

  String? sendOffer(
    RecyclablePost post, {
    required String collectorUsername,
    required String collectorName,
    required String collectorPhone,
    required bool isJunkShop,
    required double amount,
    required String unit,
    String message = '',
  }) {
    if (post.status != PostStatus.posted) return 'This post is no longer open.';
    if (post.offerBy(collectorUsername) != null) {
      return 'You already sent an offer.';
    }
    post.offers.add(
      PriceOffer(
        id: newId('offer'),
        postId: post.id,
        collectorUsername: collectorUsername,
        collectorName: collectorName,
        collectorPhone: collectorPhone,
        isJunkShop: isJunkShop,
        providerUid: _uid,
        amount: amount,
        unit: unit,
        message: message,
      ),
    );
    unawaited(_savePost(post));
    unawaited(_saveOffer(post, post.offers.last));
    _notify(
      post.householdUsername,
      '$collectorName sent an offer for your ${post.material} post.',
      postId: post.id,
    );
    notifyListeners();
    return null;
  }

  void respondOffer(
    RecyclablePost post,
    PriceOffer offer, {
    required bool accept,
  }) {
    if (offer.status != OfferStatus.pending) return;
    offer.status = accept ? OfferStatus.accepted : OfferStatus.declined;
    unawaited(_saveOffer(post, offer));
    if (accept) {
      post.status = PostStatus.accepted;
      post.acceptedOfferId = offer.id;
      post.collectorUsername = offer.collectorUsername;
      _notify(
        offer.collectorUsername,
        'Your offer for ${post.material} was accepted.',
        postId: post.id,
      );
      for (final other in post.offers) {
        if (other.id != offer.id && other.status == OfferStatus.pending) {
          other.status = OfferStatus.declined;
          unawaited(_saveOffer(post, other));
        }
      }
    } else {
      _notify(
        offer.collectorUsername,
        'Your offer for ${post.material} was declined.',
        postId: post.id,
      );
    }
    unawaited(_savePost(post));
    notifyListeners();
  }

  String? cancelPost(
    RecyclablePost post, {
    required String reason,
    String? by,
  }) {
    if (post.status.isClosed) return 'This post is already closed.';
    post.status = PostStatus.cancelled;
    post.cancelReason = reason;
    post.cancelledBy = by;
    unawaited(_savePost(post));
    notifyListeners();
    return null;
  }

  void completeCollection(RecyclablePost post, {required bool sold}) {
    if (post.status != PostStatus.accepted) return;
    post.status = sold ? PostStatus.sold : PostStatus.collected;
    post.completedAt = DateTime.now();
    unawaited(_savePost(post));
    notifyListeners();
  }

  void markAllRead(String username) {
    for (final n in _notifications.where((n) => n.toUsername == username)) {
      n.read = true;
      unawaited(
        _db.collection('notifications').doc(n.id).update({'read': true}),
      );
    }
    notifyListeners();
  }

  void markRead(AppNotification notification) {
    notification.read = true;
    unawaited(
      _db.collection('notifications').doc(notification.id).update({
        'read': true,
      }),
    );
    notifyListeners();
  }

  List<SukiContact> sukiFor(String owner) =>
      _suki.where((c) => c.ownerUsername == owner).toList();

  void addSuki({
    required String owner,
    required String name,
    required String phone,
    String address = '',
    String? linkedUsername,
  }) {
    _suki.add(
      SukiContact(
        id: newId('suki'),
        ownerUsername: owner,
        name: name,
        phone: phone,
        address: address,
        linkedUsername: linkedUsername?.trim().isEmpty == true
            ? null
            : linkedUsername?.trim(),
      ),
    );
    unawaited(_saveSuki(_suki.last));
    notifyListeners();
  }

  void removeSuki(SukiContact contact) {
    _suki.remove(contact);
    unawaited(_db.collection('favorites').doc(contact.id).delete());
    notifyListeners();
  }

  bool notifySuki(SukiContact contact, String message) {
    if (contact.linkedUsername == null) return false;
    _notify(contact.linkedUsername!, message);
    notifyListeners();
    return true;
  }

  void _notify(String username, String message, {String? postId}) {
    final notification = AppNotification(
      id: newId('notification'),
      toUsername: username,
      message: message,
      postId: postId,
    );
    _notifications.add(notification);
    unawaited(_saveNotification(notification));
  }

  Future<void> _saveNotification(AppNotification notification) async {
    final fromUid = _uid;
    if (fromUid == null) return;
    final toUid = await _uidForUsername(notification.toUsername);
    if (toUid == null) return;
    await _db.collection('notifications').doc(notification.id).set({
      'fromUid': fromUid,
      'toUid': toUid,
      'toUsername': notification.toUsername,
      'message': notification.message,
      'postId': notification.postId,
      'read': notification.read,
      'sentAt': Timestamp.fromDate(notification.sentAt),
    });
  }

  Future<void> loadForCurrentUser() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final snapshots = await Future.wait([
        _db.collection('posts').where('status', isEqualTo: 'posted').get(),
        _db.collection('posts').where('householdUid', isEqualTo: uid).get(),
      ]);
      final docs = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      for (final snapshot in snapshots) {
        for (final doc in snapshot.docs) {
          docs[doc.id] = doc;
        }
      }
      for (final doc in docs.values) {
        if (postById(doc.id) != null) continue;
        final post = _postFromMap(doc.id, doc.data());
        if (post == null) continue;
        final offers = await doc.reference.collection('offers').get();
        for (final offerDoc in offers.docs) {
          final offer = _offerFromMap(offerDoc.id, post.id, offerDoc.data());
          if (offer != null) post.offers.add(offer);
        }
        _posts.add(post);
        await _loadPostMessages(post.id, uid);
      }
      await _loadSuki(uid);
      await _loadNotifications(uid);
      notifyListeners();
    } catch (_) {
      // The local cache remains usable when Firestore is temporarily offline.
    }
  }

  Future<void> _savePost(RecyclablePost post) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('posts').doc(post.id).set({
      'householdUid': uid,
      'householdUsername': post.householdUsername,
      'householdName': post.householdName,
      'householdPhone': post.householdPhone,
      'material': post.material,
      'quantity': post.quantity,
      'unit': post.unit,
      'latitude': post.location.latitude,
      'longitude': post.location.longitude,
      'address': post.address,
      'scheduleLabel': post.scheduleLabel,
      'scheduledAt': post.scheduledAt == null
          ? null
          : Timestamp.fromDate(post.scheduledAt!),
      'notes': post.notes,
      'priceRequested': post.priceRequested,
      'highValue': post.highValue,
      'anonymous': post.anonymous,
      'status': post.status.name,
      'acceptedOfferId': post.acceptedOfferId,
      'acceptedProviderUid': post.acceptedOffer?.providerUid,
      'collectorUsername': post.collectorUsername,
      'cancelReason': post.cancelReason,
      'cancelledBy': post.cancelledBy,
      'completedAt': post.completedAt == null
          ? null
          : Timestamp.fromDate(post.completedAt!),
      'createdAt': Timestamp.fromDate(post.createdAt),
    }, SetOptions(merge: true));
  }

  Future<void> _saveOffer(RecyclablePost post, PriceOffer offer) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection('posts')
        .doc(post.id)
        .collection('offers')
        .doc(offer.id)
        .set({
          'collectorUsername': offer.collectorUsername,
          'providerUid': offer.providerUid ?? uid,
          'collectorName': offer.collectorName,
          'collectorPhone': offer.collectorPhone,
          'isJunkShop': offer.isJunkShop,
          'amount': offer.amount,
          'unit': offer.unit,
          'message': offer.message,
          'status': offer.status.name,
          'sentAt': Timestamp.fromDate(offer.sentAt),
        }, SetOptions(merge: true));
  }

  Future<void> _savePostMessage(PostMessage message) async {
    final uid = _uid;
    if (uid == null) return;
    final toUid = await _uidForUsername(message.toUsername);
    await _db
        .collection('conversations')
        .doc(message.postId)
        .collection('messages')
        .doc(message.id)
        .set({
          'fromUid': uid,
          'fromUsername': message.fromUsername,
          'fromName': message.fromName,
          'toUsername': message.toUsername,
          'toUid': toUid,
          'text': message.text,
          'sentAt': Timestamp.fromDate(message.sentAt),
        });
  }

  Future<void> _saveDirectMessage(DirectMessage message) async {
    final uid = _uid;
    if (uid == null) return;
    final toUid = await _uidForUsername(message.toUsername);
    final conversationId = [message.fromUsername, message.toUsername]..sort();
    await _db
        .collection('conversations')
        .doc(conversationId.join('__'))
        .collection('messages')
        .doc(message.id)
        .set({
          'fromUid': uid,
          'fromUsername': message.fromUsername,
          'fromName': message.fromName,
          'toUsername': message.toUsername,
          'toUid': toUid,
          'text': message.text,
          'sentAt': Timestamp.fromDate(message.sentAt),
        });
  }

  Future<void> _saveSuki(SukiContact contact) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('favorites').doc(contact.id).set({
      'ownerUid': uid,
      'ownerUsername': contact.ownerUsername,
      'name': contact.name,
      'phone': contact.phone,
      'address': contact.address,
      'linkedUsername': contact.linkedUsername,
      'addedAt': Timestamp.fromDate(contact.addedAt),
    });
  }

  RecyclablePost? _postFromMap(String id, Map<String, dynamic> data) {
    final latitude = (data['latitude'] as num?)?.toDouble();
    final longitude = (data['longitude'] as num?)?.toDouble();
    if (latitude == null || longitude == null) return null;
    final createdAt = _date(data['createdAt']) ?? DateTime.now();
    final post = RecyclablePost(
      id: id,
      householdUsername: (data['householdUsername'] as String?) ?? '',
      householdName: (data['householdName'] as String?) ?? 'Household',
      householdPhone: (data['householdPhone'] as String?) ?? '',
      material: (data['material'] as String?) ?? 'Material',
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0,
      unit: (data['unit'] as String?) ?? 'kg',
      location: LatLng(latitude, longitude),
      address: (data['address'] as String?) ?? '',
      scheduleLabel: (data['scheduleLabel'] as String?) ?? '',
      scheduledAt: _date(data['scheduledAt']),
      notes: (data['notes'] as String?) ?? '',
      priceRequested: data['priceRequested'] == true,
      highValue: data['highValue'] == true,
      anonymous: data['anonymous'] == true,
      createdAt: createdAt,
    );
    post.status = PostStatus.values.firstWhere(
      (value) => value.name == data['status'],
      orElse: () => PostStatus.posted,
    );
    post.acceptedOfferId = data['acceptedOfferId'] as String?;
    post.collectorUsername = data['collectorUsername'] as String?;
    post.cancelReason = data['cancelReason'] as String?;
    post.cancelledBy = data['cancelledBy'] as String?;
    post.completedAt = _date(data['completedAt']);
    return post;
  }

  PriceOffer? _offerFromMap(
    String id,
    String postId,
    Map<String, dynamic> data,
  ) {
    final amount = (data['amount'] as num?)?.toDouble();
    if (amount == null) return null;
    return PriceOffer(
      id: id,
      postId: postId,
      collectorUsername: (data['collectorUsername'] as String?) ?? '',
      collectorName: (data['collectorName'] as String?) ?? '',
      collectorPhone: (data['collectorPhone'] as String?) ?? '',
      isJunkShop: data['isJunkShop'] == true,
      providerUid: data['providerUid'] as String?,
      amount: amount,
      unit: (data['unit'] as String?) ?? 'total',
      message: (data['message'] as String?) ?? '',
      status: OfferStatus.values.firstWhere(
        (value) => value.name == data['status'],
        orElse: () => OfferStatus.pending,
      ),
      sentAt: _date(data['sentAt']),
    );
  }

  DateTime? _date(dynamic value) => value is Timestamp ? value.toDate() : null;

  Future<void> _loadPostMessages(String postId, String uid) async {
    final ref = _db
        .collection('conversations')
        .doc(postId)
        .collection('messages');
    final snapshots = await Future.wait([
      ref.where('fromUid', isEqualTo: uid).get(),
      ref.where('toUid', isEqualTo: uid).get(),
    ]);
    final docs = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final snapshot in snapshots) {
      for (final doc in snapshot.docs) {
        docs[doc.id] = doc;
      }
    }
    for (final doc in docs.values) {
      final data = doc.data();
      _messages.add(
        PostMessage(
          id: doc.id,
          postId: postId,
          fromUsername: (data['fromUsername'] as String?) ?? '',
          fromName: (data['fromName'] as String?) ?? '',
          toUsername: (data['toUsername'] as String?) ?? '',
          text: (data['text'] as String?) ?? '',
          sentAt: _date(data['sentAt']),
        ),
      );
    }
  }

  Future<void> _loadSuki(String uid) async {
    final snapshot = await _db
        .collection('favorites')
        .where('ownerUid', isEqualTo: uid)
        .get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      _suki.add(
        SukiContact(
          id: doc.id,
          ownerUsername: (data['ownerUsername'] as String?) ?? '',
          name: (data['name'] as String?) ?? '',
          phone: (data['phone'] as String?) ?? '',
          address: (data['address'] as String?) ?? '',
          linkedUsername: data['linkedUsername'] as String?,
          addedAt: _date(data['addedAt']),
        ),
      );
    }
  }

  Future<void> _loadNotifications(String uid) async {
    final snapshot = await _db
        .collection('notifications')
        .where('toUid', isEqualTo: uid)
        .get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final notification = AppNotification(
        id: doc.id,
        toUsername: (data['toUsername'] as String?) ?? '',
        message: (data['message'] as String?) ?? '',
        postId: data['postId'] as String?,
        sentAt: _date(data['sentAt']),
      );
      notification.read = data['read'] == true;
      _notifications.add(notification);
    }
  }

  Future<String?> _uidForUsername(String username) async {
    final result = await _db
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return result.docs.isEmpty ? null : result.docs.first.id;
  }
}
