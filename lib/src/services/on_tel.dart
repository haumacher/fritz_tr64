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

/// Well-known phone number types per the TR-064 contact spec.
enum PhoneNumberType {
  home,
  mobile,
  work,
  intern;

  /// Parse a type attribute value from XML.
  ///
  /// Returns the matching enum value, or `null` for unknown types.
  static PhoneNumberType? tryParse(String value) {
    for (final t in values) {
      if (t.name == value) return t;
    }
    return null;
  }
}

/// A phone number from a phonebook contact.
class PhoneNumber {
  final String number;
  final PhoneNumberType type;
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
  String toString() => 'PhoneNumber(${type.name}: $number)';
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

  /// Serialize this entry to an XML `<contact>` string.
  String toXml() {
    final builder = XmlBuilder();
    builder.element('contact', nest: () {
      if (category != null) {
        builder.element('category', nest: category.toString());
      }
      builder.element('person', nest: () {
        builder.element('realName', nest: name);
        if (imageUrl != null) {
          builder.element('imageURL', nest: imageUrl!);
        }
      });
      if (numbers.isNotEmpty || emails.isNotEmpty) {
        builder.element('telephony', nest: () {
          for (final n in numbers) {
            builder.element('number', attributes: {
              'type': n.type.name,
              if (n.prio != 0) 'prio': n.prio.toString(),
              if (n.quickdial.isNotEmpty) 'quickdial': n.quickdial,
              if (n.vanity.isNotEmpty) 'vanity': n.vanity,
            }, nest: n.number);
          }
          if (emails.isNotEmpty) {
            builder.element('services', nest: () {
              for (final email in emails) {
                builder.element('email', nest: email);
              }
            });
          }
        });
      }
      if (uniqueId != null) {
        builder.element('uniqueid', nest: uniqueId.toString());
      }
    });
    return builder.buildDocument().rootElement.toXmlString();
  }

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
        final type = PhoneNumberType.tryParse(el.getAttribute('type') ?? '');
        if (type == null) continue; // skip unknown types
        numbers.add(PhoneNumber(
          number: el.innerText,
          type: type,
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

/// Information about an online (remote) phonebook account.
class OnlinePhonebookInfo {
  final bool enable;
  final String status;
  final String lastConnect;
  final String url;
  final String serviceId;
  final String username;
  final String name;

  OnlinePhonebookInfo({
    required this.enable,
    required this.status,
    required this.lastConnect,
    required this.url,
    required this.serviceId,
    required this.username,
    required this.name,
  });

  factory OnlinePhonebookInfo.fromArguments(Map<String, String> args) {
    return OnlinePhonebookInfo(
      enable: args['NewEnable'] == '1',
      status: args['NewStatus'] ?? '',
      lastConnect: args['NewLastConnect'] ?? '',
      url: args['NewUrl'] ?? '',
      serviceId: args['NewServiceId'] ?? '',
      username: args['NewUsername'] ?? '',
      name: args['NewName'] ?? '',
    );
  }

  @override
  String toString() => 'OnlinePhonebookInfo($name, $url)';
}

/// Information about a DECT handset.
class DectHandsetInfo {
  final String handsetName;
  final int phonebookId;

  DectHandsetInfo({
    required this.handsetName,
    required this.phonebookId,
  });

  @override
  String toString() => 'DectHandsetInfo($handsetName, phonebook=$phonebookId)';
}

/// A call deflection rule.
class Deflection {
  final bool enable;
  final String type;
  final String number;
  final String deflectionToNumber;
  final String mode;
  final String outgoing;
  final int? phonebookId;

  Deflection({
    required this.enable,
    required this.type,
    required this.number,
    required this.deflectionToNumber,
    required this.mode,
    required this.outgoing,
    this.phonebookId,
  });

  factory Deflection.fromArguments(Map<String, String> args) {
    final pbIdStr = args['NewPhonebookID'];
    return Deflection(
      enable: args['NewEnable'] == '1',
      type: args['NewType'] ?? '',
      number: args['NewNumber'] ?? '',
      deflectionToNumber: args['NewDeflectionToNumber'] ?? '',
      mode: args['NewMode'] ?? '',
      outgoing: args['NewOutgoing'] ?? '',
      phonebookId:
          pbIdStr != null && pbIdStr.isNotEmpty ? int.tryParse(pbIdStr) : null,
    );
  }

  @override
  String toString() => 'Deflection($type, $number -> $deflectionToNumber)';
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

  /// Add a new phonebook.
  ///
  /// [extraId] is optional and can make a phonebook unique.
  Future<void> addPhonebook(String name, {String extraId = ''}) async {
    await call('AddPhonebook', {
      'NewPhonebookName': name,
      'NewPhonebookExtraID': extraId,
    });
  }

  /// Delete a phonebook by ID.
  ///
  /// The default phonebook (ID 0) cannot be deleted; instead all its
  /// entries are removed and it becomes empty.
  /// [extraId] is optional.
  Future<void> deletePhonebook(int phonebookId, {String extraId = ''}) async {
    await call('DeletePhonebook', {
      'NewPhonebookID': phonebookId.toString(),
      'NewPhonebookExtraID': extraId,
    });
  }

  /// Add or update a phonebook entry by entry index.
  ///
  /// To add a new entry, pass an empty string for [entryId].
  Future<void> setPhonebookEntry(
      int phonebookId, String entryId, PhonebookEntry entry) async {
    await call('SetPhonebookEntry', {
      'NewPhonebookID': phonebookId.toString(),
      'NewPhonebookEntryID': entryId,
      'NewPhonebookEntryData': entry.toXml(),
    });
  }

  /// Add or update a phonebook entry by unique ID.
  ///
  /// To add a new entry, leave [PhonebookEntry.uniqueId] as null.
  /// Returns the unique ID of the new or changed entry.
  Future<int> setPhonebookEntryUID(
      int phonebookId, PhonebookEntry entry) async {
    final result = await call('SetPhonebookEntryUID', {
      'NewPhonebookID': phonebookId.toString(),
      'NewPhonebookEntryData': entry.toXml(),
    });
    return int.parse(result['NewPhonebookEntryUniqueID'] ?? '0');
  }

  /// Delete a phonebook entry by its index.
  Future<void> deletePhonebookEntry(int phonebookId, int entryId) async {
    await call('DeletePhonebookEntry', {
      'NewPhonebookID': phonebookId.toString(),
      'NewPhonebookEntryID': entryId.toString(),
    });
  }

  /// Delete a phonebook entry by its unique ID.
  Future<void> deletePhonebookEntryUID(int phonebookId, int uniqueId) async {
    await call('DeletePhonebookEntryUID', {
      'NewPhonebookID': phonebookId.toString(),
      'NewPhonebookEntryUniqueID': uniqueId.toString(),
    });
  }

  /// Get the total number of phonebook entries.
  Future<int> getNumberOfEntries() async {
    final result = await call('GetNumberOfEntries');
    return int.parse(result['NewOnTelNumberOfEntries'] ?? '0');
  }

  // -- Call barring --

  /// Get a call barring entry by its entry ID.
  Future<PhonebookEntry> getCallBarringEntry(int entryId) async {
    final result = await call('GetCallBarringEntry', {
      'NewPhonebookEntryID': entryId.toString(),
    });
    return PhonebookEntry.fromXml(result['NewPhonebookEntryData'] ?? '');
  }

  /// Get a call barring entry by phone number.
  ///
  /// Throws a SOAP fault (714) if the number exists in the phonebook
  /// but not in the call barring list.
  Future<PhonebookEntry> getCallBarringEntryByNum(String number) async {
    final result = await call('GetCallBarringEntryByNum', {
      'NewNumber': number,
    });
    return PhonebookEntry.fromXml(result['NewPhonebookEntryData'] ?? '');
  }

  /// Get the URL to an XML file containing all call barring entries.
  Future<String> getCallBarringList() async {
    final result = await call('GetCallBarringList');
    return result['NewPhonebookURL'] ?? '';
  }

  /// Add or update a call barring entry.
  ///
  /// Returns the unique ID of the new or changed entry.
  Future<int> setCallBarringEntry(PhonebookEntry entry) async {
    final result = await call('SetCallBarringEntry', {
      'NewPhonebookEntryData': entry.toXml(),
    });
    return int.parse(result['NewPhonebookEntryUniqueID'] ?? '0');
  }

  /// Delete a call barring entry by its unique ID.
  Future<void> deleteCallBarringEntryUID(int uniqueId) async {
    await call('DeleteCallBarringEntryUID', {
      'NewPhonebookEntryUniqueID': uniqueId.toString(),
    });
  }

  // -- Online phonebook management --

  /// Get information about an online phonebook account by index.
  Future<OnlinePhonebookInfo> getInfoByIndex(int index) async {
    final result = await call('GetInfoByIndex', {
      'NewIndex': index.toString(),
    });
    return OnlinePhonebookInfo.fromArguments(result);
  }

  /// Enable or disable an online phonebook account.
  ///
  /// Switching from false to true triggers synchronization.
  Future<void> setEnableByIndex(int index, bool enable) async {
    await call('SetEnableByIndex', {
      'NewIndex': index.toString(),
      'NewEnable': enable ? '1' : '0',
    });
  }

  /// Configure an online phonebook account.
  ///
  /// If [index] addresses an existing account, the configuration is changed.
  /// If [index] is `numberOfEntries + 1`, a new account is created.
  Future<void> setConfigByIndex({
    required int index,
    required bool enable,
    required String url,
    required String serviceId,
    required String username,
    required String password,
    required String name,
  }) async {
    await call('SetConfigByIndex', {
      'NewIndex': index.toString(),
      'NewEnable': enable ? '1' : '0',
      'NewUrl': url,
      'NewServiceId': serviceId,
      'NewUsername': username,
      'NewPassword': password,
      'NewName': name,
    });
  }

  /// Delete an online phonebook account by index.
  Future<void> deleteByIndex(int index) async {
    await call('DeleteByIndex', {
      'NewIndex': index.toString(),
    });
  }

  // -- DECT handsets --

  /// Get a list of DECT handset IDs.
  Future<List<String>> getDectHandsetList() async {
    final result = await call('GetDECTHandsetList');
    final csv = result['NewDectIDList'] ?? '';
    if (csv.isEmpty) return [];
    return csv.split(',').map((s) => s.trim()).toList();
  }

  /// Get information about a DECT handset.
  Future<DectHandsetInfo> getDectHandsetInfo(String dectId) async {
    final result = await call('GetDECTHandsetInfo', {
      'NewDectID': dectId,
    });
    return DectHandsetInfo(
      handsetName: result['NewHandsetName'] ?? '',
      phonebookId: int.parse(result['NewPhonebookID'] ?? '0'),
    );
  }

  /// Assign a phonebook to a DECT handset.
  Future<void> setDectHandsetPhonebook(String dectId, int phonebookId) async {
    await call('SetDECTHandsetPhonebook', {
      'NewDectID': dectId,
      'NewPhonebookID': phonebookId.toString(),
    });
  }

  // -- Deflections --

  /// Get the number of call deflection rules.
  Future<int> getNumberOfDeflections() async {
    final result = await call('GetNumberOfDeflections');
    return int.parse(result['NewNumberOfDeflections'] ?? '0');
  }

  /// Get a single deflection rule by index (0-based).
  Future<Deflection> getDeflection(int deflectionId) async {
    final result = await call('GetDeflection', {
      'NewDeflectionId': deflectionId.toString(),
    });
    return Deflection.fromArguments(result);
  }

  /// Get the full deflection list as an XML string.
  Future<String> getDeflections() async {
    final result = await call('GetDeflections');
    return result['NewDeflectionList'] ?? '';
  }

  /// Enable or disable a deflection rule.
  Future<void> setDeflectionEnable(int deflectionId, bool enable) async {
    await call('SetDeflectionEnable', {
      'NewDeflectionId': deflectionId.toString(),
      'NewEnable': enable ? '1' : '0',
    });
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
