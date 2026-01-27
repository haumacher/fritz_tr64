import '../client.dart';
import '../service.dart';

/// Result of OnTel:GetPhonebook action.
class Phonebook {
  final String url;
  final String name;
  final String extraId;

  Phonebook({
    required this.url,
    required this.name,
    required this.extraId,
  });

  factory Phonebook.fromArguments(Map<String, String> args) {
    return Phonebook(
      url: args['NewPhonebookURL'] ?? '',
      name: args['NewPhonebookName'] ?? '',
      extraId: args['NewPhonebookExtraID'] ?? '',
    );
  }

  @override
  String toString() => 'Phonebook($name, $url)';
}

/// TR-064 X_AVM-DE_OnTel service (contacts / phonebook).
///
/// Service type: urn:dslforum-org:service:X_AVM-DE_OnTel:1
class OnTelService extends Tr64Service {
  OnTelService({
    required super.description,
    required super.callAction,
  });

  /// Get the URL for the call list.
  Future<String> getCallList() async {
    final result = await call('GetCallList');
    return result['NewCallListURL'] ?? '';
  }

  /// Get a list of available phonebook IDs.
  Future<List<int>> getPhonebookList() async {
    final result = await call('GetPhonebookList');
    final csv = result['NewPhonebookList'] ?? '';
    if (csv.isEmpty) return [];
    return csv.split(',').map((s) => int.parse(s.trim())).toList();
  }

  /// Get phonebook metadata by ID.
  Future<Phonebook> getPhonebook(int phonebookId) async {
    final result = await call('GetPhonebook', {
      'NewPhonebookID': phonebookId.toString(),
    });
    return Phonebook.fromArguments(result);
  }

  /// Get a phonebook entry by its index within a phonebook.
  Future<String> getPhonebookEntry(int phonebookId, int entryId) async {
    final result = await call('GetPhonebookEntry', {
      'NewPhonebookID': phonebookId.toString(),
      'NewPhonebookEntryID': entryId.toString(),
    });
    return result['NewPhonebookEntryData'] ?? '';
  }

  /// Get a phonebook entry by its unique ID.
  Future<String> getPhonebookEntryUID(int phonebookId, int uniqueId) async {
    final result = await call('GetPhonebookEntryUID', {
      'NewPhonebookID': phonebookId.toString(),
      'NewPhonebookEntryUniqueID': uniqueId.toString(),
    });
    return result['NewPhonebookEntryData'] ?? '';
  }

  /// Get the total number of phonebook entries.
  Future<int> getNumberOfEntries() async {
    final result = await call('GetNumberOfEntries');
    return int.parse(result['NewOnTelNumberOfEntries'] ?? '0');
  }
}

/// Extension on [Tr64Client] to access the OnTel (phonebook) service.
extension OnTelClientExtension on Tr64Client {
  /// Create an [OnTelService] for querying phonebooks and call lists.
  ///
  /// Requires [Tr64Client.connect] to have been called first.
  OnTelService? onTel() {
    if (description == null) return null;
    final desc = description!.findByType(
      'urn:dslforum-org:service:X_AVM-DE_OnTel:1',
    );
    if (desc == null) return null;
    return OnTelService(
      description: desc,
      callAction: (serviceType, controlUrl, actionName, arguments) => call(
        serviceType: serviceType,
        controlUrl: controlUrl,
        actionName: actionName,
        arguments: arguments,
      ),
    );
  }
}
