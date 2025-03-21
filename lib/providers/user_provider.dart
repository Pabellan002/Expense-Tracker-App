import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class UserProvider extends ChangeNotifier {
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _paymentMethods = [];
  Map<int, double> _balances = {};

  Map<String, dynamic>? get userData => _userData;
  List<Map<String, dynamic>> get paymentMethods => _paymentMethods;
  Map<int, double> get balances => _balances;

  double getBalanceForPaymentMethod(int paymentMethodId) {
    return _balances[paymentMethodId] ?? 0.0;
  }

  double getWalletBalance(int paymentMethodId) {
    print(
        'Getting balance for method $paymentMethodId: ${_balances[paymentMethodId] ?? 0.0}'); // Debug print
    return _balances[paymentMethodId] ?? 0.0;
  }

  Future<void> refreshUserData() async {
    try {
      if (_userData == null || _userData!['user_id'] == null) {
        print('Cannot refresh user data: No user ID available');
        return;
      }
      
      print('Refreshing user data for ID: ${_userData!['user_id']}');
      
      final response = await http.post(
        Uri.parse(ApiConfig.userEndpoint),
        body: {
          'operation': 'getUserData',
          'json': jsonEncode({'user_id': _userData!['user_id']}),
        },
      );

      print('User data refresh response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data is Map<String, dynamic> && data.containsKey('user_id')) {
          print('Updated user data received: $data');
          _userData = data;
          
          // Check if profile image is included
          if (data.containsKey('profile_image')) {
            print('Profile image URL: ${data['profile_image']}');
          } else {
            print('No profile image in response');
          }
          
          await refreshWalletBalances();
          notifyListeners();
        } else {
          print('Invalid user data format received: $data');
        }
      } else {
        print('Failed to refresh user data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }

  Future<void> refreshWalletBalances() async {
    if (_userData == null) {
      print('❌ Cannot refresh balances: No user data'); // Debug print
      return;
    }

    try {
      print('\n=== Refreshing Wallet Balances ===');
      print('👤 User ID: ${_userData!['user_id']}');

      final response = await http.get(
        Uri.parse(ApiConfig.userEndpoint).replace(
          queryParameters: {
            'operation': 'getWalletBalances',
            'json': jsonEncode({'user_id': _userData!['user_id']}),
          },
        ),
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📡 Raw Response Body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          print('⚠️ Warning: Empty response body');
          return;
        }

        try {
          final List<dynamic> data = jsonDecode(response.body);
          print('📊 Decoded data: $data');

          _balances.clear();
          print('🗑️ Cleared existing balances');

          for (var item in data) {
            print('💰 Processing balance item: $item');
            final methodId = int.parse(item['method_id'].toString());
            final balance = double.parse(item['balance'].toString());
            _balances[methodId] = balance;
            print('✅ Updated balance for method $methodId: $balance');
          }

          print('📱 Final balances map: $_balances');
          notifyListeners();
          print('🔄 Notified listeners of balance updates');
        } catch (e) {
          print('❌ Error parsing response: $e');
          if (e is FormatException) {
            print('🔍 Response that failed to parse: ${response.body}');
          }
        }
      } else {
        print('❌ API request failed with status: ${response.statusCode}');
        print('❌ Error response: ${response.body}');
      }
      print('=== End of Wallet Balance Refresh ===\n');
    } catch (e) {
      print('❌ Error refreshing wallet balances: $e');
      print('Stack trace: ${e is Error ? e.stackTrace : 'No stack trace'}');
    }
  }

  Future<bool> updateWalletBalance(int paymentMethodId, double amount) async {
    if (_userData == null) return false;

    try {
      print(
          'Sending wallet update: User ID: ${_userData!['user_id']}, Method ID: $paymentMethodId, Amount: $amount'); // Debug print

      final response = await http.get(
        Uri.parse(ApiConfig.userEndpoint).replace(
          queryParameters: {
            'operation': 'updateWalletBalance',
            'json': jsonEncode({
              'user_id': _userData!['user_id'],
              'payment_method_id': paymentMethodId,
              'amount': amount,
            }),
          },
        ),
      );

      print('Wallet update response: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          await refreshWalletBalances(); // Refresh balances after successful update
          return true;
        } else {
          print('Wallet update failed: ${result['message']}'); // Debug print
          return false;
        }
      }
    } catch (e) {
      print('Error updating wallet balance: $e');
    }
    return false;
  }

  void setUser(Map<String, dynamic> user) {
    _userData = user;
    refreshWalletBalances(); // Refresh balances when user is set
    notifyListeners();
  }

  void clearUser() {
    _userData = null;
    _balances.clear();
    notifyListeners();
  }

  bool get isLoggedIn => _userData != null;

  void logout() {
    _userData = null;
    notifyListeners();
    // Clear any stored credentials if you're using them
  }

  void updateUser(Map<String, dynamic> updatedUser) {
    _userData = updatedUser;
    notifyListeners();
  }

  void updateUserData(Map<String, dynamic> updatedData) {
    _userData = updatedData;
    notifyListeners();
  }

  String? get profileImageUrl {
    if (userData == null || userData!['profile_image'] == null || userData!['profile_image'].toString().isEmpty) {
      return null;
    }
    return userData!['profile_image'];
  }
}
