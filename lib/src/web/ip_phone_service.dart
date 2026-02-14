import 'dart:convert';

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

/// Callback for wizard step progress reporting.
///
/// Called after each wizard step with the 1-based [step] number,
/// a short [description], the [params] that were sent, and the raw
/// [responseBody] from the Fritz!Box.
typedef WizardStepCallback = void Function(
  int step,
  String description,
  Map<String, String> params,
  String responseBody,
);

/// Manages IP phone (SIP device) settings via the Fritz!Box web API.
///
/// The web API uses `ip_idx` (0-based index among IP phones) which differs
/// from the TR-064 `clientIndex`. Use [findIpIdx] to locate the correct
/// index by matching the SIP username.
class IpPhoneService {
  final FritzWebClient client;

  /// Saved wizard state for 2FA confirmation of [createIpPhone].
  Map<String, String>? _pendingWizardState;

  /// Saved step callback for [confirmCreate] to report the 2FA re-submit.
  WizardStepCallback? _pendingOnStep;

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

  /// Save IP phone credentials and settings for an existing device.
  ///
  /// The device must already exist (created via TR-064 `SetClient4`).
  /// Use [findIpIdx] to locate the correct `ip_idx` by SIP username.
  ///
  /// Returns a [FormResult] indicating success, validation error, or
  /// 2FA requirement.
  Future<FormResult> saveCredentials({
    required int ipIdx,
    required String username,
    required String password,
    required bool fromInet,
  }) async {
    final json = await client.submitForm(
      page: 'edit_ipfon_option',
      fields: _buildFields(
        ipIdx: ipIdx,
        username: username,
        password: password,
        fromInet: fromInet,
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
  }) async {
    final json = await client.submitForm(
      page: 'edit_ipfon_option',
      fields: {
        ..._buildFields(
          ipIdx: ipIdx,
          username: username,
          password: password,
          fromInet: fromInet,
        ),
        'confirmed': '',
        'twofactor': '',
      },
    );
    return _parseFormResult(json);
  }

  /// Create a new IP phone device using the Fritz!Box wizard.
  ///
  /// This drives the `assi_telefon` multi-step wizard that is the only way
  /// to create IP phone devices (TR-064's ExternalRegistration is ignored).
  ///
  /// If [onStep] is provided, it is called after each wizard step with the
  /// step number, a description, and the raw response body — useful for
  /// debugging the wizard flow.
  ///
  /// Returns a [FormResult] indicating success, validation error, or
  /// 2FA requirement. If [FormTwoFactor] is returned, call [confirmCreate]
  /// after 2FA confirmation.
  Future<FormResult> createIpPhone({
    required String name,
    required String username,
    required String password,
    String? outgoingNumber,
    bool connectToAll = true,
    WizardStepCallback? onStep,
  }) async {
    _pendingWizardState = null;
    _pendingOnStep = onStep;

    const wizardConst = <String, String>{
      'HTMLConfigAssiTyp': 'FonOnly',
      'FonAssiFromPage': 'fonerweitert',
    };

    // Step 1: Load wizard start page
    var stepParams = <String, String>{
      ...wizardConst,
      'pagemaster': 'fondevices_list',
    };
    final step1Body = await client.fetchPage(
      page: 'assi_telefon_start',
      params: stepParams,
    );
    onStep?.call(1, 'Load wizard start', stepParams, step1Body);

    // Step 2: Select device type → JSON redirect
    stepParams = {
      ...wizardConst,
      'New_DeviceTyp': 'Fon',
      'Submit_Next': '',
      'oldpage': '/assis/assi_telefon.lua',
    };
    final step2Body = await client.fetchPage(
      page: 'assi_telefon_start',
      params: stepParams,
    );
    onStep?.call(2, 'Select device type (JSON redirect)', stepParams, step2Body);
    final step2Json = jsonDecode(step2Body) as Map<String, dynamic>;
    final step2Params =
        (step2Json['params'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, v.toString()),
            ) ??
            <String, String>{};

    // Step 3: Load phone wizard → HTML with hidden state fields
    stepParams = {
      ...wizardConst,
      'assicall': '1',
      ...step2Params,
    };
    var html = await client.fetchPage(
      page: 'assi_telefon',
      params: stepParams,
    );
    var state = _extractHiddenFields(html);
    onStep?.call(3, 'Load phone wizard', stepParams, html);

    // Step 4: Select port + name (AssiFonConnecting)
    stepParams = {
      ...wizardConst,
      ...state,
      'assicall': '1',
      'New_Notation': name,
      'New_CurrSide': 'AssiFonConnecting',
      'Submit_Next': '',
      'oldpage': '/assis/assi_telefon.lua',
    };
    html = await client.fetchPage(
      page: 'assi_telefon',
      params: stepParams,
    );
    state = _extractHiddenFields(html);
    onStep?.call(4, 'Port + name', stepParams, html);

    // Step 5: Enter credentials (AssiFonIpOption)
    stepParams = {
      ...wizardConst,
      ...state,
      'assicall': '1',
      'New_IpUsername': username,
      'New_IpPassword': password,
      'New_CurrSide': 'AssiFonIpOption',
      'Submit_Next': '',
      'oldpage': '/assis/assi_telefon.lua',
    };
    html = await client.fetchPage(
      page: 'assi_telefon',
      params: stepParams,
    );
    state = _extractHiddenFields(html);
    onStep?.call(5, 'Credentials', stepParams, html);

    // Determine outgoing number: use provided or parse first from HTML
    final sipNumber = outgoingNumber ?? _extractFirstOutgoingNumber(html);

    // Step 6: Select outgoing number (AssiFonOutgoing)
    stepParams = {
      ...wizardConst,
      ...state,
      'assicall': '1',
      'NewFnc_OutgoingNr': sipNumber,
      'New_CurrSide': 'AssiFonOutgoing',
      'Submit_Next': '',
      'oldpage': '/assis/assi_telefon.lua',
    };
    html = await client.fetchPage(
      page: 'assi_telefon',
      params: stepParams,
    );
    state = _extractHiddenFields(html);
    onStep?.call(6, 'Outgoing number=$sipNumber', stepParams, html);

    // Step 7: Select incoming numbers (AssiFonIncoming)
    stepParams = {
      ...wizardConst,
      ...state,
      'assicall': '1',
      if (connectToAll) 'NewFnc_ConnectToAll': 'T',
      'New_CurrSide': 'AssiFonIncoming',
      'Submit_Next': '',
      'oldpage': '/assis/assi_telefon.lua',
    };
    html = await client.fetchPage(
      page: 'assi_telefon',
      params: stepParams,
    );
    state = _extractHiddenFields(html);
    onStep?.call(7, 'Incoming numbers', stepParams, html);

    // Step 8: Save (AssiFonSummary)
    final saveParams = <String, String>{
      ...wizardConst,
      ...state,
      'assicall': '1',
      'New_CurrSide': 'AssiFonSummary',
      'Submit_Save': '',
      'lang': 'de',
      'oldpage': '/assis/assi_telefon.lua',
    };

    final resultBody = await client.fetchPage(
      page: 'assi_telefon',
      params: saveParams,
    );
    onStep?.call(8, 'Save (AssiFonSummary)', saveParams, resultBody);
    final resultJson = jsonDecode(resultBody) as Map<String, dynamic>;
    final result = _parseWizardResult(resultJson);

    if (result is FormTwoFactor) {
      _pendingWizardState = saveParams;
    }

    return result;
  }

  /// Re-submit the wizard save step after 2FA confirmation.
  ///
  /// Call this after [createIpPhone] returns [FormTwoFactor] and the 2FA
  /// process completes successfully.
  Future<FormResult> confirmCreate() async {
    final state = _pendingWizardState;
    if (state == null) {
      throw StateError('No pending wizard state — call createIpPhone() first');
    }
    _pendingWizardState = null;

    final confirmParams = <String, String>{
      ...state,
      'confirmed': '',
      'twofactor': '',
    };
    final resultBody = await client.fetchPage(
      page: 'assi_telefon',
      params: confirmParams,
    );
    _pendingOnStep?.call(9, 'Confirm after 2FA', confirmParams, resultBody);
    _pendingOnStep = null;
    final resultJson = jsonDecode(resultBody) as Map<String, dynamic>;
    return _parseWizardResult(resultJson);
  }

  /// Parse all `<input type="hidden" ...>` tags from wizard HTML.
  static Map<String, String> _extractHiddenFields(String html) {
    final fields = <String, String>{};
    final pattern = RegExp(
      r'''<input[^>]*type=["']hidden["'][^>]*/?>''',
      caseSensitive: false,
    );
    final namePattern = RegExp(r'''name=["']([^"']*)["']''');
    final valuePattern = RegExp(r'''value=["']([^"']*)["']''');

    for (final match in pattern.allMatches(html)) {
      final tag = match.group(0)!;
      final nameMatch = namePattern.firstMatch(tag);
      final valueMatch = valuePattern.firstMatch(tag);
      if (nameMatch != null) {
        fields[nameMatch.group(1)!] = valueMatch?.group(1) ?? '';
      }
    }
    return fields;
  }

  /// Extract the first outgoing number option from wizard HTML.
  static String _extractFirstOutgoingNumber(String html) {
    // Look for selected option in outgoing number select, or first Sip option
    final selected = RegExp(
      r'''<option[^>]*selected[^>]*value=["'](Sip\d+)["']''',
    ).firstMatch(html);
    if (selected != null) return selected.group(1)!;

    final first = RegExp(
      r'''value=["'](Sip\d+)["']''',
    ).firstMatch(html);
    return first?.group(1) ?? 'Sip0';
  }

  FormResult _parseWizardResult(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) return const FormOk();

    final submitSave = data['Submit_Save'];
    if (submitSave == 'saveerror') {
      final saveerror = data['saveerror'] as Map<String, dynamic>? ?? {};
      final msg = saveerror['msg'] as String? ?? '';
      return FormValError(alert: msg, tomark: const []);
    }

    if (submitSave == 'twofactor') {
      final methods = data['twofactor'] as String? ?? '';
      return FormTwoFactor(methods: methods);
    }

    return const FormOk();
  }

  Map<String, String> _buildFields({
    required int ipIdx,
    required String username,
    required String password,
    required bool fromInet,
  }) {
    return <String, String>{
      'username': username,
      'password': password,
      'ip_idx': ipIdx.toString(),
      'back_to_page': '/fon_devices/fondevices_list.lua',
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
