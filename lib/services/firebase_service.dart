import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  static String _role(UserRole value) => value.name;
  static String _idType(IdType value) => value.name;

  static Future<void> registerUser({required AppUser user}) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: user.email,
      password: user.password,
    );
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'Account creation failed.',
      );
    }

    await firebaseUser.updateDisplayName(user.fullName);
    await firebaseUser.sendEmailVerification();

    final profile = <String, dynamic>{
      'uid': firebaseUser.uid,
      'fullName': user.fullName,
      'username': user.username,
      'email': user.email,
      'emailVerified': false,
      'role': _role(user.role),
      'idType': _idType(user.idType),
      'phone': user.phone,
      'address': user.address,
      'status': user.status.name,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
      'failedLoginAttempts': 0,
      'documentsSubmitted': true,
      'idDocumentName': user.idDocument?.name,
      'idBackDocumentName': user.idBackDocument?.name,
      'permitDocumentName': user.permitDocument?.name,
    };

    await db.collection('users').doc(firebaseUser.uid).set(profile);
    await auth.signOut();
  }

  static Future<AppUser> signIn({
    required String identity,
    required String password,
  }) async {
    var email = identity.trim().toLowerCase();
    if (!email.contains('@')) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Please log in using the email address used to register.',
      );
    }

    final result = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final firebaseUser = result.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(code: 'user-null');
    }
    await firebaseUser.reload();
    final refreshedUser = auth.currentUser;
    if (refreshedUser == null) {
      throw FirebaseAuthException(code: 'user-null');
    }
    final profileSnapshot = await db
        .collection('users')
        .doc(refreshedUser.uid)
        .get();
    if (!profileSnapshot.exists) {
      await auth.signOut();
      throw FirebaseAuthException(
        code: 'profile-missing',
        message: 'Your account profile is not ready. Please contact the administrator.',
      );
    }
    final profile = profileSnapshot.data() ?? <String, dynamic>{};
    await db.collection('users').doc(refreshedUser.uid).set({
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return AppUser(
      fullName:
          (profile['fullName'] as String?) ??
          refreshedUser.displayName ??
          'RecyConnect user',
      username: (profile['username'] as String?) ?? email,
      password: '',
      email: refreshedUser.email ?? email,
      role: UserRole.values.firstWhere(
        (value) => value.name == profile['role'],
        orElse: () => UserRole.household,
      ),
      idType: IdType.values.firstWhere(
        (value) => value.name == profile['idType'],
        orElse: () => IdType.other,
      ),
      phone: (profile['phone'] as String?) ?? '',
      address: (profile['address'] as String?) ?? '',
      status: AccountStatus.values.firstWhere(
        (value) => value.name == profile['status'],
        orElse: () => AccountStatus.pending,
      ),
    );
  }

  static Future<void> sendEmailVerification() async {
    final user = auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user was found.',
      );
    }
    await user.sendEmailVerification();
  }

  static Future<bool> reloadEmailVerification() async {
    final user = auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return auth.currentUser?.emailVerified ?? false;
  }

  static Future<void> sendPasswordReset(String email) {
    return auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  static Future<void> signOut() => auth.signOut();

  static Future<void> updateProfile({
    required String uid,
    String? fullName,
    String? phone,
    String? address,
    Uint8List? profilePhoto,
  }) async {
    final values = <String, dynamic>{
      'fullName': ?fullName,
      'phone': ?phone,
      'address': ?address,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await db.collection('users').doc(uid).set(values, SetOptions(merge: true));
  }

  static Future<List<AppUser>> loadUsersForAdmin() async {
    final snapshot = await db.collection('users').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return AppUser(
        firebaseUid: doc.id,
        fullName: (data['fullName'] as String?) ?? 'RecyConnect user',
        username: (data['username'] as String?) ?? doc.id,
        password: '',
        email: (data['email'] as String?) ?? '',
        role: UserRole.values.firstWhere(
          (value) => value.name == data['role'],
          orElse: () => UserRole.household,
        ),
        idType: IdType.values.firstWhere(
          (value) => value.name == data['idType'],
          orElse: () => IdType.other,
        ),
        phone: (data['phone'] as String?) ?? '',
        address: (data['address'] as String?) ?? '',
        status: AccountStatus.values.firstWhere(
          (value) => value.name == data['status'],
          orElse: () => AccountStatus.pending,
        ),
        rejectionReason: data['rejectionReason'] as String?,
        // Older registrations required documents in the app but did not save
        // a metadata flag. Keep those existing pending/approved profiles
        // actionable after migrating the admin list to Firestore.
        documentsSubmitted:
            data['documentsSubmitted'] == true ||
            data['status'] == AccountStatus.pending.name ||
            data['status'] == AccountStatus.approved.name,
        createdAt: _timestampDate(data['createdAt']),
      );
    }).toList();
  }

  static Future<void> updateUserAdminFields({
    required String uid,
    AccountStatus? status,
    String? rejectionReason,
    UserRole? role,
  }) async {
    final values = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      if (status != null) ...{
        'status': status.name,
        'rejectionReason': rejectionReason,
      },
      if (role != null) 'role': role.name,
    };
    await db.collection('users').doc(uid).set(values, SetOptions(merge: true));
  }

  static Future<void> deleteUserProfile(String uid) {
    return db.collection('users').doc(uid).delete();
  }

  static DateTime? _timestampDate(dynamic value) =>
      value is Timestamp ? value.toDate() : null;
}
