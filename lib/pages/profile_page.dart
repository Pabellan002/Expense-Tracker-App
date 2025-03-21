import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'login_page.dart';
import 'edit_profile_page.dart';
import 'change_password_page.dart';
import '../theme/app_theme.dart';
import 'help_support_page.dart';
import 'about_page.dart';
import 'notifications_page.dart';
import '../config/api_config.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // If not logged in, show login page
        if (!userProvider.isLoggedIn) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_circle,
                    size: 100,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome to Expense Tracker!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please sign in to continue',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                      if (result != null) {
                        userProvider.setUser(result);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final userData = userProvider.userData!;

        // Show profile page for logged in user
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Profile'),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        backgroundImage: userProvider.profileImageUrl != null
                            ? NetworkImage('${ApiConfig.baseUrl}/${userProvider.profileImageUrl}')
                            : null,
                        onBackgroundImageError: userProvider.profileImageUrl != null
                            ? (exception, stackTrace) {
                                print('Error loading profile image: $exception');
                                print('Image URL that failed: ${ApiConfig.baseUrl}/${userProvider.profileImageUrl}');
                              }
                            : null,
                        child: userProvider.profileImageUrl == null
                            ? Icon(
                                Icons.person,
                                size: 50,
                                color: AppTheme.primaryColor,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${userData['first_name']} ${userData['last_name']}',
                        style: AppTheme.headingStyle,
                      ),
                      Text(
                        userData['username'],
                        style: AppTheme.subheadingStyle,
                      ),
                    ],
                  ),
                ),

                // Menu Items
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildMenuSection(
                        'Account',
                        [
                          _buildMenuItem(
                            'Edit Profile',
                            Icons.person_outline,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const EditProfilePage()),
                            ),
                          ),
                          _buildMenuItem(
                            'Change Password',
                            Icons.lock_outline,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ChangePasswordPage()),
                            ),
                          ),
                          _buildMenuItem(
                            'Notifications',
                            Icons.notifications_outlined,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const NotificationsPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildMenuSection(
                        'Other',
                        [
                          _buildMenuItem(
                            'Help & Support',
                            Icons.help_outline,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HelpSupportPage(),
                                ),
                              );
                            },
                          ),
                          _buildMenuItem(
                            'About App',
                            Icons.info_outline,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AboutPage(),
                                ),
                              );
                            },
                          ),
                          _buildMenuItem(
                            'Logout',
                            Icons.logout,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Logout'),
                                  content: const Text(
                                    'Are you sure you want to logout?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () {
                                        userProvider.clearUser();
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Logout'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            isDestructive: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    String title,
    IconData icon, {
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : AppTheme.primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
