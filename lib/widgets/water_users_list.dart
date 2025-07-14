import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_management_provider.dart';
import '../models/water_user.dart';
import '../models/notification_type.dart';
import '../screens/user_detail_screen.dart';

class WaterUsersList extends StatelessWidget {
  const WaterUsersList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterManagementProvider>(
      builder: (context, provider, child) {
        if (provider.waterUsers.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.waterUsers.length,
          itemBuilder: (context, index) {
            final user = provider.waterUsers[index];
            return _buildUserCard(context, provider, user);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 1,
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Water Users',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add water users to start managing irrigation notifications',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    WaterManagementProvider provider,
    WaterUser user,
  ) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Water Shares: ${user.sharesOfWater.toStringAsFixed(2)}'),
        trailing: IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () => _showNotificationOptions(context, provider, user),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => UserDetailScreen(user: user),
            ),
          );
        },
      ),
    );
  }

  void _showNotificationOptions(
    BuildContext context,
    WaterManagementProvider provider,
    WaterUser user,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Send Notification to ${user.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // 12 Hour Options
            Text(
              '12 Hour Period',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await provider.notifyUser(user, 12, notificationType: NotificationType.sms, context: context);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('SMS sent to ${user.name} (12 hours)'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.sms),
                    label: const Text('SMS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await provider.notifyUser(user, 12, notificationType: NotificationType.email, context: context);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Email sent to ${user.name} (12 hours)'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.email),
                    label: const Text('Email'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await provider.notifyUser(user, 12, notificationType: NotificationType.both, context: context);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('SMS & Email sent to ${user.name} (12 hours)'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.notifications),
                    label: const Text('Both'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 24 Hour Options
            Text(
              '24 Hour Period',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await provider.notifyUser(user, 24, notificationType: NotificationType.sms, context: context);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('SMS sent to ${user.name} (24 hours)'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.sms),
                    label: const Text('SMS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await provider.notifyUser(user, 24, notificationType: NotificationType.email, context: context);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Email sent to ${user.name} (24 hours)'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.email),
                    label: const Text('Email'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await provider.notifyUser(user, 24, notificationType: NotificationType.both, context: context);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('SMS & Email sent to ${user.name} (24 hours)'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.notifications),
                    label: const Text('Both'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Rate Change Options
            Text(
              'Rate Change Notification',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      _showRateChangeDialog(context, provider, user);
                    },
                    icon: const Icon(Icons.trending_up),
                    label: const Text('Rate Change'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRateChangeDialog(
    BuildContext context,
    WaterManagementProvider provider,
    WaterUser user,
  ) {
    double rate = provider.currentRate;
    NotificationType selectedNotificationType = NotificationType.sms;
    final rateController = TextEditingController(text: rate.toStringAsFixed(1));
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Send Rate Change to ${user.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: rateController,
                decoration: const InputDecoration(
                  labelText: 'Rate',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  rate = double.tryParse(value) ?? rate;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Select notification method:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          selectedNotificationType = NotificationType.sms;
                        });
                      },
                      icon: const Icon(Icons.sms, size: 20),
                      label: const Text('SMS Only'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedNotificationType == NotificationType.sms 
                            ? Colors.blue 
                            : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          selectedNotificationType = NotificationType.email;
                        });
                      },
                      icon: const Icon(Icons.email, size: 20),
                      label: const Text('Email Only'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedNotificationType == NotificationType.email 
                            ? Colors.orange 
                            : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          selectedNotificationType = NotificationType.both;
                        });
                      },
                      icon: const Icon(Icons.notifications, size: 20),
                      label: const Text('SMS & Email'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedNotificationType == NotificationType.both 
                            ? Colors.green 
                            : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newRate = double.tryParse(rateController.text);
                if (newRate != null && newRate > 0) {
                  Navigator.of(context).pop();
                  _sendRateChangeToUser(context, provider, user, newRate, selectedNotificationType);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid rate.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  void _sendRateChangeToUser(
    BuildContext context,
    WaterManagementProvider provider,
    WaterUser user,
    double newRate,
    NotificationType notificationType,
  ) async {
    try {
      // Create a single-user list for the rate change notification
      final userData = [{
        'userName': user.name,
        'phoneNumber': user.phoneNumber,
        'email': user.email,
      }];
      
      // Use the existing rate change notification service
      await provider.notifyRateChange(
        oldRate: provider.currentRate,
        newRate: newRate,
        userData: userData,
        notificationType: notificationType,
        context: context,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rate change notification sent to ${user.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending rate change notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


} 