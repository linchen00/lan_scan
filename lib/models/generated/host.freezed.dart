// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../host.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Host _$HostFromJson(Map<String, dynamic> json) {
  return _Host.fromJson(json);
}

/// @nodoc
mixin _$Host {
  String get ip => throw _privateConstructorUsedError;
  String? get mac => throw _privateConstructorUsedError;
  String? get hostName => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $HostCopyWith<Host> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HostCopyWith<$Res> {
  factory $HostCopyWith(Host value, $Res Function(Host) then) =
      _$HostCopyWithImpl<$Res, Host>;
  @useResult
  $Res call({String ip, String? mac, String? hostName});
}

/// @nodoc
class _$HostCopyWithImpl<$Res, $Val extends Host>
    implements $HostCopyWith<$Res> {
  _$HostCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ip = null,
    Object? mac = freezed,
    Object? hostName = freezed,
  }) {
    return _then(_value.copyWith(
      ip: null == ip
          ? _value.ip
          : ip // ignore: cast_nullable_to_non_nullable
              as String,
      mac: freezed == mac
          ? _value.mac
          : mac // ignore: cast_nullable_to_non_nullable
              as String?,
      hostName: freezed == hostName
          ? _value.hostName
          : hostName // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HostImplCopyWith<$Res> implements $HostCopyWith<$Res> {
  factory _$$HostImplCopyWith(
          _$HostImpl value, $Res Function(_$HostImpl) then) =
      __$$HostImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String ip, String? mac, String? hostName});
}

/// @nodoc
class __$$HostImplCopyWithImpl<$Res>
    extends _$HostCopyWithImpl<$Res, _$HostImpl>
    implements _$$HostImplCopyWith<$Res> {
  __$$HostImplCopyWithImpl(_$HostImpl _value, $Res Function(_$HostImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ip = null,
    Object? mac = freezed,
    Object? hostName = freezed,
  }) {
    return _then(_$HostImpl(
      ip: null == ip
          ? _value.ip
          : ip // ignore: cast_nullable_to_non_nullable
              as String,
      mac: freezed == mac
          ? _value.mac
          : mac // ignore: cast_nullable_to_non_nullable
              as String?,
      hostName: freezed == hostName
          ? _value.hostName
          : hostName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HostImpl with DiagnosticableTreeMixin implements _Host {
  const _$HostImpl({required this.ip, this.mac, this.hostName});

  factory _$HostImpl.fromJson(Map<String, dynamic> json) =>
      _$$HostImplFromJson(json);

  @override
  final String ip;
  @override
  final String? mac;
  @override
  final String? hostName;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Host(ip: $ip, mac: $mac, hostName: $hostName)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'Host'))
      ..add(DiagnosticsProperty('ip', ip))
      ..add(DiagnosticsProperty('mac', mac))
      ..add(DiagnosticsProperty('hostName', hostName));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HostImpl &&
            (identical(other.ip, ip) || other.ip == ip) &&
            (identical(other.mac, mac) || other.mac == mac) &&
            (identical(other.hostName, hostName) ||
                other.hostName == hostName));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, ip, mac, hostName);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HostImplCopyWith<_$HostImpl> get copyWith =>
      __$$HostImplCopyWithImpl<_$HostImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HostImplToJson(
      this,
    );
  }
}

abstract class _Host implements Host {
  const factory _Host(
      {required final String ip,
      final String? mac,
      final String? hostName}) = _$HostImpl;

  factory _Host.fromJson(Map<String, dynamic> json) = _$HostImpl.fromJson;

  @override
  String get ip;
  @override
  String? get mac;
  @override
  String? get hostName;
  @override
  @JsonKey(ignore: true)
  _$$HostImplCopyWith<_$HostImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
