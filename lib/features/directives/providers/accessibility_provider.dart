import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../bridge/veto_method_channel.dart';

/// State of the Accessibility Service permission.
class AccessibilityState {
  const AccessibilityState({
    required this.isEnabled,
    required this.isChecking,
  });

  final bool isEnabled;
  final bool isChecking;

  AccessibilityState copyWith({
    bool? isEnabled,
    bool? isChecking,
  }) {
    return AccessibilityState(
      isEnabled: isEnabled ?? this.isEnabled,
      isChecking: isChecking ?? this.isChecking,
    );
  }
}

/// Notifier that checks the Accessibility Service permission and registers
/// an App Lifecycle observer to check whenever the user returns to the app.
class AccessibilityNotifier extends StateNotifier<AccessibilityState>
    with WidgetsBindingObserver {
  AccessibilityNotifier(this._channel)
      : super(const AccessibilityState(isEnabled: false, isChecking: true)) {
    WidgetsBinding.instance.addObserver(this);
    checkStatus();
  }

  final VetoMethodChannel _channel;

  /// Check whether the Accessibility Service is active in system settings.
  Future<void> checkStatus() async {
    state = state.copyWith(isChecking: true);
    final enabled = await _channel.isAccessibilityServiceEnabled();
    state = AccessibilityState(isEnabled: enabled, isChecking: false);
  }

  /// Launch system settings page directly to Accessibility section.
  Future<void> openSettings() async {
    await _channel.openAccessibilitySettings();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check permission status when user returns from settings/background
    if (state == AppLifecycleState.resumed) {
      checkStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

final accessibilityProvider =
    StateNotifierProvider<AccessibilityNotifier, AccessibilityState>(
  (ref) => AccessibilityNotifier(VetoMethodChannel()),
);
