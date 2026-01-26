import 'package:flutter_tr64/src/device_description.dart';
import 'package:test/test.dart';

const _sampleXml = '''<?xml version="1.0"?>
<root xmlns="urn:dslforum-org:device-1-0">
  <specVersion>
    <major>1</major>
    <minor>0</minor>
  </specVersion>
  <device>
    <deviceType>urn:dslforum-org:device:InternetGatewayDevice:1</deviceType>
    <friendlyName>FRITZ!Box 7590</friendlyName>
    <manufacturer>AVM Berlin</manufacturer>
    <manufacturerURL>http://www.avm.de</manufacturerURL>
    <modelDescription>FRITZ!Box 7590</modelDescription>
    <modelName>FRITZ!Box 7590</modelName>
    <modelNumber>avm</modelNumber>
    <modelURL>http://www.avm.de</modelURL>
    <UDN>uuid:12345678-1234-1234-1234-123456789012</UDN>
    <serviceList>
      <service>
        <serviceType>urn:dslforum-org:service:DeviceInfo:1</serviceType>
        <serviceId>urn:DeviceInfo-com:serviceId:DeviceInfo1</serviceId>
        <controlURL>/upnp/control/deviceinfo</controlURL>
        <eventSubURL>/upnp/control/deviceinfo</eventSubURL>
        <SCPDURL>/deviceinfoSCPD.xml</SCPDURL>
      </service>
      <service>
        <serviceType>urn:dslforum-org:service:DeviceConfig:1</serviceType>
        <serviceId>urn:DeviceConfig-com:serviceId:DeviceConfig1</serviceId>
        <controlURL>/upnp/control/deviceconfig</controlURL>
        <eventSubURL>/upnp/control/deviceconfig</eventSubURL>
        <SCPDURL>/deviceconfigSCPD.xml</SCPDURL>
      </service>
    </serviceList>
    <deviceList>
      <device>
        <deviceType>urn:dslforum-org:device:LANDevice:1</deviceType>
        <friendlyName>LAN</friendlyName>
        <manufacturer>AVM Berlin</manufacturer>
        <serviceList>
          <service>
            <serviceType>urn:dslforum-org:service:WLANConfiguration:1</serviceType>
            <serviceId>urn:WLANConfiguration-com:serviceId:WLANConfiguration1</serviceId>
            <controlURL>/upnp/control/wlanconfig1</controlURL>
            <eventSubURL>/upnp/control/wlanconfig1</eventSubURL>
            <SCPDURL>/wlanconfigSCPD.xml</SCPDURL>
          </service>
        </serviceList>
        <deviceList>
          <device>
            <deviceType>urn:dslforum-org:device:InnerDevice:1</deviceType>
            <friendlyName>Inner</friendlyName>
            <serviceList>
              <service>
                <serviceType>urn:dslforum-org:service:Hosts:1</serviceType>
                <serviceId>urn:LanDeviceHosts-com:serviceId:Hosts1</serviceId>
                <controlURL>/upnp/control/hosts</controlURL>
                <eventSubURL>/upnp/control/hosts</eventSubURL>
                <SCPDURL>/hostsSCPD.xml</SCPDURL>
              </service>
            </serviceList>
          </device>
        </deviceList>
      </device>
      <device>
        <deviceType>urn:dslforum-org:device:WANDevice:1</deviceType>
        <friendlyName>WAN</friendlyName>
        <manufacturer>AVM Berlin</manufacturer>
        <serviceList>
          <service>
            <serviceType>urn:dslforum-org:service:WANCommonInterfaceConfig:1</serviceType>
            <serviceId>urn:WANCommonIFC-com:serviceId:WANCommonIFC1</serviceId>
            <controlURL>/upnp/control/wancommonifconfig1</controlURL>
            <eventSubURL>/upnp/control/wancommonifconfig1</eventSubURL>
            <SCPDURL>/wancommonifconfigSCPD.xml</SCPDURL>
          </service>
        </serviceList>
      </device>
    </deviceList>
  </device>
</root>''';

