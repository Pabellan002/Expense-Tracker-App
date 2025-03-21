import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/user_provider.dart';
import '../pages/edit_transaction_page.dart';
import '../theme/app_theme.dart';
import '../config/api_config.dart';

enum TimePeriod { today, week, month }

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => RecordsPageState();
}

class RecordsPageState extends State<RecordsPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Map<String, dynamic>> _incomeRecords = [];
  List<Map<String, dynamic>> _expenseRecords = [];
  DateTime _selectedDate = DateTime.now();
  TimePeriod _selectedPeriod = TimePeriod.month;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadTransactions();
      }
    });
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final userData = Provider.of<UserProvider>(context, listen: false).userData;
    if (userData == null) return;

    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadTransactionsByType('income'),
        _loadTransactionsByType('expense'),
      ]);
    } catch (e) {
      print('Error loading transactions: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadTransactionsByType(String type) async {
    final userData = Provider.of<UserProvider>(context, listen: false).userData;
    if (userData == null) return;

    try {
      print(
          'Loading transactions for date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}');

      final requestData = {
        'user_id': userData['user_id'],
        'type': type,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      };
      print('Request data: $requestData');

      final response = await http.get(
        Uri.parse(ApiConfig.transactionEndpoint).replace(
          queryParameters: {
            'operation': 'getTransactions',
            'json': jsonEncode(requestData),
          },
        ),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final String responseBody = response.body.trim();
        if (responseBody.isEmpty) {
          setState(() {
            if (type == 'income') {
              _incomeRecords = [];
            } else {
              _expenseRecords = [];
            }
          });
          return;
        }

        try {
          final decodedData = jsonDecode(responseBody);
          if (decodedData is List) {
            if (mounted) {
              setState(() {
                if (type == 'income') {
                  _incomeRecords = List<Map<String, dynamic>>.from(decodedData);
                  print('Income records loaded: ${_incomeRecords.length}');
                } else {
                  _expenseRecords =
                      List<Map<String, dynamic>>.from(decodedData);
                  print('Expense records loaded: ${_expenseRecords.length}');
                }
              });
            }
          } else if (decodedData is Map && decodedData.containsKey('error')) {
            print('Server error: ${decodedData['error']}');
            throw Exception(decodedData['error']);
          }
        } catch (e) {
          print('JSON decode error: $e');
          print('Response body: $responseBody');
          throw Exception('Invalid response format');
        }
      } else {
        _showErrorDialog('Failed to load transactions');
        return;
      }
    } catch (e) {
      print('Error loading $type transactions: $e');
      if (mounted) {
        _showErrorDialog('Error loading $type transactions');
      }
    }
  }

  void _changeMonth(int months) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + months,
      );
      _loadTransactions();
    });
  }

  double _calculateTotal(List<Map<String, dynamic>> transactions) {
    return transactions.fold(
        0.0,
        (sum, transaction) =>
            sum + double.parse(transaction['amount'].toString()));
  }

  List<Map<String, dynamic>> _filterTransactionsByPeriod(
      List<Map<String, dynamic>> transactions) {
    return transactions.where((transaction) {
      final transactionDate = DateTime.parse(transaction['transaction_date']);

      switch (_selectedPeriod) {
        case TimePeriod.today:
          // Show only transactions from selected date
          return DateFormat('yyyy-MM-dd').format(transactionDate) ==
              DateFormat('yyyy-MM-dd').format(_selectedDate);

        case TimePeriod.week:
          // Get the start and end of selected month's week
          final startOfMonth =
              DateTime(_selectedDate.year, _selectedDate.month, 1);
          final currentWeek = ((_selectedDate.day - 1) ~/ 7);
          final startOfWeek = startOfMonth.add(Duration(days: currentWeek * 7));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));

          return transactionDate
                  .isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
              transactionDate
                  .isBefore(endOfWeek.add(const Duration(days: 1))) &&
              transactionDate.month == _selectedDate.month;

        case TimePeriod.month:
          // Show transactions from selected month
          return transactionDate.year == _selectedDate.year &&
              transactionDate.month == _selectedDate.month;
      }
    }).toList();
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case TimePeriod.today:
        return DateFormat('MMMM d, yyyy').format(_selectedDate);
      case TimePeriod.week:
        final startOfMonth =
            DateTime(_selectedDate.year, _selectedDate.month, 1);
        final currentWeek = ((_selectedDate.day - 1) ~/ 7);
        final startOfWeek = startOfMonth.add(Duration(days: currentWeek * 7));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d').format(endOfWeek)}';
      case TimePeriod.month:
        return DateFormat('MMMM yyyy').format(_selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final filteredIncome = _filterTransactionsByPeriod(_incomeRecords);
    final filteredExpense = _filterTransactionsByPeriod(_expenseRecords);
    final totalIncome = _calculateTotal(filteredIncome);
    final totalExpense = _calculateTotal(filteredExpense);
    final balance = totalIncome - totalExpense;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Wallet',
          style: AppTheme.headingStyle,
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final DateTime now = DateTime.now();
              final DateTime lastDate = DateTime(now.year + 1, 12, 31);
              final DateTime firstDate = DateTime(2020, 1, 1);

              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: firstDate,
                lastDate: lastDate,
                initialDatePickerMode: DatePickerMode.day,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                            primary: Theme.of(context).primaryColor,
                          ),
                    ),
                    child: child!,
                  );
                },
              );

              if (picked != null && mounted) {
                setState(() {
                  _selectedDate = picked;
                });
                _loadTransactions();
              }
            },
            icon: const Icon(Icons.calendar_month),
            label: Text(
              DateFormat('yyyy MMM').format(_selectedDate),
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Cards Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Period Filter
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPeriodButton('Today', TimePeriod.today),
                          const SizedBox(width: 8),
                          _buildPeriodButton('Week', TimePeriod.week),
                          const SizedBox(width: 8),
                          _buildPeriodButton('Month', TimePeriod.month),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Income',
                              totalIncome,
                              Colors.green,
                              Icons.arrow_upward,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSummaryCard(
                              'Expense',
                              totalExpense,
                              Colors.red,
                              Icons.arrow_downward,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryCard(
                        'Balance',
                        balance,
                        Colors.blue,
                        Icons.account_balance_wallet,
                      ),
                    ],
                  ),
                ),

                // Tab Bar
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Income'),
                    Tab(text: 'Expense'),
                  ],
                ),

                // Transaction Lists
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTransactionList(filteredIncome, true),
                      _buildTransactionList(filteredExpense, false),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCard(
      String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '₱${NumberFormat('#,##0.00').format(amount)}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(
      List<Map<String, dynamic>> transactions, bool isIncome) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isIncome ? Icons.account_balance_wallet : Icons.money_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${isIncome ? 'income' : 'expense'} records found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      );
    }

    final groupedTransactions = _groupTransactionsByDate(transactions);
    final dates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final dayTransactions = groupedTransactions[date]!;
        final dayTotal = _calculateTotal(dayTransactions);
        final formattedDate =
            DateFormat('MMMM dd, yyyy').format(DateTime.parse(date));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '₱${NumberFormat('#,##0.00').format(dayTotal)}',
                    style: TextStyle(
                      color: isIncome ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ...dayTransactions.map((transaction) {
              return _buildTransactionItem(transaction);
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final amount = double.parse(transaction['amount'].toString());
    final isExpense = transaction['type'] == 'expense';
    final date = DateTime.parse(transaction['transaction_date']);

    return Dismissible(
      key: Key(transaction['transaction_id'].toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Transaction'),
            content:
                const Text('Are you sure you want to delete this transaction?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _deleteTransaction(transaction);
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditTransactionPage(
                transaction: transaction,
              ),
            ),
          );
          if (result == true) {
            refreshData();
          }
        },
        child: Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    (isExpense ? AppTheme.expenseColor : AppTheme.incomeColor)
                        .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                color: isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
              ),
            ),
            title: Text(
              transaction['category_name'] ?? 'Unknown Category',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (transaction['subcategory_name']?.isNotEmpty ?? false)
                  Text(
                    transaction['subcategory_name'],
                    style: TextStyle(
                      color: AppTheme.secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, yyyy').format(date),
                  style: TextStyle(
                    color: AppTheme.secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
                if (transaction['note']?.isNotEmpty ?? false)
                  Text(
                    transaction['note'],
                    style: TextStyle(
                      color: AppTheme.secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            trailing: Text(
              '${isExpense ? '-' : '+'}₱${NumberFormat('#,##0.00').format(amount)}',
              style: TextStyle(
                color: isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupTransactionsByDate(
      List<Map<String, dynamic>> transactions) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (var transaction in transactions) {
      final date = DateTime.parse(transaction['transaction_date']);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(transaction);
    }
    return grouped;
  }

  Future<void> refreshData() async {
    print('Refreshing transaction data...'); // Debug print
    if (mounted) {
      await _loadTransactions();
      // Also refresh user data to update balances
      if (mounted) {
        await Provider.of<UserProvider>(context, listen: false)
            .refreshUserData();
      }
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transportation':
        return Colors.blue;
      case 'entertainment':
        return Colors.purple;
      case 'bills':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transportation':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'bills':
        return Icons.receipt;
      default:
        return Icons.category;
    }
  }

  Widget _buildPeriodButton(String label, TimePeriod period) {
    final isSelected = _selectedPeriod == period;
    return InkWell(
      onTap: () => setState(() {
        _selectedPeriod = period;
        _loadTransactions();
      }),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.secondaryTextColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<void> _deleteTransaction(Map<String, dynamic> transaction) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (!userProvider.isLoggedIn) return;

      final response = await http.get(
        Uri.parse(ApiConfig.transactionEndpoint).replace(
          queryParameters: {
            'operation': 'deleteTransaction',
            'json': jsonEncode({
              'user_id': userProvider.userData!['user_id'],
              'transaction_id': transaction['transaction_id'],
            }),
          },
        ),
      );

      print('Delete response: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          // Show success message
          if (mounted) {
            _showSuccessDialog('Transaction deleted successfully');
            // Refresh the transactions list and wallet balances
            await userProvider.refreshWalletBalances();
            await refreshData();
          }
        } else {
          throw Exception(result['message'] ?? 'Failed to delete transaction');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting transaction: $e'); // Debug print
      if (mounted) {
        _showErrorDialog('Error: ${e.toString()}');
      }
    }
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
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
