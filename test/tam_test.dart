import 'package:flutter_tr64/src/device_description.dart';
import 'package:flutter_tr64/src/services/tam.dart';
import 'package:test/test.dart';

ServiceDescription _fakeDescription() {
  return ServiceDescription(
    serviceType: 'urn:dslforum-org:service:X_AVM-DE_TAM:1',
    serviceId: 'urn:X_AVM-DE_TAM-com:serviceId:X_AVM-DE_TAM1',
    controlUrl: '/upnp/control/x_tam',
    scpdUrl: '/x_tamSCPD.xml',
  );
}

Future<String> _unusedFetchUrl(String url) async => '';

void main() {
  group('TAMMode', () {
    test('tryParse returns matching enum value', () {
      expect(TAMMode.tryParse('play_announcement'),
          TAMMode.playAnnouncement);
      expect(TAMMode.tryParse('record_message'), TAMMode.recordMessage);
      expect(TAMMode.tryParse('timeprofile'), TAMMode.timeprofile);
    });

    test('tryParse returns null for unknown', () {
      expect(TAMMode.tryParse('unknown'), isNull);
      expect(TAMMode.tryParse(''), isNull);
    });

    test('toString returns spec value', () {
      expect(TAMMode.playAnnouncement.toString(), 'play_announcement');
      expect(TAMMode.recordMessage.toString(), 'record_message');
      expect(TAMMode.timeprofile.toString(), 'timeprofile');
    });
  });

  group('TAMInfo', () {
    test('fromArguments parses all fields', () {
      final info = TAMInfo.fromArguments({
        'NewEnable': '1',
        'NewName': 'Answering Machine 1',
        'NewTAMRunning': '1',
        'NewStick': '0',
        'NewStatus': '0',
        'NewCapacity': '1200',
        'NewMode': 'record_message',
        'NewRingSeconds': '18',
        'NewPhoneNumbers': '030123456,030654321',
      });

      expect(info.enable, isTrue);
      expect(info.name, 'Answering Machine 1');
      expect(info.tamRunning, isTrue);
      expect(info.stick, 0);
      expect(info.status, 0);
      expect(info.capacity, 1200);
      expect(info.mode, TAMMode.recordMessage);
      expect(info.ringSeconds, 18);
      expect(info.phoneNumbers, '030123456,030654321');
    });

    test('fromArguments defaults for missing keys', () {
      final info = TAMInfo.fromArguments({});

      expect(info.enable, isFalse);
      expect(info.name, '');
      expect(info.tamRunning, isFalse);
      expect(info.stick, 0);
      expect(info.status, 0);
      expect(info.capacity, 0);
      expect(info.mode, isNull);
      expect(info.ringSeconds, 0);
      expect(info.phoneNumbers, '');
    });

    test('fromArguments with play_announcement mode', () {
      final info = TAMInfo.fromArguments({
        'NewMode': 'play_announcement',
      });
      expect(info.mode, TAMMode.playAnnouncement);
    });

    test('toString includes name and mode', () {
      final info = TAMInfo(
        enable: true,
        name: 'AB 1',
        tamRunning: false,
        stick: 0,
        status: 0,
        capacity: 600,
        mode: TAMMode.recordMessage,
        ringSeconds: 18,
        phoneNumbers: '',
      );
      expect(info.toString(), 'TAMInfo(AB 1, enable=true, mode=record_message)');
    });
  });

  group('TAMMessage', () {
    test('toString includes key fields', () {
      final msg = TAMMessage(
        index: 3,
        tam: 0,
        called: '030123456',
        date: '25.01.26 14:30',
        duration: 45,
        inBook: true,
        name: 'Max Mustermann',
        isNew: true,
        number: '017012345',
        path: '/data/tam/rec/rec.0.003',
      );
      expect(msg.toString(),
          'TAMMessage(3, Max Mustermann, 017012345, new=true)');
    });
  });

  group('TAMListItem', () {
    test('toString includes index and name', () {
      final item = TAMListItem(
        index: 0,
        display: 'AB 1',
        enable: true,
        name: 'Answering Machine 1',
      );
      expect(item.toString(),
          'TAMListItem(0, Answering Machine 1, enable=true)');
    });
  });

  group('TAMList', () {
    test('toString includes running status and item count', () {
      final list = TAMList(
        tamRunning: true,
        stick: 0,
        status: 0,
        capacity: 1200,
        items: [
          TAMListItem(index: 0, display: 'AB 1', enable: true, name: 'AB 1'),
        ],
      );
      expect(list.toString(), 'TAMList(running=true, 1 items)');
    });
  });

  group('TAMService', () {
    test('getInfo returns parsed TAMInfo', () async {
      final service = TAMService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetInfo');
          expect(arguments['NewIndex'], '0');
          return {
            'NewEnable': '1',
            'NewName': 'Answering Machine 1',
            'NewTAMRunning': '0',
            'NewStick': '0',
            'NewStatus': '0',
            'NewCapacity': '1200',
            'NewMode': 'record_message',
            'NewRingSeconds': '18',
            'NewPhoneNumbers': '',
          };
        },
      );

      final info = await service.getInfo(0);
      expect(info.enable, isTrue);
      expect(info.name, 'Answering Machine 1');
      expect(info.tamRunning, isFalse);
      expect(info.capacity, 1200);
      expect(info.mode, TAMMode.recordMessage);
      expect(info.ringSeconds, 18);
      expect(info.phoneNumbers, '');
    });

    test('setEnable sends correct arguments', () async {
      final service = TAMService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'SetEnable');
          expect(arguments['NewIndex'], '2');
          expect(arguments['NewEnable'], '1');
          return {};
        },
      );

      await service.setEnable(2, true);
    });

    test('setEnable sends 0 when disabling', () async {
      final service = TAMService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(arguments['NewEnable'], '0');
          return {};
        },
      );

      await service.setEnable(0, false);
    });

    test('getMessageList returns URL', () async {
      final service = TAMService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetMessageList');
          expect(arguments['NewIndex'], '0');
          return {
            'NewURL': 'http://fritz.box:49000/tamcalllist.lua?sid=abc&tam=0',
          };
        },
      );

      final url = await service.getMessageList(0);
      expect(url, 'http://fritz.box:49000/tamcalllist.lua?sid=abc&tam=0');
    });

    test('getMessages fetches and parses XML', () async {
      const messageXml = '''
<Root>
  <Message>
    <Index>0</Index>
    <Tam>0</Tam>
    <Called>030123456</Called>
    <Date>25.01.26 14:30</Date>
    <Duration>45</Duration>
    <Inbook>1</Inbook>
    <Name>Max Mustermann</Name>
    <New>1</New>
    <Number>017012345</Number>
    <Path>/data/tam/rec/rec.0.000</Path>
  </Message>
  <Message>
    <Index>1</Index>
    <Tam>0</Tam>
    <Called>030123456</Called>
    <Date>24.01.26 09:15</Date>
    <Duration>12</Duration>
    <Inbook>0</Inbook>
    <Name></Name>
    <New>0</New>
    <Number>0800555000</Number>
    <Path>/data/tam/rec/rec.0.001</Path>
  </Message>
</Root>
''';

      final service = TAMService(
        description: _fakeDescription(),
        fetchUrl: (url) async {
          expect(url, contains('tamcalllist'));
          return messageXml;
        },
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          return {
            'NewURL': 'http://fritz.box:49000/tamcalllist.lua?sid=abc&tam=0',
          };
        },
      );

      final messages = await service.getMessages(0);
      expect(messages, hasLength(2));

      expect(messages[0].index, 0);
      expect(messages[0].tam, 0);
      expect(messages[0].called, '030123456');
      expect(messages[0].date, '25.01.26 14:30');
      expect(messages[0].duration, 45);
      expect(messages[0].inBook, isTrue);
      expect(messages[0].name, 'Max Mustermann');
      expect(messages[0].isNew, isTrue);
      expect(messages[0].number, '017012345');
      expect(messages[0].path, '/data/tam/rec/rec.0.000');

      expect(messages[1].index, 1);
      expect(messages[1].inBook, isFalse);
      expect(messages[1].name, '');
      expect(messages[1].isNew, isFalse);
      expect(messages[1].number, '0800555000');
    });

    test('getMessages returns empty list for empty URL', () async {
      final service = TAMService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          return {'NewURL': ''};
        },
      );

      final messages = await service.getMessages(0);
      expect(messages, isEmpty);
    });

    test('markMessage sends correct arguments with default', () async {
      final service = TAMService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'MarkMessage');
          expect(arguments['NewIndex'], '0');
          expect(arguments['NewMessageIndex'], '3');
          expect(arguments['NewMarkedAsRead'], '1');
          return {};
        },
      );

      await service.markMessage(0, 3);
    });

    test('markMessage sends 0 when marking as unread', () async {
      final service = TAMService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(arguments['NewMarkedAsRead'], '0');
          return {};
        },
      );

      await service.markMessage(0, 3, markedAsRead: false);
    });

    test('deleteMessage sends correct arguments', () async {
      final service = TAMService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'DeleteMessage');
          expect(arguments['NewIndex'], '1');
          expect(arguments['NewMessageIndex'], '5');
          return {};
        },
      );

      await service.deleteMessage(1, 5);
    });

    test('getList returns raw XML', () async {
      final service = TAMService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          expect(actionName, 'GetList');
          expect(arguments, isEmpty);
          return {'NewTAMList': '<List><Item/></List>'};
        },
      );

      final xml = await service.getList();
      expect(xml, '<List><Item/></List>');
    });

    test('getTAMList parses XML into TAMList', () async {
      const tamListXml =
          '<List>'
          '<TAMRunning>1</TAMRunning>'
          '<Stick>0</Stick>'
          '<Status>0</Status>'
          '<Capacity>1200</Capacity>'
          '<Item>'
          '<Index>0</Index>'
          '<Display>Answering Machine 1</Display>'
          '<Enable>1</Enable>'
          '<Name>AB 1</Name>'
          '</Item>'
          '<Item>'
          '<Index>1</Index>'
          '<Display>Answering Machine 2</Display>'
          '<Enable>0</Enable>'
          '<Name>AB 2</Name>'
          '</Item>'
          '</List>';

      final service = TAMService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          return {'NewTAMList': tamListXml};
        },
      );

      final tamList = await service.getTAMList();
      expect(tamList.tamRunning, isTrue);
      expect(tamList.stick, 0);
      expect(tamList.status, 0);
      expect(tamList.capacity, 1200);
      expect(tamList.items, hasLength(2));

      expect(tamList.items[0].index, 0);
      expect(tamList.items[0].display, 'Answering Machine 1');
      expect(tamList.items[0].enable, isTrue);
      expect(tamList.items[0].name, 'AB 1');

      expect(tamList.items[1].index, 1);
      expect(tamList.items[1].display, 'Answering Machine 2');
      expect(tamList.items[1].enable, isFalse);
      expect(tamList.items[1].name, 'AB 2');
    });

    test('getTAMList handles empty list', () async {
      const tamListXml =
          '<List>'
          '<TAMRunning>0</TAMRunning>'
          '<Stick>0</Stick>'
          '<Status>0</Status>'
          '<Capacity>0</Capacity>'
          '</List>';

      final service = TAMService(
        description: _fakeDescription(),
        fetchUrl: _unusedFetchUrl,
        callAction: (serviceType, controlUrl, actionName, arguments) async {
          return {'NewTAMList': tamListXml};
        },
      );

      final tamList = await service.getTAMList();
      expect(tamList.tamRunning, isFalse);
      expect(tamList.items, isEmpty);
    });
  });
}
