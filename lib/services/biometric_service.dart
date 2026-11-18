import 'package:local_auth/local_auth.dart';

enum BiometricResult {
  success,
  cancelled,
  unavailable,
  notEnrolled,
  lockedOut,
  failed,
}

class BiometricService {
  BiometricService._();

  static final LocalAuthentication _auth = LocalAuthentication();
  static bool _sessionChecked = false;

  static bool get sessionChecked => _sessionChecked;

  static void allowPasswordFallback() => _sessionChecked = true;

  static void resetSession() => _sessionChecked = false;

  static Future<BiometricResult> authenticate() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!supported || !canCheck) return BiometricResult.unavailable;

      final enrolled = await _auth.getAvailableBiometrics();
      if (enrolled.isEmpty) return BiometricResult.notEnrolled;

      final authenticated = await _auth.authenticate(
        localizedReason: 'Verify your identity to view the admin activity log',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (authenticated) _sessionChecked = true;
      return authenticated
          ? BiometricResult.success
          : BiometricResult.cancelled;
    } on LocalAuthException catch (error) {
      final code = error.code;
      if (code == LocalAuthExceptionCode.biometricLockout ||
          code == LocalAuthExceptionCode.temporaryLockout) {
        return BiometricResult.lockedOut;
      }
      if (code == LocalAuthExceptionCode.userCanceled ||
          code == LocalAuthExceptionCode.systemCanceled) {
        return BiometricResult.cancelled;
      }
      return BiometricResult.failed;
    } catch (_) {
      return BiometricResult.failed;
    }
  }
}
