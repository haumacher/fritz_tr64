import 'dart:io';
import 'dart:math';

import 'package:fritz_tr064/fritz_tr064.dart';

import 'config.dart';

void main() async {
  final env = loadEnv('.env');
  final host = env['FRITZBOX_HOST']!;
  final username = env['FRITZBOX_USERNAME']!;
  final password = env['FRITZBOX_PASSWORD']!;

  // Generate a secure random password for the SIP device
  final sipPassword = _generatePassword(16);
  print('Generated SIP password: $sipPassword');

  // Use TR-064 only for read-only operations (no 2FA needed)
  final tr64 = Tr64Client(
    host: host,
    username: username,
    password: password,
  );
  await tr64.connect();

  try {
    final voip = tr64.voip()!;

    // Step 1: Check if a leftover test device exists
    final numberOfClients = await voip.getNumberOfClients();
    print('Number of existing clients: $numberOfClients');

    bool reusingExisting = false;
    if (numberOfClients > 0) {
      final last = await voip.getClient3(numberOfClients - 1);
      if (last.phoneName == 'Test Device') {
        print('Found leftover test device at index ${numberOfClients - 1}.');
        reusingExisting = true;
      }
    }

    // Step 2: Create or update device via web API (supports TOTP 2FA)
    print('\n--- Setting up SIP device via web API ---');
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

      int ipIdx;
      if (reusingExisting) {
        // Find the existing device by username
        final found = await ipPhone.findIpIdx('testuser');
        if (found != null) {
          ipIdx = found;
          print('Reusing existing device at ip_idx=$ipIdx');
        } else {
          // Fallback: create new
          ipIdx = await ipPhone.getIpPhoneCount();
          print('Leftover not found by username, creating at ip_idx=$ipIdx');
        }
      } else {
        ipIdx = await ipPhone.getIpPhoneCount();
        print('Creating new device at ip_idx=$ipIdx');
      }

      // Submit form: create/update device with internet access enabled
      print('Submitting form (username=testuser, from_inet=on)...');
      var result = await ipPhone.saveCredentials(
        ipIdx: ipIdx,
        username: 'testuser',
        password: sipPassword,
        fromInet: true,
        phoneName: 'Test Device',
      );

      result = await _handle2FA(result, twoFactor, () {
        return ipPhone.confirmAndSave(
          ipIdx: ipIdx,
          username: 'testuser',
          password: sipPassword,
          fromInet: true,
          phoneName: 'Test Device',
        );
      });

      switch (result) {
        case FormOk():
          print('Device saved successfully.');
        case FormValError(:final alert):
          print('Validation error: $alert');
          return;
        case FormTwoFactor():
          print('2FA was not confirmed.');
          return;
      }
    } finally {
      await webClient.close();
    }

    // Step 3: Read back and verify via TR-064
    // Re-read client count since we may have created a new one
    final newCount = await voip.getNumberOfClients();
    for (int i = 0; i < newCount; i++) {
      final c = await voip.getClient3(i);
      if (c.clientUsername == 'testuser') {
        print('\nDevice config (TR-064 read-back):');
        print('  ClientIndex: ${c.clientIndex}');
        print('  Username: ${c.clientUsername}');
        print('  PhoneName: ${c.phoneName}');
        print('  External registration: ${c.externalRegistration}');
        print('  Internal number: ${c.internalNumber}');
        break;
      }
    }

    print('\nDone — check the Fritz!Box web UI to verify internet access.');
  } finally {
    tr64.close();
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
