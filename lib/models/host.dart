import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/host.freezed.dart';

part 'generated/host.g.dart';

@freezed
class Host with _$Host {
  const factory Host({
    required String ip,
    String? mac,
    String? hostName,
  }) = _Host;

  factory Host.fromJson(Map<String, dynamic> json) => _$HostFromJson(json);
}
