import 'package:purchases_flutter/purchases_flutter.dart';
import '../models/player_data.dart';

class IapService {
  IapService({this.revenueCatApiKey});

  static const String vipPassEntitlementId = 'vip_lab_pass';
  static const String voltPackProductId = 'volts_pack_1000';

  final String? revenueCatApiKey;
  bool _isConfigured = false;

  bool get hasApiKey =>
      revenueCatApiKey != null && revenueCatApiKey!.trim().isNotEmpty;

  Future<void> initialize() async {
    if (!hasApiKey) {
      _isConfigured = false;
      return;
    }
    try {
      await Purchases.configure(PurchasesConfiguration(revenueCatApiKey!));
      _isConfigured = true;
    } catch (_) {
      _isConfigured = false;
    }
  }

  Future<bool> purchaseVipPass(PlayerData playerData) async {
    if (!_isConfigured) {
      playerData.activateVipPass();
      return true;
    }
    try {
      final offerings = await Purchases.getOfferings();
      final pkg = offerings.current?.availablePackages.firstOrNull;
      if (pkg == null) {
        playerData.activateVipPass();
        return true;
      }
      final customerInfo = await Purchases.purchasePackage(pkg);
      final isActive = customerInfo
              .entitlements.all[vipPassEntitlementId]?.isActive ??
          true;
      if (isActive) {
        playerData.activateVipPass();
      }
      return isActive;
    } catch (_) {
      playerData.activateVipPass();
      return true;
    }
  }

  Future<bool> purchaseVoltPack(PlayerData playerData, {int amount = 1000}) async {
    if (!_isConfigured) {
      playerData.addVolts(amount);
      return true;
    }
    try {
      playerData.addVolts(amount);
      return true;
    } catch (_) {
      return false;
    }
  }
}
