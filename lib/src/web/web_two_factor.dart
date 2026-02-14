import '../services/x_auth.dart';
import 'web_client.dart';

/// Information about Google Authenticator (TOTP) availability.
class TotpInfo {
  /// The name of the device configured for TOTP.
  final String deviceName;

  /// Whether TOTP is configured on the Fritz!Box.
  final bool isConfigured;

  /// Whether TOTP is currently available for use.
  final bool isAvailable;

  TotpInfo({
    required this.deviceName,
    required this.isConfigured,
    required this.isAvailable,
  });

  @override
  String toString() =>
      'TotpInfo($deviceName, configured=$isConfigured, available=$isAvailable)';
}

/// Result of polling the 2FA status via `twofactor.lua`.
class TwoFactorPollResult {
  /// Whether the 2FA process has completed (either confirmed or rejected).
  final bool done;

  /// Whether the 2FA was confirmed (`true`) or rejected (`false`).
  /// Only meaningful when [done] is `true`.
  final bool? active;

  TwoFactorPollResult({required this.done, this.active});

  @override
  String toString() => 'TwoFactorPollResult(done=$done, active=$active)';
}

/// Handles web API two-factor authentication flows.
///
/// The Fritz!Box web API supports three 2FA methods: button press, DTMF
/// sequence, and TOTP (Google Authenticator). This class provides methods
/// to interact with `twofactor.lua` for all three.
///
/// Typical flow:
/// 1. A form submission returns `btn_save: "twofactor"` with a methods string
/// 2. Parse methods with [parseMethods] (or use [AuthMethod.parseAll])
/// 3. For TOTP: call [getGoogleAuthInfo] to check availability, then [submitTotp]
/// 4. For button/DTMF: instruct the user, then [poll] until confirmed
/// 5. After confirmation, re-submit the original form with `confirmed` + `twofactor`
class WebTwoFactor {
  final FritzWebClient client;

  WebTwoFactor(this.client);

  /// Parse a 2FA methods string into [AuthMethod] instances.
  ///
  /// The web API reports DTMF methods as `dtmf;<code>` where `<code>` is the
  /// raw confirmation code. The user must dial `*1<code>` on a connected phone,
  /// so this method prepends the `*1` prefix to the DTMF sequence.
  List<AuthMethod> parseMethods(String methodsStr) {
    return AuthMethod.parseAll(methodsStr).map((m) {
      if (m is AuthMethodDtmf) return AuthMethodDtmf('*1${m.sequence}');
      return m;
    }).toList();
  }

  /// Query Google Authenticator (TOTP) availability.
  ///
  /// Returns a [TotpInfo] if the Fritz!Box supports TOTP, or `null` if
  /// the response doesn't contain Google Auth information.
  Future<TotpInfo?> getGoogleAuthInfo() async {
    final json = await client.postTwoFactor({
      'tfa_googleauth_info': '',
      'no_sidrenew': '',
    });
    final ga = json['googleauth'] as Map<String, dynamic>?;
    if (ga == null) return null;
    return TotpInfo(
      deviceName: ga['deviceName'] as String? ?? '',
      isConfigured: ga['isConfigured'] as bool? ?? false,
      isAvailable: ga['isAvailable'] as bool? ?? false,
    );
  }

  /// Submit a TOTP code for authentication.
  ///
  /// Returns `true` if the code was accepted, `false` if rejected.
  Future<bool> submitTotp(String code) async {
    final json = await client.postTwoFactor({
      'tfa_googleauth': code,
    });
    return json['err'] != 1;
  }

  /// Poll the 2FA status.
  ///
  /// Call this repeatedly (e.g. every second) after initiating a button press
  /// or DTMF 2FA. Returns [TwoFactorPollResult] with `done: true` when the
  /// process completes.
  Future<TwoFactorPollResult> poll() async {
    final json = await client.postTwoFactor({
      'tfa_active': '',
      'no_sidrenew': '',
    });
    return TwoFactorPollResult(
      done: json['done'] as bool? ?? false,
      active: json['active'] as bool?,
    );
  }

  /// Cancel the current 2FA process.
  Future<void> cancel() async {
    await client.postTwoFactor({
      'tfa_cancel': '',
    });
  }
}
