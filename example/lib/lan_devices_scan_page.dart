import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lan_scan/lan_scan.dart';
import 'package:permission_handler/permission_handler.dart';

class LanDevicesScanPage extends StatefulWidget {
  const LanDevicesScanPage({super.key});

  @override
  State<LanDevicesScanPage> createState() => _LanDevicesScanPageState();
}

class _LanDevicesScanPageState extends State<LanDevicesScanPage> {
  final _lanScanPlugin = LanScan();

  final List<String> list = [];
  bool isWifiConnected = false;
  StreamSubscription<Host?>? _searchDevicesSubscription;
  StreamSubscription<bool>? _wifiConnectionStatusSubscription;

  @override
  void initState() {
    super.initState();
    startListenWifiConnectionStatus();
  }

  @override
  void dispose() {
    _searchDevicesSubscription?.cancel();
    super.dispose();
  }

  void startScanningLanDevices() async {
    final locationPermissionStatus = Permission.locationWhenInUse.request();
    if (await locationPermissionStatus.isGranted) {
      list.clear();
      _searchDevicesSubscription = _lanScanPlugin.startDeviceScanStream().listen(
        (Host? host) {
          if (host == null) {
            _searchDevicesSubscription = null;
            debugPrint("searchWiFiDetectionStreamDone");
          } else {
            setState(() {
              list.add(host.toString());
            });
          }
        },
      );
    }
  }

  void stopScanningLanDevices() {
    _searchDevicesSubscription?.cancel();
    _searchDevicesSubscription = null;
  }

  void startListenWifiConnectionStatus() {
    _wifiConnectionStatusSubscription = _lanScanPlugin.wifiConnectionStatusChange().listen((event) {
      setState(() {
        isWifiConnected = event;
      });
      debugPrint("wifiConnectionStatusChange:$event");
    });
  }

  void stopListenWifiConnectionStatus() {
    _wifiConnectionStatusSubscription?.cancel();
    _wifiConnectionStatusSubscription = null;
  }

  void clearList() {
    setState(() {
      list.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Devices'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: startListenWifiConnectionStatus,
            child: const Text("start listen wifi connection status"),
          ),
          ElevatedButton(
            onPressed: stopListenWifiConnectionStatus,
            child: const Text("stop listen wifi connection status"),
          ),
          Text("print WiFi connection status(${isWifiConnected})"),
          ElevatedButton(
            onPressed: startScanningLanDevices,
            child: const Text("start scanning Lan Devices"),
          ),
          ElevatedButton(
            onPressed: stopScanningLanDevices,
            child: const Text("stop scanning Lan Devices"),
          ),
          ElevatedButton(
            onPressed: clearList,
            child: const Text("clear Lan Devices"),
          ),
          ElevatedButton(
            onPressed: () {},
            child: Text("devices count:${list.length}"),
          ),
          Expanded(
            child: ListView.separated(
              itemBuilder: (context, index) => ListTile(
                title: Text(list[index]),
              ),
              itemCount: list.length,
              separatorBuilder: (BuildContext context, int index) => const Divider(),
            ),
          )
        ],
      ),
    );
  }
}