void main() {
  group('DeviceDescription', () {
    late DeviceDescription desc;

    setUp(() {
      desc = DeviceDescription.parse(_sampleXml);
    });

    test('parses root device', () {
      expect(desc.rootDevice.friendlyName, 'FRITZ!Box 7590');
      expect(desc.rootDevice.deviceType,
          'urn:dslforum-org:device:InternetGatewayDevice:1');
    });

    test('parses root device services', () {
      expect(desc.rootDevice.services, hasLength(2));

      final deviceInfo = desc.rootDevice.services
          .firstWhere((s) => s.serviceType.contains('DeviceInfo'));
      expect(deviceInfo.serviceType,
          'urn:dslforum-org:service:DeviceInfo:1');
      expect(deviceInfo.controlUrl, '/upnp/control/deviceinfo');
      expect(deviceInfo.scpdUrl, '/deviceinfoSCPD.xml');
    });

    test('parses nested devices', () {
      expect(desc.rootDevice.subDevices, hasLength(2));

      final lan = desc.rootDevice.subDevices
          .firstWhere((d) => d.friendlyName == 'LAN');
      expect(lan.deviceType, 'urn:dslforum-org:device:LANDevice:1');
      expect(lan.services, hasLength(1));
      expect(lan.services.first.serviceType,
          'urn:dslforum-org:service:WLANConfiguration:1');

      final wan = desc.rootDevice.subDevices
          .firstWhere((d) => d.friendlyName == 'WAN');
      expect(wan.deviceType, 'urn:dslforum-org:device:WANDevice:1');
    });

    test('parses deeply nested devices', () {
      final lan = desc.rootDevice.subDevices
          .firstWhere((d) => d.friendlyName == 'LAN');
      expect(lan.subDevices, hasLength(1));

      final inner = lan.subDevices.first;
      expect(inner.friendlyName, 'Inner');
      expect(inner.services, hasLength(1));
      expect(inner.services.first.serviceType,
          'urn:dslforum-org:service:Hosts:1');
    });

    test('builds flat service maps across all devices', () {
      // 2 root + 1 LAN + 1 Inner + 1 WAN = 5 services total
      expect(desc.allServices, hasLength(5));
    });

    test('findByType returns correct service', () {
      final service = desc.findByType(
          'urn:dslforum-org:service:WLANConfiguration:1');
      expect(service, isNotNull);
      expect(service!.controlUrl, '/upnp/control/wlanconfig1');
    });

    test('findByType returns null for unknown service', () {
      final service = desc.findByType('urn:unknown:service:Foo:1');
      expect(service, isNull);
    });

    test('findById returns correct service', () {
      final service = desc.findById(
          'urn:DeviceInfo-com:serviceId:DeviceInfo1');
      expect(service, isNotNull);
      expect(service!.serviceType,
          'urn:dslforum-org:service:DeviceInfo:1');
    });

    test('findById returns null for unknown id', () {
      final service = desc.findById('urn:unknown:serviceId:Foo1');
      expect(service, isNull);
    });
  });

  group('DeviceDescription error handling', () {
    test('throws on missing device element', () {
      const xml = '''<?xml version="1.0"?>
<root xmlns="urn:dslforum-org:device-1-0">
  <specVersion><major>1</major><minor>0</minor></specVersion>
</root>''';

      expect(
        () => DeviceDescription.parse(xml),
        throwsA(isA<FormatException>()),
      );
    });

    test('handles device with no services', () {
      const xml = '''<?xml version="1.0"?>
<root xmlns="urn:dslforum-org:device-1-0">
  <device>
    <deviceType>urn:dslforum-org:device:Test:1</deviceType>
    <friendlyName>Test</friendlyName>
  </device>
</root>''';

      final desc = DeviceDescription.parse(xml);
      expect(desc.rootDevice.services, isEmpty);
      expect(desc.rootDevice.subDevices, isEmpty);
      expect(desc.allServices, isEmpty);
    });
  });
}
