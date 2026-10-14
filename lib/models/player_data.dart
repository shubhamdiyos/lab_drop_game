import 'package:flutter/material.dart';

enum LabTheme {
  cyberScience(
    id: 'cyber_science',
    displayName: 'Cyber Science',
    description: 'Neon cyan laboratory grid with high-contrast telemetry.',
    costVolts: 0,
    backgroundTop: Color(0xFF0B1021),
    backgroundBottom: Color(0xFF152238),
    accentColor: Color(0xFF00E5FF),
    gridColor: Color(0x2200E5FF),
  ),
  magmaFoundry(
    id: 'magma_foundry',
    displayName: 'Magma Foundry',
    description: 'Superheated volcanic forge chamber with molten embers.',
    costVolts: 300,
    backgroundTop: Color(0xFF240B0B),
    backgroundBottom: Color(0xFF3E160C),
    accentColor: Color(0xFFFF6D00),
    gridColor: Color(0x22FF6D00),
  ),
  zeroGSpace(
    id: 'zero_g_space',
    displayName: 'Zero-G Space',
    description: 'Deep orbital research station bathed in nebula violet.',
    costVolts: 500,
    backgroundTop: Color(0xFF090619),
    backgroundBottom: Color(0xFF1B1035),
    accentColor: Color(0xFFE040FB),
    gridColor: Color(0x22E040FB),
  );

  const LabTheme({
    required this.id,
    required this.displayName,
    required this.description,
    required this.costVolts,
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.accentColor,
    required this.gridColor,
  });

  final String id;
  final String displayName;
  final String description;
  final int costVolts;
  final Color backgroundTop;
  final Color backgroundBottom;
  final Color accentColor;
  final Color gridColor;

  static LabTheme fromId(String id) {
    for (final theme in LabTheme.values) {
      if (theme.id == id) return theme;
    }
    return LabTheme.cyberScience;
  }
}

class PlayerData extends ChangeNotifier {
  PlayerData({
    int highScore = 0,
    int volts = 250,
    Set<String>? unlockedThemeIds,
    String selectedThemeId = 'cyber_science',
    bool hasVipPass = false,
    int voltMultiplierLevel = 1,
  })  : _highScore = highScore,
        _volts = volts,
        _unlockedThemeIds = unlockedThemeIds ?? {'cyber_science'},
        _selectedThemeId = selectedThemeId,
        _hasVipPass = hasVipPass,
        _voltMultiplierLevel = voltMultiplierLevel;

  int _highScore;
  int _volts;
  final Set<String> _unlockedThemeIds;
  String _selectedThemeId;
  bool _hasVipPass;
  int _voltMultiplierLevel;

  int get highScore => _highScore;
  int get volts => _volts;
  Set<String> get unlockedThemeIds => Set.unmodifiable(_unlockedThemeIds);
  String get selectedThemeId => _selectedThemeId;
  LabTheme get selectedTheme => LabTheme.fromId(_selectedThemeId);
  bool get hasVipPass => _hasVipPass;
  int get voltMultiplierLevel => _voltMultiplierLevel;

  bool isThemeUnlocked(LabTheme theme) => _unlockedThemeIds.contains(theme.id);

  void updateHighScore(int score) {
    if (score > _highScore) {
      _highScore = score;
      notifyListeners();
    }
  }

  void addVolts(int amount) {
    if (amount <= 0) return;
    final multiplier = _hasVipPass ? 2 : 1;
    _volts += amount * multiplier;
    notifyListeners();
  }

  bool spendVolts(int amount) {
    if (_volts < amount) return false;
    _volts -= amount;
    notifyListeners();
    return true;
  }

  bool unlockTheme(LabTheme theme) {
    if (_unlockedThemeIds.contains(theme.id)) {
      _selectedThemeId = theme.id;
      notifyListeners();
      return true;
    }
    if (_volts < theme.costVolts) {
      return false;
    }
    _volts -= theme.costVolts;
    _unlockedThemeIds.add(theme.id);
    _selectedThemeId = theme.id;
    notifyListeners();
    return true;
  }

  void selectTheme(LabTheme theme) {
    if (_unlockedThemeIds.contains(theme.id)) {
      _selectedThemeId = theme.id;
      notifyListeners();
    }
  }

  void activateVipPass() {
    _hasVipPass = true;
    for (final theme in LabTheme.values) {
      _unlockedThemeIds.add(theme.id);
    }
    _volts += 1000;
    notifyListeners();
  }

  bool upgradeVoltMultiplier({int cost = 200}) {
    if (_volts < cost) return false;
    _volts -= cost;
    _voltMultiplierLevel += 1;
    notifyListeners();
    return true;
  }
}
