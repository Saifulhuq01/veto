import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionNotifier extends StateNotifier<bool> {
  SubscriptionNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('veto_is_pro') ?? false;
  }

  Future<void> setPro(bool isPro) async {
    state = isPro;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('veto_is_pro', isPro);
  }

  Future<void> buyPro() async {
    await setPro(true);
  }
}

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, bool>((ref) {
  return SubscriptionNotifier();
});
