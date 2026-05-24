// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'system_directive.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SystemDirective _$SystemDirectiveFromJson(Map<String, dynamic> json) {
  return _SystemDirective.fromJson(json);
}

/// @nodoc
mixin _$SystemDirective {
  String get id => throw _privateConstructorUsedError;
  String get appName => throw _privateConstructorUsedError;
  String get packageName => throw _privateConstructorUsedError;
  DirectiveType get type => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  AppLimit? get limit => throw _privateConstructorUsedError;
  DeepBlockTarget? get deepBlockTarget => throw _privateConstructorUsedError;

  /// Serializes this SystemDirective to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SystemDirective
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SystemDirectiveCopyWith<SystemDirective> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SystemDirectiveCopyWith<$Res> {
  factory $SystemDirectiveCopyWith(
    SystemDirective value,
    $Res Function(SystemDirective) then,
  ) = _$SystemDirectiveCopyWithImpl<$Res, SystemDirective>;
  @useResult
  $Res call({
    String id,
    String appName,
    String packageName,
    DirectiveType type,
    bool isActive,
    AppLimit? limit,
    DeepBlockTarget? deepBlockTarget,
  });

  $AppLimitCopyWith<$Res>? get limit;
  $DeepBlockTargetCopyWith<$Res>? get deepBlockTarget;
}

/// @nodoc
class _$SystemDirectiveCopyWithImpl<$Res, $Val extends SystemDirective>
    implements $SystemDirectiveCopyWith<$Res> {
  _$SystemDirectiveCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SystemDirective
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? appName = null,
    Object? packageName = null,
    Object? type = null,
    Object? isActive = null,
    Object? limit = freezed,
    Object? deepBlockTarget = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            appName: null == appName
                ? _value.appName
                : appName // ignore: cast_nullable_to_non_nullable
                      as String,
            packageName: null == packageName
                ? _value.packageName
                : packageName // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as DirectiveType,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            limit: freezed == limit
                ? _value.limit
                : limit // ignore: cast_nullable_to_non_nullable
                      as AppLimit?,
            deepBlockTarget: freezed == deepBlockTarget
                ? _value.deepBlockTarget
                : deepBlockTarget // ignore: cast_nullable_to_non_nullable
                      as DeepBlockTarget?,
          )
          as $Val,
    );
  }

  /// Create a copy of SystemDirective
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AppLimitCopyWith<$Res>? get limit {
    if (_value.limit == null) {
      return null;
    }

    return $AppLimitCopyWith<$Res>(_value.limit!, (value) {
      return _then(_value.copyWith(limit: value) as $Val);
    });
  }

  /// Create a copy of SystemDirective
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DeepBlockTargetCopyWith<$Res>? get deepBlockTarget {
    if (_value.deepBlockTarget == null) {
      return null;
    }

    return $DeepBlockTargetCopyWith<$Res>(_value.deepBlockTarget!, (value) {
      return _then(_value.copyWith(deepBlockTarget: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SystemDirectiveImplCopyWith<$Res>
    implements $SystemDirectiveCopyWith<$Res> {
  factory _$$SystemDirectiveImplCopyWith(
    _$SystemDirectiveImpl value,
    $Res Function(_$SystemDirectiveImpl) then,
  ) = __$$SystemDirectiveImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String appName,
    String packageName,
    DirectiveType type,
    bool isActive,
    AppLimit? limit,
    DeepBlockTarget? deepBlockTarget,
  });

  @override
  $AppLimitCopyWith<$Res>? get limit;
  @override
  $DeepBlockTargetCopyWith<$Res>? get deepBlockTarget;
}

/// @nodoc
class __$$SystemDirectiveImplCopyWithImpl<$Res>
    extends _$SystemDirectiveCopyWithImpl<$Res, _$SystemDirectiveImpl>
    implements _$$SystemDirectiveImplCopyWith<$Res> {
  __$$SystemDirectiveImplCopyWithImpl(
    _$SystemDirectiveImpl _value,
    $Res Function(_$SystemDirectiveImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SystemDirective
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? appName = null,
    Object? packageName = null,
    Object? type = null,
    Object? isActive = null,
    Object? limit = freezed,
    Object? deepBlockTarget = freezed,
  }) {
    return _then(
      _$SystemDirectiveImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        appName: null == appName
            ? _value.appName
            : appName // ignore: cast_nullable_to_non_nullable
                  as String,
        packageName: null == packageName
            ? _value.packageName
            : packageName // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as DirectiveType,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        limit: freezed == limit
            ? _value.limit
            : limit // ignore: cast_nullable_to_non_nullable
                  as AppLimit?,
        deepBlockTarget: freezed == deepBlockTarget
            ? _value.deepBlockTarget
            : deepBlockTarget // ignore: cast_nullable_to_non_nullable
                  as DeepBlockTarget?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SystemDirectiveImpl implements _SystemDirective {
  const _$SystemDirectiveImpl({
    required this.id,
    required this.appName,
    required this.packageName,
    required this.type,
    this.isActive = false,
    this.limit,
    this.deepBlockTarget,
  });

  factory _$SystemDirectiveImpl.fromJson(Map<String, dynamic> json) =>
      _$$SystemDirectiveImplFromJson(json);

  @override
  final String id;
  @override
  final String appName;
  @override
  final String packageName;
  @override
  final DirectiveType type;
  @override
  @JsonKey()
  final bool isActive;
  @override
  final AppLimit? limit;
  @override
  final DeepBlockTarget? deepBlockTarget;

  @override
  String toString() {
    return 'SystemDirective(id: $id, appName: $appName, packageName: $packageName, type: $type, isActive: $isActive, limit: $limit, deepBlockTarget: $deepBlockTarget)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SystemDirectiveImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.appName, appName) || other.appName == appName) &&
            (identical(other.packageName, packageName) ||
                other.packageName == packageName) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.deepBlockTarget, deepBlockTarget) ||
                other.deepBlockTarget == deepBlockTarget));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    appName,
    packageName,
    type,
    isActive,
    limit,
    deepBlockTarget,
  );

  /// Create a copy of SystemDirective
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SystemDirectiveImplCopyWith<_$SystemDirectiveImpl> get copyWith =>
      __$$SystemDirectiveImplCopyWithImpl<_$SystemDirectiveImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SystemDirectiveImplToJson(this);
  }
}

abstract class _SystemDirective implements SystemDirective {
  const factory _SystemDirective({
    required final String id,
    required final String appName,
    required final String packageName,
    required final DirectiveType type,
    final bool isActive,
    final AppLimit? limit,
    final DeepBlockTarget? deepBlockTarget,
  }) = _$SystemDirectiveImpl;

  factory _SystemDirective.fromJson(Map<String, dynamic> json) =
      _$SystemDirectiveImpl.fromJson;

  @override
  String get id;
  @override
  String get appName;
  @override
  String get packageName;
  @override
  DirectiveType get type;
  @override
  bool get isActive;
  @override
  AppLimit? get limit;
  @override
  DeepBlockTarget? get deepBlockTarget;

  /// Create a copy of SystemDirective
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SystemDirectiveImplCopyWith<_$SystemDirectiveImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AppLimit _$AppLimitFromJson(Map<String, dynamic> json) {
  return _AppLimit.fromJson(json);
}

/// @nodoc
mixin _$AppLimit {
  int get dailyLimitMinutes => throw _privateConstructorUsedError;
  int get usedMinutes => throw _privateConstructorUsedError;

  /// Serializes this AppLimit to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppLimit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppLimitCopyWith<AppLimit> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppLimitCopyWith<$Res> {
  factory $AppLimitCopyWith(AppLimit value, $Res Function(AppLimit) then) =
      _$AppLimitCopyWithImpl<$Res, AppLimit>;
  @useResult
  $Res call({int dailyLimitMinutes, int usedMinutes});
}

/// @nodoc
class _$AppLimitCopyWithImpl<$Res, $Val extends AppLimit>
    implements $AppLimitCopyWith<$Res> {
  _$AppLimitCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppLimit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? dailyLimitMinutes = null, Object? usedMinutes = null}) {
    return _then(
      _value.copyWith(
            dailyLimitMinutes: null == dailyLimitMinutes
                ? _value.dailyLimitMinutes
                : dailyLimitMinutes // ignore: cast_nullable_to_non_nullable
                      as int,
            usedMinutes: null == usedMinutes
                ? _value.usedMinutes
                : usedMinutes // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AppLimitImplCopyWith<$Res>
    implements $AppLimitCopyWith<$Res> {
  factory _$$AppLimitImplCopyWith(
    _$AppLimitImpl value,
    $Res Function(_$AppLimitImpl) then,
  ) = __$$AppLimitImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int dailyLimitMinutes, int usedMinutes});
}

/// @nodoc
class __$$AppLimitImplCopyWithImpl<$Res>
    extends _$AppLimitCopyWithImpl<$Res, _$AppLimitImpl>
    implements _$$AppLimitImplCopyWith<$Res> {
  __$$AppLimitImplCopyWithImpl(
    _$AppLimitImpl _value,
    $Res Function(_$AppLimitImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppLimit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? dailyLimitMinutes = null, Object? usedMinutes = null}) {
    return _then(
      _$AppLimitImpl(
        dailyLimitMinutes: null == dailyLimitMinutes
            ? _value.dailyLimitMinutes
            : dailyLimitMinutes // ignore: cast_nullable_to_non_nullable
                  as int,
        usedMinutes: null == usedMinutes
            ? _value.usedMinutes
            : usedMinutes // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AppLimitImpl implements _AppLimit {
  const _$AppLimitImpl({required this.dailyLimitMinutes, this.usedMinutes = 0});

  factory _$AppLimitImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppLimitImplFromJson(json);

  @override
  final int dailyLimitMinutes;
  @override
  @JsonKey()
  final int usedMinutes;

  @override
  String toString() {
    return 'AppLimit(dailyLimitMinutes: $dailyLimitMinutes, usedMinutes: $usedMinutes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppLimitImpl &&
            (identical(other.dailyLimitMinutes, dailyLimitMinutes) ||
                other.dailyLimitMinutes == dailyLimitMinutes) &&
            (identical(other.usedMinutes, usedMinutes) ||
                other.usedMinutes == usedMinutes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, dailyLimitMinutes, usedMinutes);

  /// Create a copy of AppLimit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppLimitImplCopyWith<_$AppLimitImpl> get copyWith =>
      __$$AppLimitImplCopyWithImpl<_$AppLimitImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppLimitImplToJson(this);
  }
}

abstract class _AppLimit implements AppLimit {
  const factory _AppLimit({
    required final int dailyLimitMinutes,
    final int usedMinutes,
  }) = _$AppLimitImpl;

  factory _AppLimit.fromJson(Map<String, dynamic> json) =
      _$AppLimitImpl.fromJson;

  @override
  int get dailyLimitMinutes;
  @override
  int get usedMinutes;

  /// Create a copy of AppLimit
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppLimitImplCopyWith<_$AppLimitImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DeepBlockTarget _$DeepBlockTargetFromJson(Map<String, dynamic> json) {
  return _DeepBlockTarget.fromJson(json);
}

/// @nodoc
mixin _$DeepBlockTarget {
  /// Human-readable feature name (e.g., "Shorts", "Reels")
  String get featureName => throw _privateConstructorUsedError;

  /// Content descriptions / text to match in the accessibility node tree
  List<String> get nodeTexts => throw _privateConstructorUsedError;

  /// Icon codepoint for the UI
  int get iconCodePoint => throw _privateConstructorUsedError;

  /// Serializes this DeepBlockTarget to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DeepBlockTarget
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeepBlockTargetCopyWith<DeepBlockTarget> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeepBlockTargetCopyWith<$Res> {
  factory $DeepBlockTargetCopyWith(
    DeepBlockTarget value,
    $Res Function(DeepBlockTarget) then,
  ) = _$DeepBlockTargetCopyWithImpl<$Res, DeepBlockTarget>;
  @useResult
  $Res call({String featureName, List<String> nodeTexts, int iconCodePoint});
}

/// @nodoc
class _$DeepBlockTargetCopyWithImpl<$Res, $Val extends DeepBlockTarget>
    implements $DeepBlockTargetCopyWith<$Res> {
  _$DeepBlockTargetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeepBlockTarget
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? featureName = null,
    Object? nodeTexts = null,
    Object? iconCodePoint = null,
  }) {
    return _then(
      _value.copyWith(
            featureName: null == featureName
                ? _value.featureName
                : featureName // ignore: cast_nullable_to_non_nullable
                      as String,
            nodeTexts: null == nodeTexts
                ? _value.nodeTexts
                : nodeTexts // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            iconCodePoint: null == iconCodePoint
                ? _value.iconCodePoint
                : iconCodePoint // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DeepBlockTargetImplCopyWith<$Res>
    implements $DeepBlockTargetCopyWith<$Res> {
  factory _$$DeepBlockTargetImplCopyWith(
    _$DeepBlockTargetImpl value,
    $Res Function(_$DeepBlockTargetImpl) then,
  ) = __$$DeepBlockTargetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String featureName, List<String> nodeTexts, int iconCodePoint});
}

/// @nodoc
class __$$DeepBlockTargetImplCopyWithImpl<$Res>
    extends _$DeepBlockTargetCopyWithImpl<$Res, _$DeepBlockTargetImpl>
    implements _$$DeepBlockTargetImplCopyWith<$Res> {
  __$$DeepBlockTargetImplCopyWithImpl(
    _$DeepBlockTargetImpl _value,
    $Res Function(_$DeepBlockTargetImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DeepBlockTarget
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? featureName = null,
    Object? nodeTexts = null,
    Object? iconCodePoint = null,
  }) {
    return _then(
      _$DeepBlockTargetImpl(
        featureName: null == featureName
            ? _value.featureName
            : featureName // ignore: cast_nullable_to_non_nullable
                  as String,
        nodeTexts: null == nodeTexts
            ? _value._nodeTexts
            : nodeTexts // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        iconCodePoint: null == iconCodePoint
            ? _value.iconCodePoint
            : iconCodePoint // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DeepBlockTargetImpl implements _DeepBlockTarget {
  const _$DeepBlockTargetImpl({
    required this.featureName,
    required final List<String> nodeTexts,
    this.iconCodePoint = 0xe05d,
  }) : _nodeTexts = nodeTexts;

  factory _$DeepBlockTargetImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeepBlockTargetImplFromJson(json);

  /// Human-readable feature name (e.g., "Shorts", "Reels")
  @override
  final String featureName;

  /// Content descriptions / text to match in the accessibility node tree
  final List<String> _nodeTexts;

  /// Content descriptions / text to match in the accessibility node tree
  @override
  List<String> get nodeTexts {
    if (_nodeTexts is EqualUnmodifiableListView) return _nodeTexts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_nodeTexts);
  }

  /// Icon codepoint for the UI
  @override
  @JsonKey()
  final int iconCodePoint;

  @override
  String toString() {
    return 'DeepBlockTarget(featureName: $featureName, nodeTexts: $nodeTexts, iconCodePoint: $iconCodePoint)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeepBlockTargetImpl &&
            (identical(other.featureName, featureName) ||
                other.featureName == featureName) &&
            const DeepCollectionEquality().equals(
              other._nodeTexts,
              _nodeTexts,
            ) &&
            (identical(other.iconCodePoint, iconCodePoint) ||
                other.iconCodePoint == iconCodePoint));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    featureName,
    const DeepCollectionEquality().hash(_nodeTexts),
    iconCodePoint,
  );

  /// Create a copy of DeepBlockTarget
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeepBlockTargetImplCopyWith<_$DeepBlockTargetImpl> get copyWith =>
      __$$DeepBlockTargetImplCopyWithImpl<_$DeepBlockTargetImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DeepBlockTargetImplToJson(this);
  }
}

abstract class _DeepBlockTarget implements DeepBlockTarget {
  const factory _DeepBlockTarget({
    required final String featureName,
    required final List<String> nodeTexts,
    final int iconCodePoint,
  }) = _$DeepBlockTargetImpl;

  factory _DeepBlockTarget.fromJson(Map<String, dynamic> json) =
      _$DeepBlockTargetImpl.fromJson;

  /// Human-readable feature name (e.g., "Shorts", "Reels")
  @override
  String get featureName;

  /// Content descriptions / text to match in the accessibility node tree
  @override
  List<String> get nodeTexts;

  /// Icon codepoint for the UI
  @override
  int get iconCodePoint;

  /// Create a copy of DeepBlockTarget
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeepBlockTargetImplCopyWith<_$DeepBlockTargetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
