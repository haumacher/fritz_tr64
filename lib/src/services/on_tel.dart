import 'package:xml/xml.dart';

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

/// A phone number from a phonebook contact.
class PhoneNumber {
  final String number;
  final String type;
  final String quickdial;
  final String vanity;
  final int prio;

  PhoneNumber({
    required this.number,
    required this.type,
    this.quickdial = '',
    this.vanity = '',
    this.prio = 0,
  });

  @override
  String toString() => 'PhoneNumber($type: $number)';
}

/// A parsed phonebook contact entry.
class PhonebookEntry {
  final String name;
  final int? uniqueId;
  final int? category;
  final String? imageUrl;
  final List<PhoneNumber> numbers;
  final List<String> emails;

  PhonebookEntry({
    required this.name,
    this.uniqueId,
    this.category,
    this.imageUrl,
    this.numbers = const [],
    this.emails = const [],
  });

  /// Parse from the XML string returned by GetPhonebookEntry.
  factory PhonebookEntry.fromXml(String xml) {
    final document = XmlDocument.parse(xml);
    final contact = document.rootElement;

    // person > realName
    final person = _findChild(contact, 'person');
    final name = person != null ? _childText(person, 'realName') ?? '' : '';
    final imageUrl = person != null ? _childText(person, 'imageURL') : null;

    // category
    final categoryText = _childText(contact, 'category');
    final category = categoryText != null ? int.tryParse(categoryText) : null;

    // uniqueid
    final uniqueIdText = _childText(contact, 'uniqueid');
    final uniqueId = uniqueIdText != null ? int.tryParse(uniqueIdText) : null;

    // telephony > number elements
    final telephony = _findChild(contact, 'telephony');
    final numbers = <PhoneNumber>[];
    if (telephony != null) {
      for (final el in telephony.childElements
          .where((e) => e.localName == 'number')) {
        numbers.add(PhoneNumber(
          number: el.innerText,
          type: el.getAttribute('type') ?? '',
          quickdial: el.getAttribute('quickdial') ?? '',
          vanity: el.getAttribute('vanity') ?? '',
          prio: int.tryParse(el.getAttribute('prio') ?? '') ?? 0,
        ));
      }
    }

    // telephony > services > email elements
    final emails = <String>[];
    final services =
        telephony != null ? _findChild(telephony, 'services') : null;
    if (services != null) {
      for (final el in services.childElements
          .where((e) => e.localName == 'email')) {
        if (el.innerText.isNotEmpty) emails.add(el.innerText);
      }
    }

    return PhonebookEntry(
      name: name,
      uniqueId: uniqueId,
      category: category,
      imageUrl: imageUrl,
      numbers: numbers,
      emails: emails,
    );
  }

  @override
  String toString() => 'PhonebookEntry($name, ${numbers.length} numbers)';
}

XmlElement? _findChild(XmlElement parent, String localName) {
  for (final child in parent.childElements) {
    if (child.localName == localName) return child;
  }
  return null;
}

String? _childText(XmlElement parent, String localName) {
  final el = _findChild(parent, localName);
  if (el == null) return null;
  final text = el.innerText;
  return text.isEmpty ? null : text;
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
  Future<PhonebookEntry> getPhonebookEntry(
      int phonebookId, int entryId) async {
    final result = await call('GetPhonebookEntry', {
      'NewPhonebookID': phonebookId.toString(),
      'NewPhonebookEntryID': entryId.toString(),
    });
    return PhonebookEntry.fromXml(result['NewPhonebookEntryData'] ?? '');
  }

  /// Get a phonebook entry by its unique ID.
  Future<PhonebookEntry> getPhonebookEntryUID(
      int phonebookId, int uniqueId) async {
    final result = await call('GetPhonebookEntryUID', {
      'NewPhonebookID': phonebookId.toString(),
      'NewPhonebookEntryUniqueID': uniqueId.toString(),
    });
    return PhonebookEntry.fromXml(result['NewPhonebookEntryData'] ?? '');
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
