library lan_scan;

import 'lan_scan_platform_interface.dart';
import 'models/host.dart';
export 'models/host.dart';

class LanScan {
  Future<String?> getPlatformVersion() {
    return LanScanPlatform.instance.getPlatformVersion();
  }

  Stream<Host> searchWiFiDetectionStream() {
    return LanScanPlatform.instance.searchWiFiDetectionStream();
  }
}
