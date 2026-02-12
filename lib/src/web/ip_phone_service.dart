import 'web_client.dart';

/// Credentials and settings for an IP phone device.
class IpPhoneCredentials {
  /// The SIP username.
  final String username;

  /// The SIP registrar address.
  final String registrar;

  /// Whether internet access (external registration) is enabled.
  final bool fromInet;

  IpPhoneCredentials({
    required this.username,
    required this.registrar,
    required this.fromInet,
  });

  @override
  String toString() =>
      'IpPhoneCredentials($username, registrar=$registrar, fromInet=$fromInet)';
}

/// Result of a form submission for IP phone settings.
sealed class FormResult {
  const FormResult();
}

/// The form was saved successfully.
class FormOk extends FormResult {
  const FormOk();

  @override
  String toString() => 'FormOk()';
}

/// A validation error occurred.
class FormValError extends FormResult {
  /// The alert message from the Fritz!Box.
  final String alert;

  /// Field names that should be marked as invalid.
  final List<String> tomark;

  const FormValError({required this.alert, required this.tomark});

  @override
  String toString() => 'FormValError($alert, tomark=$tomark)';
}

/// Two-factor authentication is required to save.
class FormTwoFactor extends FormResult {
  /// The available 2FA methods as a comma-separated string.
  ///
  /// Parse with [AuthMethod.parseAll] or [WebTwoFactor.parseMethods].
  final String methods;

  const FormTwoFactor({required this.methods});

  @override
  String toString() => 'FormTwoFactor($methods)';
}

/// Manages IP phone (SIP device) settings via the Fritz!Box web API.
///
/// The web API uses `ip_idx` (0-based index among IP phones) which differs
/// from the TR-064 `clientIndex`. Use [findIpIdx] to locate the correct
/// index by matching the SIP username.
class IpPhoneService {
  final FritzWebClient client;

  IpPhoneService(this.client);

  /// Find the `ip_idx` for a SIP device by its username.
  ///
  /// Probes `edit_ipfon_option` pages sequentially until a matching
  /// username is found. Returns `null` if not found.
  Future<int?> findIpIdx(String sipUsername) async {
    for (int i = 0; i < 20; i++) {
      final body = await _fetchEditPage(i);

      final foundUsername = _extractUsername(body);
      if (foundUsername == null) {
        // Not an edit page (probably overview fallback) — no more devices
        break;
      }
      if (foundUsername == sipUsername) {
        return i;
      }
    }
    return null;
  }

  /// Get the number of existing IP phone devices.
  ///
  /// Probes `edit_ipfon_option` pages to count how many exist.
  Future<int> getIpPhoneCount() async {
    for (int i = 0; i < 20; i++) {
      final body = await _fetchEditPage(i);
      if (_extractUsername(body) == null) return i;
    }
    return 20;
  }

  /// Get the current credentials and settings for an IP phone.
  Future<IpPhoneCredentials> getCredentials(int ipIdx) async {
    final body = await _fetchEditPage(ipIdx);

    final registrarMatch =
        RegExp(r'name="registrar"[^>]*value="([^"]*)"').firstMatch(body) ??
            RegExp(r'value="([^"]*)"[^>]*name="registrar"').firstMatch(body);
    final fromInet = body.contains('checked') &&
        body.contains('from_inet');

    return IpPhoneCredentials(
      username: _extractUsername(body) ?? '',
      registrar: registrarMatch?.group(1) ?? '',
      fromInet: fromInet,
    );
  }

  /// Save IP phone credentials and settings.
  ///
  /// Use [ipIdx] for the device index. For a new device, use the next
  /// available index (from [getIpPhoneCount]). Set [phoneName] when
  /// creating a new device.
  ///
  /// Returns a [FormResult] indicating success, validation error, or
  /// 2FA requirement.
  Future<FormResult> saveCredentials({
    required int ipIdx,
    required String username,
    required String password,
    required bool fromInet,
    String? phoneName,
  }) async {
    final json = await client.submitForm(
      page: 'edit_ipfon_option',
      fields: _buildFields(
        ipIdx: ipIdx,
        username: username,
        password: password,
        fromInet: fromInet,
        phoneName: phoneName,
      ),
    );
    return _parseFormResult(json);
  }

  /// Re-submit the form after 2FA confirmation.
  ///
  /// Call this after the 2FA process completes successfully (via
  /// [WebTwoFactor.poll] or [WebTwoFactor.submitTotp]).
  Future<FormResult> confirmAndSave({
    required int ipIdx,
    required String username,
    required String password,
    required bool fromInet,
    String? phoneName,
  }) async {
    final json = await client.submitForm(
      page: 'edit_ipfon_option',
      fields: {
        ..._buildFields(
          ipIdx: ipIdx,
          username: username,
          password: password,
          fromInet: fromInet,
          phoneName: phoneName,
        ),
        'confirmed': '',
        'twofactor': '',
      },
    );
    return _parseFormResult(json);
  }

  Map<String, String> _buildFields({
    required int ipIdx,
    required String username,
    required String password,
    required bool fromInet,
    String? phoneName,
  }) {
    return <String, String>{
      'username': username,
      'password': password,
      'ip_idx': ipIdx.toString(),
      'back_to_page': '/fon_devices/fondevices_list.lua',
      if (phoneName != null) 'phonename': phoneName,
      if (fromInet) 'from_inet': 'on',
    };
  }

  Future<String> _fetchEditPage(int ipIdx) {
    return client.fetchPage(
      page: 'edit_ipfon_option',
      params: {
        'ip_idx': ipIdx.toString(),
        'back_to_page': '/fon_devices/fondevices_list.lua',
      },
    );
  }

  static String? _extractUsername(String body) {
    final match =
        RegExp(r'name="username"[^>]*value="([^"]*)"').firstMatch(body) ??
            RegExp(r'value="([^"]*)"[^>]*name="username"').firstMatch(body);
    return match?.group(1);
  }

  FormResult _parseFormResult(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) return const FormOk();

    final btnSave = data['btn_save'];
    if (btnSave == 'valerror') {
      final valerror = data['valerror'] as Map<String, dynamic>? ?? {};
      final alert = valerror['alert'] as String? ?? '';
      final tomarkRaw = valerror['tomark'] as List<dynamic>? ?? [];
      final tomark = tomarkRaw.map((e) => e.toString()).toList();
      return FormValError(alert: alert, tomark: tomark);
    }

    if (btnSave == 'twofactor') {
      final methods = data['twofactor'] as String? ?? '';
      return FormTwoFactor(methods: methods);
    }

    return const FormOk();
  }
}
