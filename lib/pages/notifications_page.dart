import 'package:flutter/material.dart';
import '../services/notification_service.dart';


class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _lowBalanceEnabled = true;
  bool _monthlyReportEnabled = true;
  double _lowBalanceThreshold = 1000.0;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    // Load preferences from shared preferences
    // This would typically be implemented in the NotificationService
    setState(() {
      // Default values for now
      _lowBalanceEnabled = true;
      _monthlyReportEnabled = true;
      _lowBalanceThreshold = 1000.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Low Balance Alert
          Card(
            elevation: 0,
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
                    'Low Balance Alert',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Get notified when your balance falls below a certain threshold.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Low Balance Alerts'),
                    value: _lowBalanceEnabled,
                    onChanged: (value) {
                      setState(() {
                        _lowBalanceEnabled = value;
                      });
                      NotificationService.setLowBalanceAlert(value);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_lowBalanceEnabled) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Threshold: ₱'),
                        Expanded(
                          child: Slider(
                            value: _lowBalanceThreshold,
                            min: 100,
                            max: 5000,
                            divisions: 49,
                            label: '₱${_lowBalanceThreshold.toStringAsFixed(0)}',
                            onChanged: (value) {
                              setState(() {
                                _lowBalanceThreshold = value;
                              });
                            },
                            onChangeEnd: (value) {
                              NotificationService.setLowBalanceThreshold(value);
                            },
                          ),
                        ),
                        Text(
                          '₱${_lowBalanceThreshold.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Monthly Report
          Card(
            elevation: 0,
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
                    'Monthly Report',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Receive a monthly summary of your income and expenses.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Monthly Reports'),
                    value: _monthlyReportEnabled,
                    onChanged: (value) {
                      setState(() {
                        _monthlyReportEnabled = value;
                      });
                      NotificationService.setMonthlyReportAlert(value);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Test Notifications
          ElevatedButton(
            onPressed: () {
              NotificationService.showNotification(
                title: 'Test Notification',
                body: 'This is a test notification from your expense tracker app.',
                type: NotificationType.lowBalance,
              );
            },
            child: const Text('Send Test Notification'),
          ),
        ],
      ),
    );
  }
}
