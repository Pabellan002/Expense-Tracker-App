import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../config/api_config.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _categoryData = [];
  String _selectedType = 'expense';
  String _selectedPeriod = 'month';
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    setState(() => _isLoading = true);

    try {
      final userData =
          Provider.of<UserProvider>(context, listen: false).userData;
      if (userData == null) return;

      final response = await http.get(
        Uri.parse(ApiConfig.transactionEndpoint).replace(
          queryParameters: {
            'operation': 'getCategoryStats',
            'json': jsonEncode({
              'user_id': userData['user_id'],
              'type': _selectedType,
              'period': _selectedPeriod,
            }),
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _categoryData = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      print('Error loading chart data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double get _total => _categoryData.fold(
        0,
        (sum, item) => sum + (double.tryParse(item['total'].toString()) ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Budget',
                style: AppTheme.headingStyle.copyWith(fontSize: 25),
              ),
              const SizedBox(height: 24),

              // Type and Period Selector
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'expense', child: Text('Expense')),
                        DropdownMenuItem(
                            value: 'income', child: Text('Income')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedType = value);
                          _loadChartData();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPeriod,
                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'month', child: Text('This Month')),
                        DropdownMenuItem(
                            value: 'year', child: Text('This Year')),
                        DropdownMenuItem(value: 'all', child: Text('All Time')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedPeriod = value);
                          _loadChartData();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_categoryData.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(color: AppTheme.secondaryTextColor),
                    ),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Pie Chart
                        AspectRatio(
                          aspectRatio: 1.3,
                          child: PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback:
                                    (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection ==
                                            null) {
                                      _touchedIndex = -1;
                                      return;
                                    }
                                    _touchedIndex = pieTouchResponse
                                        .touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              sections:
                                  _categoryData.asMap().entries.map((entry) {
                                final index = entry.key;
                                final data = entry.value;
                                final amount =
                                    double.tryParse(data['total'].toString()) ??
                                        0;
                                final percentage = amount / _total * 100;
                                final isTouched = index == _touchedIndex;
                                final radius = isTouched ? 110.0 : 100.0;

                                return PieChartSectionData(
                                  color:
                                      _getCategoryColor(data['category_name']),
                                  value: amount,
                                  title: '${percentage.toStringAsFixed(1)}%',
                                  radius: radius,
                                  titleStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              }).toList(),
                              sectionsSpace: 2,
                              centerSpaceRadius: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Category List
                        ...List.generate(_categoryData.length, (index) {
                          final data = _categoryData[index];
                          final amount =
                              double.tryParse(data['total'].toString()) ?? 0;
                          final percentage = amount / _total * 100;
                          final color =
                              _getCategoryColor(data['category_name']);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: color.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(data['category_name']),
                                    color: color,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['category_name'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            '${percentage.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              color: color,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            ' of total ${_selectedType}s',
                                            style: TextStyle(
                                              color:
                                                  AppTheme.secondaryTextColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  NumberFormat.currency(
                                    locale: 'en_PH',
                                    symbol: '₱',
                                  ).format(amount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    if (category == null) return Colors.grey;

    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transportation':
        return Colors.blue;
      case 'entertainment':
        return Colors.purple;
      case 'bills':
        return Colors.red;
      case 'salary':
        return Colors.green;
      case 'business':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String? category) {
    if (category == null) return Icons.category;

    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transportation':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'bills':
        return Icons.receipt;
      case 'salary':
        return Icons.work;
      case 'business':
        return Icons.business;
      default:
        return Icons.category;
    }
  }
}
