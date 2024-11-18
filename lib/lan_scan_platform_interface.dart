import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'lan_scan_method_channel.dart';
import 'models/host.dart';

abstract class LanScanPlatform extends PlatformInterface {
  /// Constructs a LanScanPlatform.
  LanScanPlatform() : super(token: _token);

  static final Object _token = Object();

  static LanScanPlatform _instance = MethodChannelLanScan();

  /// The default instance of [LanScanPlatform] to use.
  ///
  /// Defaults to [MethodChannelLanScan].
  static LanScanPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [LanScanPlatform] when
  /// they register themselves.
  static set instance(LanScanPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Stream<Host?> startDeviceScanStream() {
    throw UnimplementedError('startDeviceScanStream() has not been implemented.');
  }
}
