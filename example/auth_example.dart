import 'package:fritz_tr064/fritz_tr064.dart';

import 'config.dart';

void main() async {
  final client = await createClient();

  try {
    final auth = client.auth();
    if (auth == null) {
      print('X_AVM-DE_Auth service not available on this device.');
      return;
    }

    // Check whether 2FA is enabled
    final enabled = await auth.getInfo();
    print('Second-factor authentication enabled: $enabled');

    // Print the current state
    final state = await auth.getState();
    print('Current state: ${state.name}');

    if (!enabled) {
      print('2FA is disabled — nothing more to do.');
      return;
    }

    // Start a second-factor authentication process
    print('\nStarting authentication...');
    final startResult = await auth.setConfig('start');
    print('State: ${startResult.state.name}');
    print('Token: ${startResult.token}');
    print('Methods:');
    for (final method in startResult.methods) {
      switch (method) {
        case AuthMethodButton():
          print('  - button: press any button on the device');
        case AuthMethodDtmf(:final sequence):
          print('  - dtmf: enter $sequence on a connected phone');
        case AuthMethodUnknown(:final raw):
          print('  - unknown: $raw');
      }
    }

    // Stop the authentication process
    print('\nStopping authentication...');
    final stopResult = await auth.setConfig('stop');
    print('State: ${stopResult.state.name}');
  } finally {
    client.close();
  }
}
