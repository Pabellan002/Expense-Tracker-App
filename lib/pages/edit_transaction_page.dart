import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../config/api_config.dart';
import '../providers/user_provider.dart';

class EditTransactionPage extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const EditTransactionPage({
    super.key,
    required this.transaction,
  });

  @override
  State<EditTransactionPage> createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedCategory;
  String? _selectedPaymentMethod;
  bool _isLoading = false;
  bool _isInitialized = false;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _paymentMethods = [];

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.transaction['amount'].toString();
    _noteController.text = widget.transaction['note'] ?? '';
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([
        _loadCategories(),
        _loadPaymentMethods(),
      ]);

      if (mounted) {
        setState(() {
          _selectedCategory = widget.transaction['category_id']?.toString();
          _selectedPaymentMethod =
              widget.transaction['payment_method_id']?.toString();
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.transactionEndpoint).replace(
          queryParameters: {
            'operation': 'getCategories',
            'json': jsonEncode({
              'type': widget.transaction['type'],
            }),
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _categories = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final userData =
          Provider.of<UserProvider>(context, listen: false).userData;
      if (userData == null) return;

      final response = await http.get(
        Uri.parse(ApiConfig.transactionEndpoint).replace(
          queryParameters: {
            'operation': 'getPaymentMethods',
            'json': jsonEncode({
              'user_id': userData['user_id'],
            }),
          },
        ),
      );

      print('Payment methods response: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          print('Empty response from payment methods API');
          return;
        }

        if (response.body.contains('<br />')) {
          print('PHP error in response: ${response.body}');
          return;
        }

        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _paymentMethods = List<Map<String, dynamic>>.from(data);
        });
      } else {
        print('Error status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading payment methods: $e');
      if (e is FormatException) {
        print('Raw response that caused error: ${e.source}');
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = widget.transaction['type'] == 'expense';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isExpense ? 'View Expense' : 'Edit Income',
          style: AppTheme.headingStyle,
        ),
        actions: [
          IconButton(
            onPressed: _showDeleteConfirmation,
            icon: const Icon(
              Icons.delete_outline,
              color: AppTheme.expenseColor,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transaction Type Indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isExpense
                        ? AppTheme.expenseColor.withOpacity(0.1)
                        : AppTheme.incomeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isExpense
                            ? AppTheme.expenseColor
                            : AppTheme.incomeColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isExpense ? 'Expense' : 'Income',
                        style: TextStyle(
                          color: isExpense
                              ? AppTheme.expenseColor
                              : AppTheme.incomeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Amount Section
                Card(
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Amount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _amountController,
                          enabled: !isExpense,
                          decoration: InputDecoration(
                            prefixText: '₱',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: AppTheme.surfaceColor,
                          ),
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isExpense
                                ? AppTheme.expenseColor
                                : AppTheme.incomeColor,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an amount';
                            }
                            if (double.tryParse(value
                                    .replaceAll('₱', '')
                                    .replaceAll(',', '')) ==
                                null) {
                              return 'Please enter a valid amount';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Category Section
                Card(
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.category_outlined, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Category',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isExpense) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.lock_outline,
                                  size: 16, color: AppTheme.secondaryTextColor),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildCategoryDropdown(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Method Section
                Card(
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_outlined,
                                size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Payment Method',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isExpense) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.lock_outline,
                                  size: 16, color: AppTheme.secondaryTextColor),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (isExpense)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _paymentMethods.firstWhere(
                                (m) =>
                                    m['method_id'].toString() ==
                                    widget.transaction['payment_method_id']
                                        .toString(),
                                orElse: () => {'name': 'Unknown'},
                              )['name'],
                              style: const TextStyle(fontSize: 16),
                            ),
                          )
                        else
                          _buildPaymentMethodDropdown(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Note Section
                Card(
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.note_outlined, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Note',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isExpense) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.lock_outline,
                                  size: 16, color: AppTheme.secondaryTextColor),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _noteController,
                          enabled: !isExpense,
                          decoration: InputDecoration(
                            hintText: 'Add a note',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: AppTheme.surfaceColor,
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Update/Delete Button
                if (!isExpense)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _updateTransaction,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Update Transaction'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateTransaction() async {
    // Only allow updates for income transactions
    if (widget.transaction['type'] == 'expense') {
      _showErrorDialog('Expense transactions cannot be edited');
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_selectedPaymentMethod == null) {
      _showErrorDialog('Please select payment method');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('Updating transaction...'); // Debug print
      final userData =
          Provider.of<UserProvider>(context, listen: false).userData;
      if (userData == null) return;

      // Parse the original amount from the text field
      final originalAmount = double.parse(_amountController.text
          .replaceAll('₱', '')
          .replaceAll(',', '')
          .trim());

      final requestData = {
        'user_id': userData['user_id'],
        'transaction_id': widget.transaction['transaction_id'],
        'amount': originalAmount,
        'note': _noteController.text.trim(),
        'category_id': int.parse(_selectedCategory!),
        'payment_method_id': int.parse(_selectedPaymentMethod!),
        'type': widget.transaction['type'],
        'transaction_date': widget.transaction['transaction_date'],
        'old_amount': widget.transaction['amount'],
      };

      print('Update request data: $requestData'); // Debug print

      final response = await http.post(
        Uri.parse(ApiConfig.transactionEndpoint),
        body: {
          'operation': 'updateTransaction',
          'json': jsonEncode(requestData),
        },
      );

      print('Update response: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        final bool isSuccess = response.body.isEmpty ||
            (jsonDecode(response.body)['success'] == true);

        if (isSuccess && mounted) {
          await Provider.of<UserProvider>(context, listen: false)
              .refreshUserData();

          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Success'),
                content: const Text('Transaction updated successfully'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context,
                          true); // Return to previous screen with refresh flag
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        } else {
          final message = response.body.isNotEmpty
              ? jsonDecode(response.body)['message'] ??
                  'Failed to update transaction'
              : 'Failed to update transaction';
          throw Exception(message);
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating transaction: $e'); // Debug print
      if (mounted) {
        _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteTransaction() async {
    try {
      setState(() => _isLoading = true);

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userData = userProvider.userData;

      if (userData == null) return;

      print('Sending delete request...'); // Debug print
      final response = await http.get(
        Uri.parse(ApiConfig.transactionEndpoint).replace(
          queryParameters: {
            'operation': 'deleteTransaction',
            'json': jsonEncode({
              'user_id': userData['user_id'],
              'transaction_id': widget.transaction['transaction_id'],
              'payment_method_id': widget.transaction['payment_method_id'],
              'type': widget.transaction['type'],
            }),
          },
        ),
      );

      print('Delete response status: ${response.statusCode}'); // Debug print
      print('Delete response body: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        // Consider empty response as success for delete operation
        final bool isSuccess = response.body.isEmpty ||
            (jsonDecode(response.body)['success'] == true);

        if (isSuccess && mounted) {
          // Refresh user data
          await userProvider.refreshUserData();

          // Show success dialog and return to previous screen
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Success'),
                content: const Text('Transaction deleted successfully'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(
                          context); // Close delete confirmation dialog
                      Navigator.pop(context,
                          true); // Return to previous screen with refresh flag
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        } else {
          final message = response.body.isNotEmpty
              ? jsonDecode(response.body)['message'] ??
                  'Failed to delete transaction'
              : 'Failed to delete transaction';
          throw Exception(message);
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting transaction: $e');
      if (mounted) {
        _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildCategoryDropdown() {
    if (!_isInitialized || _categories.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // For expense transactions, show the current category but disable editing
    if (widget.transaction['type'] == 'expense') {
      final currentCategory = _categories.firstWhere(
        (c) =>
            c['category_id'].toString() ==
            widget.transaction['category_id'].toString(),
        orElse: () => _categories.first,
      );

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          currentCategory['name'] ?? 'Unknown Category',
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    // For income transactions, allow editing
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        value: _selectedCategory,
        items: _categories.map((category) {
          return DropdownMenuItem<String>(
            value: category['category_id'].toString(),
            child: Text(category['name']),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedCategory = value);
          }
        },
      ),
    );
  }

  Widget _buildPaymentMethodDropdown() {
    if (!_isInitialized || _paymentMethods.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Initialize the selected payment method if it's null or invalid
    if (_selectedPaymentMethod == null ||
        !_paymentMethods
            .any((m) => m['method_id'].toString() == _selectedPaymentMethod)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedPaymentMethod =
              _paymentMethods.first['method_id'].toString();
        });
      });
      // Return loading indicator for this frame
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedPaymentMethod,
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      items: _paymentMethods.map((method) {
        return DropdownMenuItem<String>(
          value: method['method_id'].toString(),
          child: Text(method['name']),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedPaymentMethod = value);
        }
      },
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content:
            const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _deleteTransaction,
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
}
