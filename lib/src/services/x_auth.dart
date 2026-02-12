import '../client.dart';
import '../service.dart';

/// State of the second-factor authentication process.
///
/// See TR-064 X_AVM-DE_Auth StateEnum.
enum SecondFactorState {
  /// Second-factor authentication disabled by configuration.
  disabled,

  /// Waiting for user interaction (e.g. button press) to authenticate.
  waitingforauth,

  /// Second-factor authentication running for another user.
  anotherauthprocess,

  /// Second-factor authentication granted for current user.
  authenticated,

  /// Second-factor authentication stopped and not authenticated.
  stopped,

  /// Too many tries (rate limit reached).
  blocked,

  /// Internal error occurred.
  failure;

  /// Parse a state string returned by the Fritz!Box.
  ///
  /// Returns `null` for unknown values.
  static SecondFactorState? tryParse(String value) {
    for (final s in values) {
      if (s.name == value) return s;
    }
    return null;
  }
}

/// A second-factor authentication method.
///
/// The Fritz!Box reports available methods as a comma-separated string.
/// Known method types are `button`, `dtmf;<sequence>`, and `googleauth`.
sealed class AuthMethod {
  const AuthMethod();

  /// Parse a comma-separated methods string into a list.
  ///
  /// Unknown methods are preserved as [AuthMethodUnknown].
  static List<AuthMethod> parseAll(String methods) {
    if (methods.isEmpty) return const [];
    return methods.split(',').map((s) {
      final trimmed = s.trim();
      if (trimmed == 'button') return const AuthMethodButton();
      if (trimmed.startsWith('dtmf;')) {
        return AuthMethodDtmf(trimmed.substring(5));
      }
      if (trimmed == 'googleauth') return const AuthMethodTotp();
      return AuthMethodUnknown(trimmed);
    }).toList();
  }
}

/// Press any button on the device to authenticate.
class AuthMethodButton extends AuthMethod {
  const AuthMethodButton();

  @override
  String toString() => 'button';
}

/// Enter a DTMF sequence on a connected phone.
class AuthMethodDtmf extends AuthMethod {
  /// The DTMF sequence to enter (e.g. `*11234`).
  final String sequence;

  const AuthMethodDtmf(this.sequence);

  @override
  String toString() => 'dtmf;$sequence';
}

/// TOTP (Google Authenticator) authentication method.
///
/// This method is only available via the Fritz!Box web API (lua endpoints).
/// It is not supported by the TR-064 SOAP protocol.
class AuthMethodTotp extends AuthMethod {
  const AuthMethodTotp();

  @override
  String toString() => 'googleauth';
}

/// An unrecognised authentication method.
class AuthMethodUnknown extends AuthMethod {
  final String raw;

  const AuthMethodUnknown(this.raw);

  @override
  String toString() => raw;
}

/// Result of X_AVM-DE_Auth:SetConfig action.
class AuthConfigResult {
  final String token;
  final SecondFactorState state;
  final List<AuthMethod> methods;

  AuthConfigResult({
    required this.token,
    required this.state,
    required this.methods,
  });

  factory AuthConfigResult.fromArguments(Map<String, String> args) {
    return AuthConfigResult(
      token: args['NewToken'] ?? '',
      state: SecondFactorState.tryParse(args['NewState'] ?? '') ??
          SecondFactorState.failure,
      methods: AuthMethod.parseAll(args['NewMethods'] ?? ''),
    );
  }

  @override
  String toString() => 'AuthConfigResult(${state.name}, methods=$methods)';
}

/// TR-064 X_AVM-DE_Auth service (second-factor authentication).
///
/// Service type: urn:dslforum-org:service:X_AVM-DE_Auth:1
class AuthService extends Tr64Service {
  AuthService({
    required super.description,
    required super.callAction,
    required super.fetchUrl,
  });

  /// Get whether second-factor authentication is enabled.
  Future<bool> getInfo() async {
    final result = await call('GetInfo');
    return result['NewEnabled'] == '1';
  }

  /// Get the current second-factor authentication state.
  Future<SecondFactorState> getState() async {
    final result = await call('GetState');
    return SecondFactorState.tryParse(result['NewState'] ?? '') ??
        SecondFactorState.failure;
  }

  /// Start or stop a second-factor authentication process.
  ///
  /// [action] must be `"start"` or `"stop"`.
  ///
  /// Returns the token, state, and available methods.
  /// The token must be included in the SOAP header for subsequent
  /// actions that require second-factor authentication.
  Future<AuthConfigResult> setConfig(String action) async {
    final result = await call('SetConfig', {
      'NewAction': action,
    });
    return AuthConfigResult.fromArguments(result);
  }
}

/// Extension on [Tr64Client] to access the X_AVM-DE_Auth service.
extension AuthClientExtension on Tr64Client {
  /// Create an [AuthService] for second-factor authentication.
  ///
  /// Requires [Tr64Client.connect] to have been called first.
  AuthService? auth() {
    if (description == null) return null;
    final desc = description!.findByType(
      'urn:dslforum-org:service:X_AVM-DE_Auth:1',
    );
    if (desc == null) return null;
    return AuthService(
      description: desc,
      callAction: (serviceType, controlUrl, actionName, arguments) => call(
        serviceType: serviceType,
        controlUrl: controlUrl,
        actionName: actionName,
        arguments: arguments,
      ),
      fetchUrl: fetchUrl,
    );
  }
}
