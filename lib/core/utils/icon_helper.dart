import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class IconHelper {
  static IconData getIcon(String? iconName) {
    if (iconName == null) return LucideIcons.circle;

    switch (iconName.toLowerCase().trim()) {
      // Expenses
      case 'utensils':
      case 'coffee':
        return LucideIcons.utensils;
      case 'shopping-basket':
      case 'shopping-bag':
        return LucideIcons.shoppingBag;
      case 'car':
      case 'bike':
      case 'fuel':
        return LucideIcons.car;
      case 'zap':
      case 'wifi':
        return LucideIcons.zap;
      case 'home':
        return LucideIcons.home;
      case 'heart-pulse':
      case 'pill':
        return LucideIcons.heartPulse;
      case 'book-open':
      case 'graduation-cap':
        return LucideIcons.bookOpen;
      case 'shirt':
        return LucideIcons.shirt;
      case 'gamepad':
      case 'gamepad-2':
      case 'gamepad2':
      case 'clapperboard':
        return LucideIcons.gamepad2;
      case 'gift':
      case 'hand-heart':
        return LucideIcons.gift;
      case 'credit-card':
        return LucideIcons.creditCard;
      case 'briefcase':
        return LucideIcons.briefcase;
      case 'paw-print':
      case 'pawprint':
      case 'dog':
        return LucideIcons.dog;
      case 'more-horizontal':
      case 'more':
        return LucideIcons.moreHorizontal;

      // Income
      case 'banknote':
        return LucideIcons.banknote;
      case 'store':
        return LucideIcons.store;
      case 'laptop':
        return LucideIcons.laptop;
      case 'trending-up':
      case 'trendingup':
        return LucideIcons.trendingUp;
      case 'plus-circle':
        return LucideIcons.plusCircle;

      // Wallets
      case 'wallet':
        return LucideIcons.wallet;
      case 'landmark':
      case 'bank':
        return LucideIcons.landmark;
      case 'smartphone':
      case 'phone':
        return LucideIcons.smartphone;

      // Navigation & Actions
      case 'plus':
        return LucideIcons.plus;
      case 'scan':
      case 'camera':
        return LucideIcons.camera;
      case 'transfer':
      case 'arrow-left-right':
        return LucideIcons.arrowLeftRight;
      case 'chart':
      case 'pie-chart':
        return LucideIcons.pieChart;
      case 'bell':
        return LucideIcons.bell;
      case 'settings':
        return LucideIcons.settings;
      case 'trash':
      case 'trash-2':
        return LucideIcons.trash2;
      case 'pencil':
      case 'edit':
        return LucideIcons.pencil;
      case 'search':
        return LucideIcons.search;
      case 'lock':
        return LucideIcons.lock;
      case 'download':
        return LucideIcons.download;
      case 'upload':
        return LucideIcons.upload;

      default:
        return LucideIcons.circleDot;
    }
  }
}
