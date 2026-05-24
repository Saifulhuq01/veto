// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_directive.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SystemDirectiveImpl _$$SystemDirectiveImplFromJson(
  Map<String, dynamic> json,
) => _$SystemDirectiveImpl(
  id: json['id'] as String,
  appName: json['appName'] as String,
  packageName: json['packageName'] as String,
  type: $enumDecode(_$DirectiveTypeEnumMap, json['type']),
  isActive: json['isActive'] as bool? ?? false,
  limit: json['limit'] == null
      ? null
      : AppLimit.fromJson(json['limit'] as Map<String, dynamic>),
  deepBlockTarget: json['deepBlockTarget'] == null
      ? null
      : DeepBlockTarget.fromJson(
          json['deepBlockTarget'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$$SystemDirectiveImplToJson(
  _$SystemDirectiveImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'appName': instance.appName,
  'packageName': instance.packageName,
  'type': _$DirectiveTypeEnumMap[instance.type]!,
  'isActive': instance.isActive,
  'limit': instance.limit,
  'deepBlockTarget': instance.deepBlockTarget,
};

const _$DirectiveTypeEnumMap = {
  DirectiveType.appLimit: 'appLimit',
  DirectiveType.deepBlock: 'deepBlock',
};

_$AppLimitImpl _$$AppLimitImplFromJson(Map<String, dynamic> json) =>
    _$AppLimitImpl(
      dailyLimitMinutes: (json['dailyLimitMinutes'] as num).toInt(),
      usedMinutes: (json['usedMinutes'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$AppLimitImplToJson(_$AppLimitImpl instance) =>
    <String, dynamic>{
      'dailyLimitMinutes': instance.dailyLimitMinutes,
      'usedMinutes': instance.usedMinutes,
    };

_$DeepBlockTargetImpl _$$DeepBlockTargetImplFromJson(
  Map<String, dynamic> json,
) => _$DeepBlockTargetImpl(
  featureName: json['featureName'] as String,
  nodeTexts: (json['nodeTexts'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  iconCodePoint: (json['iconCodePoint'] as num?)?.toInt() ?? 0xe05d,
);

Map<String, dynamic> _$$DeepBlockTargetImplToJson(
  _$DeepBlockTargetImpl instance,
) => <String, dynamic>{
  'featureName': instance.featureName,
  'nodeTexts': instance.nodeTexts,
  'iconCodePoint': instance.iconCodePoint,
};
