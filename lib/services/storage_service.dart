import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_data.dart';

class StorageService {
  static const String _keyHighScore = 'labdrop_high_score';
  static const String _keyVolts = 'labdrop_volts';
  static const String _keyUnlockedThemes = 'labdrop_unlocked_themes';
  static const String _keySelectedTheme = 'labdrop_selected_theme';
  static const String _keyVipPass = 'labdrop_vip_pass';
  static const String _keyVoltMultiplier = 'labdrop_volt_multiplier';

  SharedPreferences? _prefs;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      _prefs = null;
    }
  }

  Future<PlayerData> loadPlayerData() async {
    if (_prefs == null) {
      await init();
    }
    final prefs = _prefs;
    if (prefs == null) {
      return PlayerData();
    }

    final highScore = prefs.getInt(_keyHighScore) ?? 0;
    final volts = prefs.getInt(_keyVolts) ?? 250;
    final unlockedList =
        prefs.getStringList(_keyUnlockedThemes) ?? <String>['cyber_science'];
    final selectedTheme = prefs.getString(_keySelectedTheme) ?? 'cyber_science';
    final hasVip = prefs.getBool(_keyVipPass) ?? false;
    final voltMultiplier = prefs.getInt(_keyVoltMultiplier) ?? 1;

    return PlayerData(
      highScore: highScore,
      volts: volts,
      unlockedThemeIds: unlockedList.toSet(),
      selectedThemeId: selectedTheme,
      hasVipPass: hasVip,
      voltMultiplierLevel: voltMultiplier,
    );
  }

  Future<void> savePlayerData(PlayerData data) async {
    final prefs = _prefs;
    if (prefs == null) return;

    await prefs.setInt(_keyHighScore, data.highScore);
    await prefs.setInt(_keyVolts, data.volts);
    await prefs.setStringList(
      _keyUnlockedThemes,
      data.unlockedThemeIds.toList(),
    );
    await prefs.setString(_keySelectedTheme, data.selectedThemeId);
    await prefs.setBool(_keyVipPass, data.hasVipPass);
    await prefs.setInt(_keyVoltMultiplier, data.voltMultiplierLevel);
  }
}
