import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static const String _lowBalanceKey = 'low_balance_enabled';
  static const String _monthlyReportKey = 'monthly_report_enabled';
  static const String _thresholdKey = 'low_balance_threshold';
  
  static const MethodChannel _channel = MethodChannel('expense_tracker/notifications');

  static Future<void> init() async {
    // Load saved preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.getBool(_lowBalanceKey) ?? true;
    await prefs.getBool(_monthlyReportKey) ?? true;
    await prefs.getDouble(_thresholdKey) ?? 1000.0;
    
    // Initialize platform-specific code if needed
    try {
      await _channel.invokeMethod('initialize');
      print('✅ Notification service initialized');
    } catch (e) {
      print('⚠️ Could not initialize notifications: $e');
      // Fail silently - app will work without notifications
    }
  }

  static Future<void> checkLowBalance(double balance) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_lowBalanceKey) ?? true;

    print('\n=== Low Balance Check ===');
    print('Balance received: $balance');
    print('Notifications enabled: $enabled');

    // Skip if balance is invalid
    if (balance <= 0) {
      print('❌ Invalid balance: $balance');
      return;
    }

    // Check if balance is 1000 or below
    if (enabled && balance <= 1000.00) {
      print('⚠️ Low balance detected: $balance <= 1000.00');
      try {
        await showNotification(
          title: '⚠️ Low Balance Alert',
          body: 'Your balance is now ₱${balance.toStringAsFixed(2)}',
          type: NotificationType.lowBalance,
        );
        print('✅ Notification sent successfully');
      } catch (e) {
        print('❌ Error showing notification: $e');
      }
    } else {
      print('✓ Balance is above threshold: $balance > 1000.00');
    }
    print('=========================\n');
  }

  static Future<void> sendMonthlyReport(
    int transactionCount,
    double totalExpense,
    double totalIncome,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_monthlyReportKey) ?? true;

    if (enabled) {
      await showNotification(
        title: 'Monthly Financial Report',
        body: 'Income: ₱${totalIncome.toStringAsFixed(2)}\n'
            'Expenses: ₱${totalExpense.toStringAsFixed(2)}\n'
            'Transactions: $transactionCount',
        type: NotificationType.monthlyReport,
      );
    }
  }

  // Helper method for showing notifications
  static Future<void> showNotification({
    required String title,
    required String body,
    required NotificationType type,
  }) async {
    print('\n=== Showing Notification ===');
    print('Title: $title');
    print('Body: $body');

    try {
      // For now, just log the notification
      print('📱 NOTIFICATION: $title - $body');
      
      // Try to show a real notification if platform supports it
      try {
        await _channel.invokeMethod('showNotification', {
          'id': type.index,
          'title': title,
          'body': body,
          'type': type.name,
        });
        print('✅ Platform notification sent');
      } catch (e) {
        print('⚠️ Could not show platform notification: $e');
        // Fail silently - app will work without notifications
      }
    } catch (e) {
      print('❌ Error creating notification: $e');
      rethrow;
    }
    print('=========================\n');
  }

  // Settings methods
  static Future<void> setLowBalanceAlert(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lowBalanceKey, enabled);
  }

  static Future<void> setMonthlyReportAlert(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_monthlyReportKey, enabled);
  }

  static Future<void> setLowBalanceThreshold(double threshold) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_thresholdKey, threshold);
  }
}

enum NotificationType {
  lowBalance,
  monthlyReport,
}
