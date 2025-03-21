import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Expense Tracker',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              'Key Features',
              [
                _buildFeatureItem(
                  Icons.account_balance_wallet,
                  'Track Finances',
                  'Record and monitor your income and expenses',
                ),
                _buildFeatureItem(
                  Icons.category,
                  'Categories',
                  'Organize transactions by categories',
                ),
                _buildFeatureItem(
                  Icons.bar_chart,
                  'Reports',
                  'View detailed financial reports and analytics',
                ),
                _buildFeatureItem(
                  Icons.security,
                  'Secure',
                  'Your data is encrypted and secure',
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoCard(
              'Development',
              'Created by Pabellan/Lagnason\n'
                  'BSIT IT2-06\n'
                  'AY 2024-2025',
              Icons.group,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              'Privacy & Security',
              'We take your privacy seriously. Your data is encrypted and never shared with third parties.',
              Icons.security,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryColor),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        description,
        style: const TextStyle(color: AppTheme.secondaryTextColor),
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon) {
    return Card(
      elevation: 0,
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(
                color: AppTheme.secondaryTextColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.headingStyle,
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: AppTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}
