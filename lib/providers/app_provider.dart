import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_log.dart';
import '../models/feedback_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class AppProvider extends ChangeNotifier {
  bool isDarkMode = true;
  AppUser? currentUser;
  bool emailVerificationRequired = false;

  // Local UI cache for admin activity and fallback screen state.
  final List<AppUser> users = [];
  final List<ActivityLog> logs = [];
  final List<Rating> ratings = [];
  final List<UserReport> reports = [];

  // Configurable by the admin (WBS 1.9.8 / 1.9.9)
  final List<String> materialCategories = [
    'Plastic',
    'Metal',
    'Glass',
    'Paper',
    'Cardboard',
    'Appliances',
  ];
  final List<String> cancellationReasons = [
    'Household not available',
    'Collector cannot make it',
    'Materials differ from the post',
    'Price not agreed',
  ];

  void _log(LogType type, String message) {
    logs.insert(0, ActivityLog(type: type, message: message));
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode = prefs.getBool('recyconnect_dark_mode') ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    isDarkMode = !isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('recyconnect_dark_mode', isDarkMode);
    notifyListeners();
  }

  String? register({
    required String fullName,
    required String username,
    required String password,
    required UserRole role,
    String email = '',
    IdType idType = IdType.other,
    required String phone,
    required String address,
    required UploadedDoc? idDocument,
    UploadedDoc? idBackDocument,
    UploadedDoc? permitDocument,
  }) {
    final cleanUsername = username.trim().toLowerCase();
    if (cleanUsername == 'admin' ||
        users.any((u) => u.username.toLowerCase() == cleanUsername)) {
      return 'That username is already taken.';
    }
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return 'Please enter a valid email address.';
    }
    if (users.any((u) => u.email.toLowerCase() == cleanEmail)) {
      return 'That email address is already registered.';
    }
    if (password.length < 8 ||
        !password.contains(RegExp(r'[A-Z]')) ||
        !password.contains(RegExp(r'[0-9]'))) {
      return 'Password must be 8+ characters with a capital letter and number.';
    }
    if (idDocument == null) {
      return 'Please attach a valid ID.';
    }
    if (idBackDocument == null) {
      return 'Please attach the back side of your valid ID.';
    }
    if (role == UserRole.junkShop && permitDocument == null) {
      return 'Junk shop owners must attach a business permit.';
    }
    users.add(
      AppUser(
        fullName: fullName.trim(),
        username: cleanUsername,
        password: password,
        role: role,
        email: cleanEmail,
        idType: idType,
        phone: phone.trim(),
        address: address.trim(),
        idDocument: idDocument,
        idBackDocument: idBackDocument,
        permitDocument: role == UserRole.junkShop ? permitDocument : null,
        documentsSubmitted: true,
        status: AccountStatus.pending,
      ),
    );
    _log(
      LogType.registration,
      '${fullName.trim()} registered as ${role.label}',
    );
    notifyListeners();
    return null;
  }

  String? login(String username, String password) {
    final identity = username.trim().toLowerCase();

    AppUser? user;
    for (final item in users) {
      if (item.username.toLowerCase() == identity ||
          item.email.toLowerCase() == identity) {
        user = item;
        break;
      }
    }

    if (user == null) {
      _log(LogType.failedLogin, "Failed login attempt for '$identity'");
      notifyListeners();
      return 'Incorrect username or password.';
    }
    if (user.isLocked) {
      final seconds = user.lockedUntil!.difference(DateTime.now()).inSeconds;
      return 'Too many failed attempts. Try again in ${(seconds / 60).ceil()} minute(s).';
    }
    if (user.password != password) {
      user.failedLoginAttempts++;
      if (user.failedLoginAttempts >= 3) {
        user.lockedUntil = DateTime.now().add(const Duration(minutes: 3));
        user.failedLoginAttempts = 0;
        _log(
          LogType.suspension,
          'Temporarily locked ${user.username} after failed logins',
        );
        notifyListeners();
        return 'Too many failed attempts. Your account is locked for 3 minutes.';
      }
      _log(LogType.failedLogin, "Failed login attempt for '$identity'");
      notifyListeners();
      return 'Incorrect username or password. Attempt ${user.failedLoginAttempts} of 3.';
    }
    if (user.failedLoginAttempts >= 3) {
      user.lockedUntil = DateTime.now().add(const Duration(minutes: 3));
      user.failedLoginAttempts = 0;
      _log(
        LogType.suspension,
        'Temporarily locked ${user.username} after failed logins',
      );
      notifyListeners();
      return 'Too many failed attempts. Your account is locked for 3 minutes.';
    }
    if (user.status == AccountStatus.pending) {
      return 'Your account is still waiting for administrator approval.';
    }
    if (user.status == AccountStatus.rejected) {
      return 'Your registration was rejected. Please contact the administrator.';
    }
    if (user.status == AccountStatus.suspended) {
      return 'Your account is currently suspended.';
    }

    currentUser = user;
    user.failedLoginAttempts = 0;
    user.lockedUntil = null;
    user.lastActive = DateTime.now();
    _log(LogType.login, '${user.fullName} (${user.role.label}) logged in');
    notifyListeners();
    return null;
  }

  String? forgotPassword(String emailOrUsername) {
    final identity = emailOrUsername.trim().toLowerCase();
    AppUser? user;
    for (final candidate in users) {
      if (candidate.email.toLowerCase() == identity ||
          candidate.username.toLowerCase() == identity) {
        user = candidate;
        break;
      }
    }
    if (user == null) return 'No account matches that email or username.';
    return 'Password reset instructions would be sent to ${user.email} after Firebase is connected.';
  }

  Future<String?> forgotPasswordWithFirebase(String email) async {
    if (!email.trim().contains('@')) {
      return 'Please enter the email address linked to your account.';
    }
    try {
      await FirebaseService.sendPasswordReset(email);
      return null;
    } on FirebaseAuthException catch (error) {
      return error.message ?? 'Could not send the password reset email.';
    }
  }

  Future<String?> registerWithFirebase({
    required String fullName,
    required String username,
    required String password,
    required UserRole role,
    required String email,
    required IdType idType,
    required String phone,
    required String address,
    required UploadedDoc idDocument,
    required UploadedDoc idBackDocument,
    UploadedDoc? permitDocument,
  }) async {
    final localError = register(
      fullName: fullName,
      username: username,
      password: password,
      role: role,
      email: email,
      idType: idType,
      phone: phone,
      address: address,
      idDocument: idDocument,
      idBackDocument: idBackDocument,
      permitDocument: permitDocument,
    );
    if (localError != null) return localError;
    final user = users.last;
    try {
      await FirebaseService.registerUser(user: user);
      return null;
    } on FirebaseAuthException catch (error) {
      users.remove(user);
      return error.message ?? 'Could not create the Firebase account.';
    } catch (error) {
      users.remove(user);
      return 'Could not save your account to Firebase: $error';
    }
  }

  Future<String?> loadUsersFromFirebase() async {
    try {
      final loaded = await FirebaseService.loadUsersForAdmin();
      users
        ..clear()
        ..addAll(loaded);
      notifyListeners();
      return null;
    } catch (error) {
      return 'Could not load users from Firebase: $error';
    }
  }

  Future<String?> loginWithFirebase(String identity, String password) async {
    emailVerificationRequired = false;
    try {
      final user = await FirebaseService.signIn(
        identity: identity,
        password: password,
      );
      if (user.status == AccountStatus.pending) {
        await FirebaseService.signOut();
        return 'Your account is still waiting for administrator approval.';
      }
      if (user.status == AccountStatus.suspended) {
        await FirebaseService.signOut();
        return 'Your account is currently suspended.';
      }
      if (user.status == AccountStatus.rejected) {
        await FirebaseService.signOut();
        return 'Your registration was rejected. Please contact the administrator.';
      }
      if (!FirebaseService.auth.currentUser!.emailVerified) {
        emailVerificationRequired = true;
        return 'Please verify your email address before continuing.';
      }
      currentUser = user;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (error) {
      return switch (error.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' => 'Incorrect email/username or password.',
        'invalid-email' =>
          error.message ??
              'Please log in using your registration email address.',
        'network-request-failed' => 'Please check your internet connection.',
        'user-disabled' => 'This account has been disabled.',
        'too-many-requests' => 'Too many attempts. Try again later.',
        _ => error.message ?? 'Unable to sign in.',
      };
    } catch (error) {
      return 'Unable to connect to Firebase: $error';
    }
  }

  Future<String?> resendVerificationEmail() async {
    try {
      await FirebaseService.sendEmailVerification();
      return null;
    } on FirebaseAuthException catch (error) {
      return switch (error.code) {
        'too-many-requests' => 'Too many requests. Please try again later.',
        'network-request-failed' => 'Please check your internet connection.',
        _ => error.message ?? 'Could not send the verification email.',
      };
    }
  }

  Future<bool> checkEmailVerification() async {
    final verified = await FirebaseService.reloadEmailVerification();
    if (verified) emailVerificationRequired = false;
    return verified;
  }

  List<AppUser> get suspiciousUsers =>
      users.where((u) => u.failedLoginAttempts > 0 || u.isLocked).toList();
  List<AppUser> get inactiveUsers => users.where((u) => u.isInactive).toList();

  void clearSecurityLock(AppUser user) {
    user.failedLoginAttempts = 0;
    user.lockedUntil = null;
    _log(LogType.reactivation, 'Cleared security lock for ${user.username}');
    notifyListeners();
  }

  // ---------------- Admin actions ----------------

  Future<void> approve(AppUser user) async {
    await _saveAdminFields(
      user,
      status: AccountStatus.approved,
      rejectionReason: null,
    );
    user.status = AccountStatus.approved;
    user.rejectionReason = null;
    _log(LogType.approval, 'Approved ${user.fullName} (${user.role.label})');
    notifyListeners();
  }

  Future<void> reject(AppUser user, {String reason = ''}) async {
    final cleanReason = reason.isEmpty ? null : reason;
    await _saveAdminFields(
      user,
      status: AccountStatus.rejected,
      rejectionReason: cleanReason,
    );
    user.status = AccountStatus.rejected;
    user.rejectionReason = cleanReason;
    _log(LogType.rejection, 'Rejected ${user.fullName} (${user.role.label})');
    notifyListeners();
  }

  Future<void> suspend(AppUser user) async {
    await _saveAdminFields(user, status: AccountStatus.suspended);
    user.status = AccountStatus.suspended;
    _log(LogType.suspension, 'Suspended ${user.fullName}');
    notifyListeners();
  }

  Future<void> reactivate(AppUser user) async {
    await _saveAdminFields(user, status: AccountStatus.approved);
    user.status = AccountStatus.approved;
    _log(LogType.reactivation, 'Reactivated ${user.fullName}');
    notifyListeners();
  }

  Future<void> changeRole(AppUser user, UserRole role) async {
    if (user.role == role) return;
    await _saveAdminFields(user, role: role);
    final old = user.role.label;
    user.role = role;
    _log(
      LogType.roleChange,
      'Changed ${user.fullName} from $old to ${role.label}',
    );
    notifyListeners();
  }

  Future<void> deleteUser(AppUser user) async {
    if (user.firebaseUid != null) {
      await FirebaseService.deleteUserProfile(user.firebaseUid!);
    }
    users.remove(user);
    ratings.removeWhere((r) => r.from == user || r.to == user);
    reports.removeWhere((r) => r.reporter == user || r.reported == user);
    _log(LogType.deletion, 'Deleted account of ${user.fullName}');
    notifyListeners();
  }

  Future<void> _saveAdminFields(
    AppUser user, {
    AccountStatus? status,
    String? rejectionReason,
    UserRole? role,
  }) async {
    final uid = user.firebaseUid;
    if (uid == null) return;
    await FirebaseService.updateUserAdminFields(
      uid: uid,
      status: status,
      rejectionReason: rejectionReason,
      role: role,
    );
  }

  void addCategory(String value) {
    final v = value.trim();
    if (v.isEmpty || materialCategories.contains(v)) return;
    materialCategories.add(v);
    _log(LogType.settings, "Added material category '$v'");
    notifyListeners();
  }

  void removeCategory(String value) {
    materialCategories.remove(value);
    _log(LogType.settings, "Removed material category '$value'");
    notifyListeners();
  }

  void addReason(String value) {
    final v = value.trim();
    if (v.isEmpty || cancellationReasons.contains(v)) return;
    cancellationReasons.add(v);
    _log(LogType.settings, "Added cancellation reason '$v'");
    notifyListeners();
  }

  void removeReason(String value) {
    cancellationReasons.remove(value);
    _log(LogType.settings, "Removed cancellation reason '$value'");
    notifyListeners();
  }

  // ---------------- Ratings ----------------

  /// Approved collectors and junk shops (or only one role), best rated first.
  List<AppUser> providers({UserRole? role, bool topFirst = true}) {
    final list = users.where((u) {
      if (u.status != AccountStatus.approved) return false;
      if (role != null) return u.role == role;
      return u.role == UserRole.collector || u.role == UserRole.junkShop;
    }).toList();
    list.sort((a, b) {
      if (topFirst) {
        final c = averageRating(b).compareTo(averageRating(a));
        if (c != 0) return c;
        final n = ratingCount(b).compareTo(ratingCount(a));
        if (n != 0) return n;
      }
      return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
    });
    return list;
  }

  AppUser? userByUsername(String username) {
    for (final user in users) {
      if (user.username == username) return user;
    }
    return null;
  }

  String? updateProfile({
    required String fullName,
    required String phone,
    required String address,
    Uint8List? profilePhoto,
  }) {
    final user = currentUser;
    if (user == null) return 'No signed-in user.';
    if (fullName.trim().length < 2) return 'Enter your full name.';
    if (phone.trim().isEmpty) return 'Enter a phone number.';
    if (address.trim().isEmpty) return 'Enter an address.';
    user.fullName = fullName.trim();
    user.phone = phone.trim();
    user.address = address.trim();
    if (profilePhoto != null) user.profilePhoto = profilePhoto;
    _log(LogType.settings, '${user.username} updated their profile');
    notifyListeners();
    return null;
  }

  List<Rating> ratingsFor(AppUser user) {
    final list = ratings.where((r) => r.to == user).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  int ratingCount(AppUser user) => ratings.where((r) => r.to == user).length;

  double averageRating(AppUser user) {
    final list = ratings.where((r) => r.to == user).toList();
    if (list.isEmpty) return 0;
    final total = list.fold<int>(0, (sum, r) => sum + r.stars);
    return total / list.length;
  }

  Rating? ratingBy(AppUser from, AppUser to) {
    for (final r in ratings) {
      if (r.from == from && r.to == to) return r;
    }
    return null;
  }

  /// One rating per person per user. Rating again updates the old one.
  String? submitRating({
    required AppUser from,
    required AppUser to,
    required int stars,
    String comment = '',
  }) {
    if (from == to) return 'You cannot rate yourself.';
    if (stars < 1 || stars > 5) return 'Please select a star rating.';
    final existing = ratingBy(from, to);
    if (existing != null) {
      existing.stars = stars;
      existing.comment = comment.trim();
      existing.createdAt = DateTime.now();
      _log(
        LogType.rating,
        '${from.fullName} updated a rating for ${to.fullName} ($stars stars)',
      );
    } else {
      ratings.add(
        Rating(from: from, to: to, stars: stars, comment: comment.trim()),
      );
      _log(
        LogType.rating,
        '${from.fullName} rated ${to.fullName} ($stars stars)',
      );
    }
    notifyListeners();
    return null;
  }

  void deleteRating(Rating rating) {
    ratings.remove(rating);
    _log(
      LogType.rating,
      'Removed a rating of ${rating.to.fullName} by ${rating.from.fullName}',
    );
    notifyListeners();
  }

  // ---------------- Reports ----------------

  List<UserReport> reportsBy(AppUser user) =>
      reports.where((r) => r.reporter == user).toList();

  int get openReportCount =>
      reports.where((r) => r.status == ReportStatus.open).length;

  String? submitReport({
    required AppUser reporter,
    required AppUser reported,
    required String reason,
    String details = '',
  }) {
    if (reporter == reported) return 'You cannot report yourself.';
    final duplicate = reports.any(
      (r) =>
          r.reporter == reporter &&
          r.reported == reported &&
          r.status == ReportStatus.open,
    );
    if (duplicate) return 'You already have an open report for this user.';
    reports.add(
      UserReport(
        reporter: reporter,
        reported: reported,
        reason: reason,
        details: details.trim(),
      ),
    );
    _log(
      LogType.report,
      '${reporter.fullName} reported ${reported.fullName}: $reason',
    );
    notifyListeners();
    return null;
  }

  void resolveReport(UserReport report, {String note = ''}) {
    report.status = ReportStatus.resolved;
    report.adminNote = note.trim().isEmpty ? null : note.trim();
    _log(
      LogType.reportReview,
      'Resolved report against ${report.reported.fullName} (${report.reason})',
    );
    notifyListeners();
  }

  void dismissReport(UserReport report, {String note = ''}) {
    report.status = ReportStatus.dismissed;
    report.adminNote = note.trim().isEmpty ? null : note.trim();
    _log(
      LogType.reportReview,
      'Dismissed report against ${report.reported.fullName} (${report.reason})',
    );
    notifyListeners();
  }

  void logout() {
    final u = currentUser;
    if (u != null) _log(LogType.login, '${u.fullName} logged out');
    currentUser = null;
    notifyListeners();
  }

  int get pendingCount =>
      users.where((u) => u.status == AccountStatus.pending).length;

  int countStatus(AccountStatus s) => users.where((u) => u.status == s).length;

  int countRole(UserRole r) => users.where((u) => u.role == r).length;
}
