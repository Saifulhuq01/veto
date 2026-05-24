import 'package:freezed_annotation/freezed_annotation.dart';

part 'system_directive.freezed.dart';
part 'system_directive.g.dart';

/// Type of system directive.
enum DirectiveType {
  @JsonValue('appLimit')
  appLimit,
  @JsonValue('deepBlock')
  deepBlock,
}

/// Core data model for a system directive rule.
/// Manages both app-level limits and deep node blocking targets.
@freezed
class SystemDirective with _$SystemDirective {
  const factory SystemDirective({
    required String id,
    required String appName,
    required String packageName,
    required DirectiveType type,
    @Default(false) bool isActive,
    AppLimit? limit,
    DeepBlockTarget? deepBlockTarget,
  }) = _SystemDirective;

  factory SystemDirective.fromJson(Map<String, dynamic> json) =>
      _$SystemDirectiveFromJson(json);
}

/// App usage limit configuration.
@freezed
class AppLimit with _$AppLimit {
  const factory AppLimit({
    required int dailyLimitMinutes,
    @Default(0) int usedMinutes,
  }) = _AppLimit;

  factory AppLimit.fromJson(Map<String, dynamic> json) =>
      _$AppLimitFromJson(json);
}

/// Deep block target — specifies which in-app feature to intercept.
@freezed
class DeepBlockTarget with _$DeepBlockTarget {
  const factory DeepBlockTarget({
    /// Human-readable feature name (e.g., "Shorts", "Reels")
    required String featureName,

    /// Content descriptions / text to match in the accessibility node tree
    required List<String> nodeTexts,

    /// Icon codepoint for the UI
    @Default(0xe05d) int iconCodePoint,
  }) = _DeepBlockTarget;

  factory DeepBlockTarget.fromJson(Map<String, dynamic> json) =>
      _$DeepBlockTargetFromJson(json);
}
