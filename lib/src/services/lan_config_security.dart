import 'package:xml/xml.dart';

import '../client.dart';
import '../service.dart';

/// Access level for a user right.
enum AccessRight {
  /// No access.
  none('none'),

  /// Read-only access.
  readonly('readonly'),

  /// Read and write access.
  readwrite('readwrite');

  final String _value;
  const AccessRight(this._value);

  /// Parse an access right string returned by the Fritz!Box.
  ///
  /// Returns `null` for unknown values.
  static AccessRight? tryParse(String value) {
    for (final a in values) {
      if (a._value == value) return a;
    }
    return null;
  }

  @override
  String toString() => _value;
}

/// A single user right entry.
class UserRight {
  /// The path/category of the right (e.g., "BoxAdmin", "Phone", "NAS").
  final String path;

  /// The access level for this path.
  final AccessRight? access;

  UserRight({
    required this.path,
    required this.access,
  });

  @override
  String toString() => 'UserRight($path: $access)';
}

/// A user entry from the user list.
class User {
  /// The username.
  final String username;

  /// Whether this was the last user to log in.
  final bool lastUser;

  User({
    required this.username,
    required this.lastUser,
  });

  @override
  String toString() => 'User($username${lastUser ? ', lastUser' : ''})';
}

/// Result of LANConfigSecurity:GetInfo action.
///
/// Contains password and username constraints.
class LanConfigSecurityInfo {
  /// Maximum number of characters allowed in a password.
  final int maxCharsPassword;

  /// Minimum number of characters required in a password.
  final int minCharsPassword;

  /// Characters allowed in passwords.
  final String allowedCharsPassword;

  /// Characters allowed in usernames.
  final String allowedCharsUsername;

  /// Whether at least one user has a default password active.
  final bool isDefaultPasswordActive;

  LanConfigSecurityInfo({
    required this.maxCharsPassword,
    required this.minCharsPassword,
    required this.allowedCharsPassword,
    required this.allowedCharsUsername,
    required this.isDefaultPasswordActive,
  });

  factory LanConfigSecurityInfo.fromArguments(Map<String, String> args) {
    return LanConfigSecurityInfo(
      maxCharsPassword: int.tryParse(args['NewMaxCharsPassword'] ?? '') ?? 0,
      minCharsPassword: int.tryParse(args['NewMinCharsPassword'] ?? '') ?? 0,
      allowedCharsPassword: args['NewAllowedCharsPassword'] ?? '',
      allowedCharsUsername: args['NewAllowedCharsUsername'] ?? '',
      isDefaultPasswordActive:
          args['NewX_AVM-DE_IsDefaultPasswordActive'] == '1',
    );
  }

  @override
  String toString() =>
      'LanConfigSecurityInfo(password=$minCharsPassword-$maxCharsPassword chars)';
}

/// Result of X_AVM-DE_GetCurrentUser action.
///
/// Contains the current username and their rights.
class CurrentUser {
  /// The current username (may be empty if anonymous login is used).
  final String username;

  /// The rights of the current user.
  final List<UserRight> rights;

  CurrentUser({
    required this.username,
    required this.rights,
  });

  factory CurrentUser.fromArguments(Map<String, String> args) {
    final username = args['NewX_AVM-DE_CurrentUsername'] ?? '';
    final rightsXml = args['NewX_AVM-DE_CurrentUserRights'] ?? '';
    final rights = _parseUserRights(rightsXml);
    return CurrentUser(username: username, rights: rights);
  }

  @override
  String toString() => 'CurrentUser($username, ${rights.length} rights)';
}

