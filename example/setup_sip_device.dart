import 'dart:io';
import 'dart:math';

import 'package:fritz_tr064/fritz_tr064.dart';

import 'config.dart';

void main() async {
  final env = loadEnv('.env');
  final host = env['FRITZBOX_HOST']!;
  final username = env['FRITZBOX_USERNAME']!;
  final password = env['FRITZBOX_PASSWORD']!;

  // SIP device credentials
  stdout.write('SIP username: ');
  final sipUsername = stdin.readLineSync()?.trim() ?? '';
  if (sipUsername.isEmpty) {
    print('Username must not be empty.');
    return;
  }
  final sipPassword = _generatePassword(16);
  print('Generated SIP password: $sipPassword');

  stdout.write('Outgoing number index (-1=none, 0=first, empty=default): ');
  final outInput = stdin.readLineSync()?.trim() ?? '';
  final int? outgoingNumber = outInput.isEmpty ? null : int.parse(outInput);

  await _printSipClient(host, username, password, sipUsername,
      header: '--- SIP client before creation ---');

  // Step 1: Create device via web API wizard (supports TOTP 2FA)
  print('\n--- Creating SIP device via web API wizard ---');
  final webClient = FritzWebClient(
    host: host,
    username: username,
    password: password,
  );
  await webClient.login();
  print('Logged in, SID: ${webClient.sid}');

  try {
    final ipPhone = IpPhoneService(webClient);
    final twoFactor = WebTwoFactor(webClient);

    var result = await ipPhone.createIpPhone(
      name: 'Test SIP Phone',
      username: sipUsername,
      password: sipPassword,
      outgoingNumber: outgoingNumber,
      onStep: _onWizardStep,
    );

    result = await _handle2FA(result, twoFactor, () => ipPhone.confirmCreate());

    switch (result) {
      case FormOk():
        print('Device created successfully.');
      case FormValError(:final alert):
        print('Validation error: $alert');
        return;
      case FormTwoFactor():
        print('2FA was not confirmed.');
        return;
    }

    // Optionally enable internet access for the new device
    final ipIdx = await ipPhone.findIpIdx(sipUsername);
    if (ipIdx != null) {
      final creds = await ipPhone.getCredentials(ipIdx);
      if (!creds.fromInet) {
        print('\nEnabling internet access...');
        var saveResult = await ipPhone.saveCredentials(
          ipIdx: ipIdx,
          username: sipUsername,
          password: sipPassword,
          fromInet: true,
        );
        saveResult = await _handle2FA(saveResult, twoFactor, () {
          return ipPhone.confirmAndSave(
            ipIdx: ipIdx,
            username: sipUsername,
            password: sipPassword,
            fromInet: true,
          );
        });
        switch (saveResult) {
          case FormOk():
            print('Internet access enabled.');
          case FormValError(:final alert):
            print('Failed to enable internet access: $alert');
          case FormTwoFactor():
            print('2FA was not confirmed for internet access.');
        }
      }
    }
  } finally {
    await webClient.close();
  }

  // Step 2: Read back and verify via TR-064
  await _printSipClient(host, username, password, sipUsername,
      header: '--- SIP client after creation ---');

  print('\nDone — check the Fritz!Box web UI to verify the device.');
}

/// Looks up a SIP client by username via TR-064 and prints its details.
Future<void> _printSipClient(
  String host,
  String username,
  String password,
  String sipUsername, {
  required String header,
}) async {
  print('\n$header');
  final tr64 = Tr64Client(host: host, username: username, password: password);
  await tr64.connect();
  try {
    final voip = tr64.voip()!;
    final count = await voip.getNumberOfClients();
    for (int i = 0; i < count; i++) {
      final c = await voip.getClient3(i);
      if (c.clientUsername == sipUsername) {
        print('  ClientIndex: ${c.clientIndex}');
        print('  Username: ${c.clientUsername}');
        print('  PhoneName: ${c.phoneName}');
        print('  External registration: ${c.externalRegistration}');
        print('  Internal number: ${c.internalNumber}');
        return;
      }
    }
    print('  SIP client "$sipUsername" not found.');
  } finally {
    tr64.close();
  }
}

