import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.help_outline,
                  size: 40,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Help Section
            _buildSection(
              'Quick Help',
              [
                _buildQuickHelpItem(
                  Icons.add_circle_outline,
                  'Add Transaction',
                  'Record your income or expenses',
                ),
                _buildQuickHelpItem(
                  Icons.edit,
                  'Edit Transaction',
                  'Modify or delete existing records',
                ),
                _buildQuickHelpItem(
                  Icons.bar_chart,
                  'View Reports',
                  'See your financial summary',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // FAQs Section
            Text('Frequently Asked Questions', style: AppTheme.headingStyle),
            const SizedBox(height: 16),
            _buildFAQItem(
              'How do I add a transaction?',
              'Tap the + button at the bottom of the screen. Choose between income or expense, then fill in the required details like amount, category, and date.',
            ),
            _buildFAQItem(
              'How do I edit a transaction?',
              'Go to Records page, find the transaction you want to edit, tap on it to view details, then use the edit or delete options.',
            ),
            _buildFAQItem(
              'How do I view my reports?',
              'Navigate to the Reports tab to see your financial summary, category breakdown, and transaction history. You can filter by day, week, or month.',
            ),
            _buildFAQItem(
              'How do I change my password?',
              'Go to Profile > Security > Change Password. Enter your current password and your new password to update it.',
            ),
            const SizedBox(height: 24),

            // Contact Support Section
            Text('Need More Help?', style: AppTheme.headingStyle),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: AppTheme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildContactItem(
                      Icons.email_outlined,
                      'Email Support',
                      'support@expensetracker.com',
                    ),
                    const Divider(color: AppTheme.dividerColor),
                    _buildContactItem(
                      Icons.phone_outlined,
                      'Phone Support',
                      '+63 912 345 6789',
                    ),
                    const Divider(color: AppTheme.dividerColor),
                    _buildContactItem(
                      Icons.chat_outlined,
                      'Live Chat',
                      'Available 24/7',
                    ),
                  ],
                ),
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
        ...children,
      ],
    );
  }

  Widget _buildQuickHelpItem(IconData icon, String title, String subtitle) {
    return Card(
      elevation: 0,
      color: AppTheme.cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
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
          subtitle,
          style: const TextStyle(color: AppTheme.secondaryTextColor),
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      elevation: 0,
      color: AppTheme.cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: const TextStyle(
                color: AppTheme.secondaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String title, String value) {
    return Card(
      elevation: 0,
      color: AppTheme.cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(
          title,
          style: const TextStyle(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            color: AppTheme.secondaryTextColor,
          ),
        ),
      ),
    );
  }
}
