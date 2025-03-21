import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../config/api_config.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool _isLoading = false;
  Map<String, dynamic> _reportData = {};
  String _selectedType = 'expense';
  String _selectedPeriod = 'month';

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    try {
      final userData =
          Provider.of<UserProvider>(context, listen: false).userData;
      if (userData == null) return;

      final response = await http.get(
        Uri.parse(ApiConfig.transactionEndpoint).replace(
          queryParameters: {
            'operation': 'getReports',
            'json': jsonEncode({
              'user_id': userData['user_id'],
              'type': _selectedType,
              'period': _selectedPeriod,
            }),
          },
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _reportData = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print('Error loading reports: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reports'),
            if (_reportData['period'] != null)
              Text(
                _getPeriodDisplay(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Period Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButton<String>(
              value: _selectedPeriod,
              underline: const SizedBox(),
              icon: const Icon(Icons.calendar_today),
              items: const [
                DropdownMenuItem(value: 'day', child: Text('Today')),
                DropdownMenuItem(value: 'week', child: Text('This Week')),
                DropdownMenuItem(value: 'month', child: Text('This Month')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPeriod = value;
                    _loadReports();
                  });
                }
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReports,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type Selector
                    Row(
                      children: [
                        _buildTypeButton('Income', 'income'),
                        const SizedBox(width: 16),
                        _buildTypeButton('Expense', 'expense'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Summary Card
                    _buildSummaryCard(),
                    const SizedBox(height: 24),

                    // Category Breakdown
                    _buildCategoryBreakdown(),
                    const SizedBox(height: 24),

                    // Recent Transactions
                    _buildRecentTransactions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTypeButton(String label, String type) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedType = type;
            _loadReports();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.secondaryTextColor,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final summary = _reportData['summary'] ?? {};
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Summary', style: AppTheme.headingStyle),
            const SizedBox(height: 16),
            _buildSummaryItem('Total Amount', summary['total'] ?? 0),
            _buildSummaryItem('Average per Day', summary['daily_average'] ?? 0),
            _buildSummaryItem('Highest Transaction', summary['highest'] ?? 0),
            _buildSummaryItem('Number of Transactions', summary['count'] ?? 0),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, dynamic value) {
    String displayValue;
    if (label == 'Number of Transactions') {
      // Don't format as currency if it's transaction count
      displayValue = value.toString();
    } else if (value is num || value is String) {
      // Convert to double if it's a string number and format as currency
      final numValue = value is String ? double.parse(value) : value as num;
      displayValue = '₱${NumberFormat('#,##0.00').format(numValue)}';
    } else {
      displayValue = value.toString();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.subheadingStyle),
          Text(
            displayValue,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final categories = List<Map<String, dynamic>>.from(
        _reportData['category_breakdown'] ?? []);
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category Breakdown', style: AppTheme.headingStyle),
            const SizedBox(height: 16),
            ...categories.map((category) => _buildCategoryItem(category)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    final amount = double.parse(category['total'].toString());
    final percentage = double.parse(category['percentage'].toString());

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.category),
      title: Text(category['name']),
      subtitle: Text(
        '${percentage.toStringAsFixed(1)}%',
        style: TextStyle(
          color: AppTheme.secondaryTextColor,
          fontSize: 12,
        ),
      ),
      trailing: Text(
        '₱${NumberFormat('#,##0.00').format(amount)}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final transactions = List<Map<String, dynamic>>.from(
        _reportData['recent_transactions'] ?? []);
    if (transactions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Transactions', style: AppTheme.headingStyle),
            const SizedBox(height: 16),
            ...transactions
                .map((transaction) => _buildTransactionItem(transaction)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final date = DateTime.parse(transaction['date']);
    final amount = double.parse(transaction['total'].toString());
    final count = int.parse(transaction['count'].toString());

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.description,
          color: AppTheme.primaryColor,
        ),
      ),
      title: Text(
        DateFormat('MMM d, yyyy').format(date),
        style: const TextStyle(
          color: AppTheme.textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '$count transaction${count > 1 ? 's' : ''}',
        style: const TextStyle(
          color: AppTheme.secondaryTextColor,
        ),
      ),
      trailing: Text(
        '₱${NumberFormat('#,##0.00').format(amount)}',
        style: const TextStyle(
          color: AppTheme.textColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  String _getPeriodDisplay() {
    final period = _reportData['period'] ?? {};
    if (period.isEmpty) return '';

    final startDate = DateTime.parse(period['start_date']);
    final endDate = DateTime.parse(period['end_date']);

    switch (period['type']) {
      case 'day':
        return DateFormat('MMMM d, yyyy').format(startDate);
      case 'week':
        return '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d').format(endDate)}';
      case 'month':
        return DateFormat('MMMM yyyy').format(startDate);
      default:
        return '';
    }
  }
}
