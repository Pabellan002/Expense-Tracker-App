import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../config/api_config.dart';
import '../services/notification_service.dart';

class AddTransactionPage extends StatefulWidget {
  final String type;

  const AddTransactionPage({super.key, required this.type});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _subcategories = [];
  List<Map<String, dynamic>> _paymentMethods = [];

  int? _selectedCategoryId;
  int? _selectedSubcategoryId;
  int? _selectedPaymentMethodId;
  bool _isLoading = false;
  bool _isExpense = false;
  final _formKey = GlobalKey<FormState>();

  final _currencyFormatter = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  void _onAmountChanged() {}

  String _formatAmount(String value) {
    if (value.isEmpty) return '';

    value = value.replaceAll(RegExp(r'[^0-9]'), '');

    double amount = double.parse(value) / 100;

    return _currencyFormatter.format(amount);
  }

  @override
  void initState() {
    super.initState();
    _isExpense = widget.type == 'expense';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      print('🔄 Loading initial data...'); // Debug print
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (userProvider.isLoggedIn) {
        print('👤 User is logged in, refreshing user data...'); // Debug print
        await userProvider
            .refreshUserData(); // This will also refresh wallet balances
      }

      await Future.wait([
        _loadCategories(),
        _loadPaymentMethods(),
      ]);
    } catch (e) {
      print('❌ Error loading initial data: $e'); // Debug print
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.transactionEndpoint).replace(
          queryParameters: {
            'operation': 'getCategories',
            'json': jsonEncode({'type': widget.type}),
          },
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _categories =
              List<Map<String, dynamic>>.from(jsonDecode(response.body));
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to load categories');
    }
  }

  Future<void> _loadSubcategories(int categoryId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.transactionEndpoint).replace(
          queryParameters: {
            'operation': 'getSubcategories',
            'json': jsonEncode({'category_id': categoryId}),
          },
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _subcategories =
              List<Map<String, dynamic>>.from(jsonDecode(response.body));
          _selectedSubcategoryId = null;
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to load subcategories');
    }
  }

  Future<void> _loadPaymentMethods() async {
    try {
      print('🔄 Loading payment methods...'); // Debug print

      final response = await http.get(
        Uri.parse(ApiConfig.transactionEndpoint).replace(
          queryParameters: {
            'operation': 'getPaymentMethods',
            'json': '{}',
          },
        ),
      );

      print(
          '📡 Payment Methods Response Status: ${response.statusCode}'); // Debug print
      print(
          '📡 Payment Methods Response Body: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        setState(() {
          _paymentMethods =
              List<Map<String, dynamic>>.from(jsonDecode(response.body));
        });

        // Refresh wallet balances after loading payment methods
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (userProvider.isLoggedIn) {
          print(
              '👤 User is logged in, refreshing wallet balances...'); // Debug print
          await userProvider.refreshWalletBalances();

          // Print current balances for debugging
          for (var method in _paymentMethods) {
            final methodId = int.parse(method['method_id'].toString());
            final balance = userProvider.getWalletBalance(methodId);
            print(
                '💰 Method ${method['name']} (ID: $methodId) Balance: $balance'); // Debug print
          }
        } else {
          print(
              '❌ User not logged in, skipping balance refresh'); // Debug print
        }
      }
    } catch (e) {
      print('❌ Error loading payment methods: $e'); // Debug print
      _showErrorDialog('Failed to load payment methods');
    }
  }

  Future<bool> _checkBalance() async {
    if (widget.type != 'expense') return true;

    if (_selectedPaymentMethodId == null) {
      _showErrorDialog('Please select a payment method');
      return false;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final balance =
        userProvider.getBalanceForPaymentMethod(_selectedPaymentMethodId!);

    // Get transaction amount
    final cleanAmount =
        _amountController.text.replaceAll('₱', '').replaceAll(',', '').trim();
    final amount = double.parse(cleanAmount);

    if (amount > balance) {
      _showErrorDialog('Insufficient balance in selected payment method');
      return false;
    }

    return true;
  }

  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if subcategories exist but none is selected
    if (_subcategories.isNotEmpty && _selectedSubcategoryId == null) {
      _showErrorDialog('Please select a subcategory');
      return;
    }

    // Check balance before proceeding for expenses
    if (widget.type == 'expense') {
      final hasBalance = await _checkBalance();
      if (!hasBalance) return;
    }

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userData = userProvider.userData;

      if (userData == null) {
        _showErrorDialog('Please login first');
        return;
      }

      // Parse amount properly
      final cleanAmount =
          _amountController.text.replaceAll('₱', '').replaceAll(',', '').trim();
      final amount = double.parse(cleanAmount);

      // Prepare transaction data
      final transactionData = {
        'user_id': userData['user_id'],
        'type': widget.type,
        'amount': amount,
        'note': _noteController.text,
        'category_id': _selectedCategoryId,
        'subcategory_id': _selectedSubcategoryId ?? 0,
        'payment_method_id': _selectedPaymentMethodId,
        'transaction_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      };

      print('Sending transaction data: $transactionData'); // Debug print

      // Create the transaction
      final response = await http.post(
        Uri.parse(ApiConfig.transactionEndpoint),
        body: {
          'operation': 'addTransaction',
          'json': jsonEncode(transactionData),
        },
      );

      print('Transaction Response Status: ${response.statusCode}'); // Debug print
      print('Transaction Response Body: ${response.body}'); // Debug print

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          // Show success message
          if (mounted) {
            _showSuccessDialog('${widget.type.capitalize()} added successfully');

            // Refresh user data to update balances
            await userProvider.refreshUserData();
            
            // Check for low balance after expense transaction
            if (widget.type == 'expense' && _selectedPaymentMethodId != null) {
              final updatedBalance = userProvider.getBalanceForPaymentMethod(_selectedPaymentMethodId!);
              await NotificationService.checkLowBalance(updatedBalance);
            }
          }
        } else {
          throw Exception(result['message'] ?? 'Failed to add transaction');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      print('Error in _submitTransaction: $e'); // Debug print
      if (mounted) {
        _showErrorDialog('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _validateForm() {
    if (_amountController.text.isEmpty) {
      _showErrorDialog('Please enter amount');
      return false;
    }
    if (_selectedCategoryId == null) {
      _showErrorDialog('Please select category');
      return false;
    }
    if (_selectedPaymentMethodId == null) {
      _showErrorDialog('Please select payment method');
      return false;
    }
    return true;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); 
              Navigator.pop(context, true); 
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isExpense ? 'Add Expense' : 'Add Income'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Transaction Type Toggle
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isExpense = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: !_isExpense
                              ? AppTheme.incomeColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Income',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !_isExpense
                                ? Colors.white
                                : AppTheme.secondaryTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isExpense = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _isExpense
                              ? AppTheme.expenseColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Expense',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isExpense
                                ? Colors.white
                                : AppTheme.secondaryTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Form
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Amount Field with Currency Symbol
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            '₱',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              style: const TextStyle(fontSize: 24),
                              decoration: const InputDecoration(
                                hintText: '0.00',
                                border: InputBorder.none,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter an amount';
                                }
                                try {
                                  final cleanAmount = value
                                      .replaceAll('₱', '')
                                      .replaceAll(',', '')
                                      .trim();
                                  double.parse(cleanAmount);
                                  return null;
                                } catch (e) {
                                  return 'Please enter a valid amount';
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Category Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonFormField<int>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value:
                                int.parse(category['category_id'].toString()),
                            child: Text(category['name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                            if (value != null) {
                              _loadSubcategories(value);
                            }
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Subcategory Dropdown (if available)
                    if (_subcategories.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<int>(
                          value: _selectedSubcategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Subcategory',
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.subdirectory_arrow_right),
                          ),
                          items: _subcategories.map((subcategory) {
                            return DropdownMenuItem(
                              value: int.parse(
                                  subcategory['subcategory_id'].toString()),
                              child: Text(subcategory['name']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedSubcategoryId = value);
                          },
                        ),
                      ),

                    if (_subcategories.isNotEmpty) const SizedBox(height: 16),

                    // Payment Method Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Consumer<UserProvider>(
                        builder: (context, userProvider, child) {
                          return DropdownButtonFormField<int>(
                            value: _selectedPaymentMethodId,
                            decoration: InputDecoration(
                              labelText: 'Payment Method',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: _paymentMethods.map((method) {
                              final balance = userProvider.getWalletBalance(
                                  int.parse(method['method_id'].toString()));
                              print(
                                  'Rendering method ${method['name']} with balance: $balance');
                              return DropdownMenuItem(
                                value:
                                    int.parse(method['method_id'].toString()),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(method['name']),
                                    Text(
                                      '₱${balance.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: balance > 0
                                            ? AppTheme.incomeColor
                                            : AppTheme.secondaryTextColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedPaymentMethodId = value);
                            },
                            validator: (value) {
                              if (value == null)
                                return 'Please select a payment method';
                              return null;
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Note Field
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          labelText: 'Note',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Date Picker
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: Text(
                          DateFormat('MMMM dd, yyyy').format(_selectedDate),
                        ),
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitTransaction,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Save Transaction'),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double _getWalletBalance(int methodId) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return userProvider.getWalletBalance(methodId);
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
