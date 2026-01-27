import 'package:xml/xml.dart';

import '../client.dart';
import '../service.dart';

/// Operating mode of a telephone answering machine.
enum TAMMode {
  /// Play announcement only (no recording).
  playAnnouncement('play_announcement'),

  /// Record messages after announcement.
  recordMessage('record_message'),

  /// Use a time-based profile.
  timeprofile('timeprofile');

  final String _value;
  const TAMMode(this._value);

  /// Parse a mode string returned by the Fritz!Box.
  ///
  /// Returns `null` for unknown values.
  static TAMMode? tryParse(String value) {
    for (final m in values) {
      if (m._value == value) return m;
    }
    return null;
  }

  @override
  String toString() => _value;
}

/// Result of X_AVM-DE_TAM:GetInfo action.
class TAMInfo {
  /// Whether this answering machine is enabled.
  final bool enable;

  /// Display name of the answering machine.
  final String name;

  /// Whether the answering machine is currently running.
  final bool tamRunning;

  /// USB stick index (0 = internal memory).
  final int stick;

  /// Status code.
  final int status;

  /// Storage capacity in seconds.
  final int capacity;

  /// Operating mode.
  final TAMMode? mode;

  /// Number of seconds to ring before the TAM picks up.
  final int ringSeconds;

  /// Comma-separated phone numbers this TAM responds to.
  ///
  /// An empty string means all numbers.
  final String phoneNumbers;

  TAMInfo({
    required this.enable,
    required this.name,
    required this.tamRunning,
    required this.stick,
    required this.status,
    required this.capacity,
    required this.mode,
    required this.ringSeconds,
    required this.phoneNumbers,
  });

  factory TAMInfo.fromArguments(Map<String, String> args) {
    return TAMInfo(
      enable: args['NewEnable'] == '1',
      name: args['NewName'] ?? '',
      tamRunning: args['NewTAMRunning'] == '1',
      stick: int.tryParse(args['NewStick'] ?? '') ?? 0,
      status: int.tryParse(args['NewStatus'] ?? '') ?? 0,
      capacity: int.tryParse(args['NewCapacity'] ?? '') ?? 0,
      mode: TAMMode.tryParse(args['NewMode'] ?? ''),
      ringSeconds: int.tryParse(args['NewRingSeconds'] ?? '') ?? 0,
      phoneNumbers: args['NewPhoneNumbers'] ?? '',
    );
  }

  @override
  String toString() => 'TAMInfo($name, enable=$enable, mode=$mode)';
}

/// A single message from the TAM message list XML.
///
/// The XML has the structure:
/// Root > Message with child elements Index, Tam, Called, Date,
/// Duration, Inbook, Name, New, Number, Path.
class TAMMessage {
  /// Message index within this TAM.
  final int index;

  /// TAM index this message belongs to.
  final int tam;

  /// Called number (the number that was called).
  final String called;

  /// Date/time string of the message (DD.MM.YY HH:MM format).
  final String date;

  /// Duration of the recorded message in seconds.
  final int duration;

  /// Whether the caller is in the phonebook.
  final bool inBook;

  /// Caller name (from phonebook or caller ID).
  final String name;

  /// Whether this message has not been listened to yet.
  final bool isNew;

  /// Caller phone number.
  final String number;

  /// Path to the recorded audio file on the Fritz!Box.
  final String path;

  TAMMessage({
    required this.index,
    required this.tam,
    required this.called,
    required this.date,
    required this.duration,
    required this.inBook,
    required this.name,
    required this.isNew,
    required this.number,
    required this.path,
  });

  @override
  String toString() => 'TAMMessage($index, $name, $number, new=$isNew)';
}

/// An item from the TAM list XML returned by GetList.
///
/// The XML has the structure:
/// List > Item with child elements Index, Display, Enable, Name.
class TAMListItem {
  /// TAM index.
  final int index;

  /// Display name.
  final String display;

  /// Whether this TAM is enabled.
  final bool enable;

  /// Name of this TAM.
  final String name;

  TAMListItem({
    required this.index,
    required this.display,
    required this.enable,
    required this.name,
  });

  @override
  String toString() => 'TAMListItem($index, $name, enable=$enable)';
}

/// Result of parsing the GetList XML document.
///
/// Contains global TAM status fields and the list of individual TAMs.
class TAMList {
  /// Whether any TAM is currently running.
  final bool tamRunning;

  /// USB stick index.
  final int stick;

  /// Global status code.
  final int status;

  /// Storage capacity in seconds.
  final int capacity;

  /// List of configured answering machines.
  final List<TAMListItem> items;

  TAMList({
    required this.tamRunning,
    required this.stick,
    required this.status,
    required this.capacity,
    required this.items,
  });

  @override
  String toString() =>
      'TAMList(running=$tamRunning, ${items.length} items)';
}

XmlElement? _findChild(XmlElement parent, String localName) {
  for (final child in parent.childElements) {
    if (child.localName == localName) return child;
  }
  return null;
}

