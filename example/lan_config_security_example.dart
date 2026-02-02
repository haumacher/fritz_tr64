import 'dart:math';

import 'package:fritz_tr064/fritz_tr064.dart';

import 'config.dart';

/// Generate a random password meeting Fritz!Box requirements:
/// - 8-32 characters
/// - At least one digit, one uppercase, one lowercase, one special character
String generatePassword({int length = 16}) {
  const lowercase = 'abcdefghijklmnopqrstuvwxyz';
  const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const digits = '0123456789';
  const special = '!#%&()*+,-./:;<>?@[]^_{}|';
  const allChars = lowercase + uppercase + digits + special;

  final random = Random.secure();

  // Ensure at least one of each required character type
  final required = [
    lowercase[random.nextInt(lowercase.length)],
    uppercase[random.nextInt(uppercase.length)],
    digits[random.nextInt(digits.length)],
    special[random.nextInt(special.length)],
  ];

  // Fill the rest with random characters
  final remaining = List.generate(
    length - required.length,
    (_) => allChars[random.nextInt(allChars.length)],
  );

  // Combine and shuffle
  final password = required + remaining;
  password.shuffle(random);

  return password.join();
}

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

    // Create an app user with call log read-only access
    final appSetup = client.appSetup();
    if (appSetup == null) {
      print('\nAppSetup service not available - cannot create app user.');
      return;
    }

    final appId = 'calllog-reader-${DateTime.now().millisecondsSinceEpoch}';
    final username = 'calllog${Random().nextInt(10000)}';
    final password = generatePassword();

    print('\nCreating app user with call log access...');
    await appSetup.registerApp(
      appId: appId,
      appDisplayName: 'Call Log Reader',
      appDeviceMAC: '',
      appUsername: username,
      appPassword: password,
      appRight: AppRight.no,
      nasRight: AppRight.no,
      phoneRight: AppRight.ro, // Read-only access to call log
      homeautoRight: AppRight.no,
      appInternetRights: false,
    );

    print('\nApp user created successfully!');
    print('  Username: $username');
    print('  Password: $password');
    print('  Rights:   Phone (read-only)');
    print('\nThis user can access the call log via TR-064 or HTTPS.');
  } finally {
    client.close();
  }
}
