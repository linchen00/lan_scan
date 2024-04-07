
import 'lan_scan_platform_interface.dart';

class LanScan {
  Future<String?> getPlatformVersion() {
    return LanScanPlatform.instance.getPlatformVersion();
  }
}
