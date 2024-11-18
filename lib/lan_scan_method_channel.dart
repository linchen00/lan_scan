import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'lan_scan_platform_interface.dart';
import 'models/host.dart';

/// An implementation of [LanScanPlatform] that uses method channels.
class MethodChannelLanScan extends LanScanPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('lan_scan');

  @visibleForTesting
  final searchDevicesEventChannel = const EventChannel('lan_scan_event');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Stream<Host?> startDeviceScanStream() {
    return searchDevicesEventChannel.receiveBroadcastStream().map((event) {
      if(event == null) return null;
      final json = jsonDecode(event) as Map<String, dynamic>;
      return Host.fromJson(json);
    });
  }
}