String _childText(XmlElement parent, String localName) {
  final el = _findChild(parent, localName);
  return el?.innerText ?? '';
}

/// Parse the message list XML into a list of [TAMMessage] objects.
List<TAMMessage> _parseMessageListXml(String xml) {
  final document = XmlDocument.parse(xml);
  final messages = <TAMMessage>[];
  for (final msg in document.findAllElements('Message')) {
    messages.add(TAMMessage(
      index: int.tryParse(_childText(msg, 'Index')) ?? 0,
      tam: int.tryParse(_childText(msg, 'Tam')) ?? 0,
      called: _childText(msg, 'Called'),
      date: _childText(msg, 'Date'),
      duration: int.tryParse(_childText(msg, 'Duration')) ?? 0,
      inBook: _childText(msg, 'Inbook') == '1',
      name: _childText(msg, 'Name'),
      isNew: _childText(msg, 'New') == '1',
      number: _childText(msg, 'Number'),
      path: _childText(msg, 'Path'),
    ));
  }
  return messages;
}

/// Parse the TAM list XML into a [TAMList] object.
TAMList _parseTAMListXml(String xml) {
  final document = XmlDocument.parse(xml);
  final root = document.rootElement;

  final items = <TAMListItem>[];
  for (final item in root.findAllElements('Item')) {
    items.add(TAMListItem(
      index: int.tryParse(_childText(item, 'Index')) ?? 0,
      display: _childText(item, 'Display'),
      enable: _childText(item, 'Enable') == '1',
      name: _childText(item, 'Name'),
    ));
  }

  return TAMList(
    tamRunning: _childText(root, 'TAMRunning') == '1',
    stick: int.tryParse(_childText(root, 'Stick')) ?? 0,
    status: int.tryParse(_childText(root, 'Status')) ?? 0,
    capacity: int.tryParse(_childText(root, 'Capacity')) ?? 0,
    items: items,
  );
}

/// TR-064 X_AVM-DE_TAM service (telephone answering machine).
///
/// Service type: urn:dslforum-org:service:X_AVM-DE_TAM:1
class TAMService extends Tr64Service {
  TAMService({
    required super.description,
    required super.callAction,
    required super.fetchUrl,
  });

  /// Get information about an answering machine by index.
  Future<TAMInfo> getInfo(int index) async {
    final result = await call('GetInfo', {
      'NewIndex': index.toString(),
    });
    return TAMInfo.fromArguments(result);
  }

  /// Enable or disable an answering machine.
  Future<void> setEnable(int index, bool enable) async {
    await call('SetEnable', {
      'NewIndex': index.toString(),
      'NewEnable': enable ? '1' : '0',
    });
  }

  /// Get the URL to the message list XML for an answering machine.
  Future<String> getMessageList(int index) async {
    final result = await call('GetMessageList', {
      'NewIndex': index.toString(),
    });
    return result['NewURL'] ?? '';
  }

  /// Fetch and parse the message list for an answering machine.
  ///
  /// Calls [getMessageList] to obtain the URL, fetches the XML,
  /// and parses each message into a [TAMMessage].
  Future<List<TAMMessage>> getMessages(int index) async {
    final url = await getMessageList(index);
    if (url.isEmpty) return [];
    final body = await fetchUrl(url);
    return _parseMessageListXml(body);
  }

  /// Mark a message as read (or unread).
  ///
  /// [markedAsRead] defaults to `true`.
  Future<void> markMessage(
    int index,
    int messageIndex, {
    bool markedAsRead = true,
  }) async {
    await call('MarkMessage', {
      'NewIndex': index.toString(),
      'NewMessageIndex': messageIndex.toString(),
      'NewMarkedAsRead': markedAsRead ? '1' : '0',
    });
  }

  /// Delete a message from an answering machine.
  Future<void> deleteMessage(int index, int messageIndex) async {
    await call('DeleteMessage', {
      'NewIndex': index.toString(),
      'NewMessageIndex': messageIndex.toString(),
    });
  }

  /// Get the list of all configured answering machines.
  ///
  /// Returns the raw XML string. Use [getTAMList] for a parsed result.
  Future<String> getList() async {
    final result = await call('GetList');
    return result['NewTAMList'] ?? '';
  }

  /// Get and parse the list of all configured answering machines.
  Future<TAMList> getTAMList() async {
    final xml = await getList();
    return _parseTAMListXml(xml);
  }
}

/// Extension on [Tr64Client] to access the X_AVM-DE_TAM service.
extension TAMClientExtension on Tr64Client {
  /// Create a [TAMService] for telephone answering machine management.
  ///
  /// Requires [Tr64Client.connect] to have been called first.
  TAMService? tam() {
    if (description == null) return null;
    final desc = description!.findByType(
      'urn:dslforum-org:service:X_AVM-DE_TAM:1',
    );
    if (desc == null) return null;
    return TAMService(
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
