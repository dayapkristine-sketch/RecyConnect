enum LogType {
  registration,
  approval,
  rejection,
  suspension,
  reactivation,
  roleChange,
  deletion,
  login,
  failedLogin,
  settings,
  rating,
  report,
  reportReview,
}

extension LogTypeGroup on LogType {
  String get group {
    switch (this) {
      case LogType.registration:
        return 'Registrations';
      case LogType.login:
      case LogType.failedLogin:
        return 'Logins';
      case LogType.rating:
      case LogType.report:
      case LogType.reportReview:
        return 'Reports & ratings';
      default:
        return 'Admin actions';
    }
  }
}

class ActivityLog {
  ActivityLog({required this.type, required this.message})
    : time = DateTime.now();

  final LogType type;
  final String message;
  final DateTime time;
}
