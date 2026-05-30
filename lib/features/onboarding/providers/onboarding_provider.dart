import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../bridge/veto_method_channel.dart';

/// Onboarding state — tracks which step the user is on and permission statuses.
class OnboardingState {
  const OnboardingState({
    this.currentStep = 0,
    this.totalSteps = 4,
    this.isAccessibilityEnabled = false,
    this.isUsageStatsEnabled = false,
    this.isOverlayEnabled = false,
    this.selectedAppsToBlock = const [],
    this.isCompleted = false,
    this.isLoading = true,
  });

  final int currentStep;
  final int totalSteps;
  final bool isAccessibilityEnabled;
  final bool isUsageStatsEnabled;
  final bool isOverlayEnabled;
  final List<String> selectedAppsToBlock;
  final bool isCompleted;
  final bool isLoading;

  OnboardingState copyWith({
    int? currentStep,
    bool? isAccessibilityEnabled,
    bool? isUsageStatsEnabled,
    bool? isOverlayEnabled,
    List<String>? selectedAppsToBlock,
    bool? isCompleted,
    bool? isLoading,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      isAccessibilityEnabled: isAccessibilityEnabled ?? this.isAccessibilityEnabled,
      isUsageStatsEnabled: isUsageStatsEnabled ?? this.isUsageStatsEnabled,
      isOverlayEnabled: isOverlayEnabled ?? this.isOverlayEnabled,
      selectedAppsToBlock: selectedAppsToBlock ?? this.selectedAppsToBlock,
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get allPermissionsGranted =>
      isAccessibilityEnabled && isUsageStatsEnabled && isOverlayEnabled;
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingState()) {
    _init();
  }

  final _channel = VetoMethodChannel();

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('veto_onboarding_completed') ?? false;
    if (completed) {
      state = state.copyWith(isCompleted: true, isLoading: false);
      return;
    }
    await refreshPermissions();
    state = state.copyWith(isLoading: false);
  }

  Future<void> refreshPermissions() async {
    final accessibility = await _channel.isAccessibilityServiceEnabled();
    final usageStats = await _channel.checkUsageStatsPermission();
    final overlay = await _channel.checkOverlayPermission();
    state = state.copyWith(
      isAccessibilityEnabled: accessibility,
      isUsageStatsEnabled: usageStats,
      isOverlayEnabled: overlay,
    );
  }

  void nextStep() {
    if (state.currentStep < state.totalSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step < state.totalSteps) {
      state = state.copyWith(currentStep: step);
    }
  }

  void toggleAppToBlock(String packageName) {
    final current = List<String>.from(state.selectedAppsToBlock);
    if (current.contains(packageName)) {
      current.remove(packageName);
    } else {
      current.add(packageName);
    }
    state = state.copyWith(selectedAppsToBlock: current);
  }

  Future<void> openAccessibilitySettings() async {
    await _channel.openAccessibilitySettings();
  }

  Future<void> requestUsageStatsPermission() async {
    await _channel.requestUsageStatsPermission();
  }

  Future<void> requestOverlayPermission() async {
    await _channel.requestOverlayPermission();
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('veto_onboarding_completed', true);

    // Apply selected blocked apps
    for (final pkg in state.selectedAppsToBlock) {
      await _channel.setDeepBlockRule(pkg, ['*'], true);
    }

    state = state.copyWith(isCompleted: true);
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>(
  (ref) => OnboardingNotifier(),
);