/// Parse user rights from XML string.
///
/// Example XML:
/// ```xml
/// <rights>
///   <path>BoxAdmin</path>
///   <access>none</access>
///   <path>Phone</path>
///   <access>readwrite</access>
/// </rights>
/// ```
List<UserRight> _parseUserRights(String xml) {
  if (xml.isEmpty) return [];
  try {
    final document = XmlDocument.parse(xml);
    final rights = <UserRight>[];
    final rightsElement = document.rootElement;
    if (rightsElement.name.local != 'rights') return [];

    final children = rightsElement.children
        .whereType<XmlElement>()
        .toList();

    // Rights are pairs of <path> and <access> elements
    for (var i = 0; i < children.length - 1; i += 2) {
      final pathElement = children[i];
      final accessElement = children[i + 1];
      if (pathElement.name.local == 'path' &&
          accessElement.name.local == 'access') {
        rights.add(UserRight(
          path: pathElement.innerText,
          access: AccessRight.tryParse(accessElement.innerText),
        ));
      }
    }
    return rights;
  } catch (_) {
    return [];
  }
}

/// Parse user list from XML string.
///
/// Example XML:
/// ```xml
/// <List>
///   <Username last_user="1">John</Username>
///   <Username last_user="0">PowerLine</Username>
/// </List>
/// ```
List<User> _parseUserList(String xml) {
  if (xml.isEmpty) return [];
  try {
    final document = XmlDocument.parse(xml);
    final users = <User>[];
    final listElement = document.rootElement;
    if (listElement.name.local != 'List') return [];

    for (final child in listElement.children.whereType<XmlElement>()) {
      if (child.name.local == 'Username') {
        users.add(User(
          username: child.innerText,
          lastUser: child.getAttribute('last_user') == '1',
        ));
      }
    }
    return users;
  } catch (_) {
    return [];
  }
}

/// TR-064 LANConfigSecurity service.
///
/// Service type: urn:dslforum-org:service:LANConfigSecurity:1
///
/// Provides methods for managing LAN configuration security settings,
/// including password policies, user management, and authentication.
class LanConfigSecurityService extends Tr64Service {
  LanConfigSecurityService({
    required super.description,
    required super.callAction,
    required super.fetchUrl,
  });

  /// Get password and username constraints.
  ///
  /// Returns information about allowed characters and length constraints
  /// for passwords and usernames, and whether a default password is active.
  Future<LanConfigSecurityInfo> getInfo() async {
    final result = await call('GetInfo');
    return LanConfigSecurityInfo.fromArguments(result);
  }

  /// Check if anonymous login is enabled.
  ///
  /// This action can be invoked without authentication.
  Future<bool> getAnonymousLogin() async {
    final result = await call('X_AVM-DE_GetAnonymousLogin');
    return result['NewX_AVM-DE_AnonymousLoginEnabled'] == '1';
  }

  /// Get the current authenticated user and their rights.
  ///
  /// The username may be empty if anonymous login is enabled and the client
  /// authenticated with an arbitrary username.
  Future<CurrentUser> getCurrentUser() async {
    final result = await call('X_AVM-DE_GetCurrentUser');
    return CurrentUser.fromArguments(result);
  }

  /// Set the configuration password.
  ///
  /// Note: Changing the password may take up to 20 seconds.
  Future<void> setConfigPassword(String password) async {
    await call('SetConfigPassword', {
      'NewPassword': password,
    });
  }

  /// Get the list of all configured users.
  ///
  /// Each user has a `lastUser` flag indicating whether they were the
  /// most recent user to log in.
  Future<List<User>> getUserList() async {
    final result = await call('X_AVM-DE_GetUserList');
    final xml = result['NewX_AVM-DE_UserList'] ?? '';
    return _parseUserList(xml);
  }
}

/// Extension on [Tr64Client] to access the LANConfigSecurity service.
extension LanConfigSecurityClientExtension on Tr64Client {
  /// Create a [LanConfigSecurityService] for managing security settings.
  ///
  /// Requires [Tr64Client.connect] to have been called first.
  LanConfigSecurityService? lanConfigSecurity() {
    if (description == null) return null;
    final desc = description!.findByType(
      'urn:dslforum-org:service:LANConfigSecurity:1',
    );
    if (desc == null) return null;
    return LanConfigSecurityService(
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
