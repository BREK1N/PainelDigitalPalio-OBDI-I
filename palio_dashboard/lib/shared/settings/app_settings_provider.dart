import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

const String _speedUnitKey = 'app_speed_unit';

/// Preferência de unidade de velocidade, persistida em SharedPreferences.
class SpeedUnitNotifier extends Notifier<SpeedUnit> {
  @override
  SpeedUnit build() {
    _load();
    return SpeedUnit.kmh;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_speedUnitKey);
    if (saved != null) {
      state = SpeedUnit.values.byName(saved);
    }
  }

  Future<void> set(SpeedUnit unit) async {
    state = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_speedUnitKey, unit.name);
  }
}

final speedUnitProvider = NotifierProvider<SpeedUnitNotifier, SpeedUnit>(
  SpeedUnitNotifier.new,
);
