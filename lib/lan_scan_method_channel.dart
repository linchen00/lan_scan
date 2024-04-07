import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'lan_scan_platform_interface.dart';

/// An implementation of [LanScanPlatform] that uses method channels.
class MethodChannelLanScan extends LanScanPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('lan_scan');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
