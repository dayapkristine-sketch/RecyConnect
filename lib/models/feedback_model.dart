import 'user_model.dart';

const List<String> reportReasons = [
  'Did not show up',
  'Unfair or changed price',
  'Rude or abusive behavior',
  'Materials differed from the post',
  'Fake or suspicious account',
  'Other',
];

/// A star rating (1-5) given by one user to another.
class Rating {
  Rating({
    required this.from,
    required this.to,
    required this.stars,
    this.comment = '',
  }) : createdAt = DateTime.now();

  final AppUser from;
  final AppUser to;
  int stars;
  String comment;
  DateTime createdAt;
}

enum ReportStatus { open, resolved, dismissed }

extension ReportStatusLabel on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.open:
        return 'Open';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.dismissed:
        return 'Dismissed';
    }
  }
}

/// A private report that only the reporter and the admin can see.
class UserReport {
  UserReport({
    required this.reporter,
    required this.reported,
    required this.reason,
    this.details = '',
  }) : createdAt = DateTime.now();

  final AppUser reporter;
  final AppUser reported;
  final String reason;
  final String details;
  final DateTime createdAt;
  ReportStatus status = ReportStatus.open;
  String? adminNote;
}
