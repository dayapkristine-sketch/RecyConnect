import 'dart:typed_data';

enum UserRole { household, collector, junkShop, admin }

enum AccountStatus { pending, approved, rejected, suspended }

enum IdType {
  nationalId,
  driversLicense,
  schoolId,
  passport,
  votersId,
  philhealthId,
  umid,
  other,
}

extension IdTypeLabel on IdType {
  String get label {
    switch (this) {
      case IdType.nationalId:
        return 'National ID / PhilSys';
      case IdType.driversLicense:
        return "Driver's License";
      case IdType.schoolId:
        return 'School ID';
      case IdType.passport:
        return 'Passport';
      case IdType.votersId:
        return "Voter's ID / Certificate";
      case IdType.philhealthId:
        return 'PhilHealth ID';
      case IdType.umid:
        return 'UMID / SSS ID';
      case IdType.other:
        return 'Other valid government ID';
    }
  }
}

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.household:
        return 'Household';
      case UserRole.collector:
        return 'Collector';
      case UserRole.junkShop:
        return 'Junk Shop Owner';
      case UserRole.admin:
        return 'Administrator';
    }
  }
}

extension AccountStatusLabel on AccountStatus {
  String get label {
    switch (this) {
      case AccountStatus.pending:
        return 'Pending';
      case AccountStatus.approved:
        return 'Approved';
      case AccountStatus.rejected:
        return 'Rejected';
      case AccountStatus.suspended:
        return 'Suspended';
    }
  }
}

class UploadedDoc {
  const UploadedDoc({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;

  String get extension {
    final i = name.lastIndexOf('.');
    return i == -1 ? '' : name.substring(i + 1).toLowerCase();
  }

  bool get isImage => const ['jpg', 'jpeg', 'png'].contains(extension);
  bool get isPdf => extension == 'pdf';
  bool get isWord => extension == 'doc' || extension == 'docx';

  String get sizeLabel {
    final kb = bytes.length / 1024;
    return kb < 1024
        ? '${kb.toStringAsFixed(0)} KB'
        : '${(kb / 1024).toStringAsFixed(1)} MB';
  }
}

class AppUser {
  AppUser({
    required this.fullName,
    required this.username,
    required this.password,
    required this.role,
    this.email = '',
    this.idType = IdType.other,
    this.phone = '',
    this.address = '',
    this.idDocument,
    this.idBackDocument,
    this.permitDocument,
    this.profilePhoto,
    this.status = AccountStatus.pending,
    this.rejectionReason,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       lastActive = DateTime.now();

  String fullName;
  final String username;
  String password; // Kept empty for Firebase-authenticated users.
  String email;
  IdType idType;
  UserRole role;
  String phone;
  String address;
  final UploadedDoc? idDocument;
  final UploadedDoc? idBackDocument;
  final UploadedDoc? permitDocument;
  Uint8List? profilePhoto;
  final DateTime createdAt;
  AccountStatus status;
  String? rejectionReason;
  int failedLoginAttempts = 0;
  DateTime? lockedUntil;
  DateTime lastActive;

  bool get isLocked =>
      lockedUntil != null && lockedUntil!.isAfter(DateTime.now());
  bool get isInactive => DateTime.now().difference(lastActive).inDays >= 30;
  bool get requiresPermit => role == UserRole.junkShop;
  bool get hasRequiredDocuments =>
      idDocument != null &&
      idBackDocument != null &&
      (!requiresPermit || permitDocument != null);
}