/// Human-readable label for a wizard step.
String _stepLabel(WizardStep step) => switch (step) {
      WizardStep.loadWizardStart => 'Load wizard start',
      WizardStep.selectDeviceType => 'Select device type',
      WizardStep.loadPhoneWizard => 'Load phone wizard',
      WizardStep.selectPortAndName => 'Port + name',
      WizardStep.enterCredentials => 'Credentials',
      WizardStep.selectOutgoingNumber => 'Outgoing number',
      WizardStep.selectIncomingNumbers => 'Incoming numbers',
      WizardStep.save => 'Save',
      WizardStep.confirmAfter2FA => 'Confirm after 2FA',
    };

/// Logs wizard step progress.
void _onWizardStep(
  WizardStep step,
  Map<String, String> params,
  Map<String, String> state,
  String responseBody,
) {
  print('  [${step.name}] ${_stepLabel(step)}');
  if (state.isNotEmpty) {
    print('    state: $state');
  }
  if (responseBody.trimLeft().startsWith('{')) {
    print('    $responseBody');
  } else {
    print('    (${responseBody.length} bytes HTML)');
  }
}

/// Handles 2FA if the form result requires it.
///
/// If [result] is [FormTwoFactor], presents available methods and waits
/// for confirmation, then calls [confirmAndSave] to re-submit.
/// Returns the final [FormResult].
Future<FormResult> _handle2FA(
  FormResult result,
  WebTwoFactor twoFactor,
  Future<FormResult> Function() confirmAndSave,
) async {
  if (result is! FormTwoFactor) return result;

  print('\n2FA required. Available methods:');
  final methods = twoFactor.parseMethods(result.methods);
  final confirmed = await _performWebApi2FA(twoFactor, methods);

  if (!confirmed) return result;

  print('2FA confirmed, re-submitting form to save...');
  return confirmAndSave();
}

/// Presents 2FA method choices, handles user interaction, and waits for
/// confirmation. Returns `true` if confirmed, `false` otherwise.
Future<bool> _performWebApi2FA(
  WebTwoFactor twoFactor,
  List<AuthMethod> methods,
) async {
  String? dtmfCode;
  bool hasButton = false;
  bool hasTotp = false;

  for (final method in methods) {
    switch (method) {
      case AuthMethodButton():
        hasButton = true;
      case AuthMethodDtmf(:final sequence):
        dtmfCode = sequence;
      case AuthMethodTotp():
        hasTotp = true;
      case AuthMethodUnknown():
        break;
    }
  }

  // Check if TOTP is configured
  bool totpConfigured = false;
  if (hasTotp) {
    final info = await twoFactor.getGoogleAuthInfo();
    if (info != null && info.isConfigured && info.isAvailable) {
      totpConfigured = true;
      print('Google Authenticator configured on: ${info.deviceName}');
    }
  }

  // Present choices
  final options = <String>[];
  if (hasButton) {
    options.add('button');
    print('  [${options.length}] Press any button on the Fritz!Box');
  }
  if (dtmfCode != null) {
    options.add('dtmf');
    print('  [${options.length}] Dial *1$dtmfCode on a connected phone');
  }
  if (totpConfigured) {
    options.add('totp');
    print('  [${options.length}] Enter TOTP code from Authenticator app');
  }

  if (options.isEmpty) {
    print('No usable 2FA methods available.');
    return false;
  }

  stdout.write('Choose method [1-${options.length}]: ');
  final choice = int.tryParse(stdin.readLineSync() ?? '');
  if (choice == null || choice < 1 || choice > options.length) {
    print('Invalid choice.');
    return false;
  }

  final selected = options[choice - 1];

  if (selected == 'totp') {
    stdout.write('Enter 6-digit TOTP code: ');
    final code = stdin.readLineSync()?.trim() ?? '';
    if (code.length != 6) {
      print('Invalid code length.');
      return false;
    }
    final success = await twoFactor.submitTotp(code);
    if (!success) {
      print('Wrong TOTP code.');
      return false;
    }
  } else {
    if (selected == 'button') {
      print('Press any button on the Fritz!Box now...');
    } else {
      print('Dial *1$dtmfCode on a connected phone now...');
    }
  }

  // Poll until confirmed
  print('Waiting for confirmation...');
  for (int i = 0; i < 120; i++) {
    await Future.delayed(const Duration(seconds: 1));
    final result = await twoFactor.poll();
    if (result.done) {
      return result.active == true;
    }
  }

  print('2FA timed out.');
  return false;
}

/// Generates a secure random password of the given [length].
String _generatePassword(int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rng = Random.secure();
  return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
}
