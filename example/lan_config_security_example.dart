import 'package:fritz_tr064/fritz_tr064.dart';

import 'config.dart';

void main() async {
  final client = await createClient();

  try {
    final security = client.lanConfigSecurity();
    if (security == null) {
      print('LANConfigSecurity service not available on this device.');
      return;
    }

    // Password/username constraints
    print('Security settings:');
    final info = await security.getInfo();
    print('  Password: ${info.minCharsPassword}-${info.maxCharsPassword} chars');
    print('  Default password active: ${info.isDefaultPasswordActive}');

    // Anonymous login status
    final anonymousLogin = await security.getAnonymousLogin();
    print('  Anonymous login enabled: $anonymousLogin');

    // Current user and rights
    print('\nCurrent user:');
    final currentUser = await security.getCurrentUser();
    if (currentUser.username.isEmpty) {
      print('  (anonymous or no username)');
    } else {
      print('  Username: ${currentUser.username}');
    }
    if (currentUser.rights.isNotEmpty) {
      print('  Rights:');
      for (final right in currentUser.rights) {
        print('    ${right.path}: ${right.access}');
      }
    }

    // List all registered users
    print('\nRegistered users:');
    final users = await security.getUserList();
    if (users.isEmpty) {
      print('  (no users found)');
    } else {
      for (final user in users) {
        final marker = user.lastUser ? ' (last login)' : '';
        print('  - ${user.username}$marker');
      }
    }
  } finally {
    client.close();
  }
}
