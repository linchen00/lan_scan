import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lan_scan/lan_scan.dart';
import 'package:permission_handler/permission_handler.dart';

class SearchDevicesPage extends StatefulWidget {
  const SearchDevicesPage({super.key});

  @override
  State<SearchDevicesPage> createState() => _SearchDevicesPageState();
}

class _SearchDevicesPageState extends State<SearchDevicesPage> {
  final _lanScanPlugin = LanScan();

  final List<String> list = [];
  StreamSubscription<Host>? _searchDevicesSubscription;

  @override
  void dispose() {
    _searchDevicesSubscription?.cancel();
    super.dispose();
  }

  void startSearchDevices() async {
    final locationPermissionStatus = Permission.locationWhenInUse.request();
    if(await locationPermissionStatus.isGranted) {
      _searchDevicesSubscription?.cancel();
      _searchDevicesSubscription = _lanScanPlugin.searchWiFiDetectionStream().listen(
        (Host host) {
          debugPrint("searchWiFiDetectionStreamEvent:$host");
          setState(() {
            list.add(host.toString());
          });
        },
        onError: (error) {
          debugPrint("searchWiFiDetectionStreamError:$error");
        },
        onDone: () {
          debugPrint("searchWiFiDetectionStreamDone");
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Devices'),
      ),
      body: list.isEmpty
          ?  Center(
              child: ElevatedButton(
                onPressed: startSearchDevices,
                child:const Text("start Search Devices"),
              ),
            )
          : ListView.separated(
              itemBuilder: (context, index) => ListTile(
                title: Text(list[index]),
              ),
              itemCount: list.length,
              separatorBuilder: (BuildContext context, int index) => const Divider(),
            ),
    );
  }
}
