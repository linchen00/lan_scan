import 'package:flutter_test/flutter_test.dart';
import 'package:lan_scan/lan_scan.dart';
import 'package:lan_scan/lan_scan_platform_interface.dart';
import 'package:lan_scan/lan_scan_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockLanScanPlatform
    with MockPlatformInterfaceMixin
    implements LanScanPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final LanScanPlatform initialPlatform = LanScanPlatform.instance;

  test('$MethodChannelLanScan is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelLanScan>());
  });

  test('getPlatformVersion', () async {
    LanScan lanScanPlugin = LanScan();
    MockLanScanPlatform fakePlatform = MockLanScanPlatform();
    LanScanPlatform.instance = fakePlatform;

    expect(await lanScanPlugin.getPlatformVersion(), '42');
  });
}
