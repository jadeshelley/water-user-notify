import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_management_provider.dart';
import '../models/notification_type.dart';
import '../services/notification_service.dart';
import '../screens/user_directory_screen.dart';

class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterManagementProvider>(
      builder: (context, provider, child) {
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        'Notify All (12h Period Calc)',
                        Icons.notifications,
                        Colors.orange,
                        () => _showNotificationDialog(context, provider, 12),
                        enabled: provider.waterUsers.isNotEmpty,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        'Notify All (24h Period Calc)',
                        Icons.notifications_active,
                        Colors.green,
                        () => _showNotificationDialog(context, provider, 24),
                        enabled: provider.waterUsers.isNotEmpty,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        'Send Rate Change to All',
                        Icons.trending_up,
                        Colors.purple,
                        () => _showRateChangeDialog(context, provider),
                        enabled: provider.waterUsers.isNotEmpty,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        'User Directory',
                        Icons.people,
                        Colors.indigo,
                        () => _showUserDirectory(context),
                        enabled: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (provider.waterUsers.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Add water users to send notifications',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                            ),
                          ),
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

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool enabled = true,
  }) {
    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showNotificationDialog(
    BuildContext context,
    WaterManagementProvider provider,
    int hoursInPeriod,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send ${hoursInPeriod}-Hour Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send to all ${provider.waterUsers.length} water users:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _sendNotifications(context, provider, hoursInPeriod, NotificationType.sms);
                    },
                    icon: const Icon(Icons.sms, size: 20),
                    label: const Text('SMS Only'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _sendNotifications(context, provider, hoursInPeriod, NotificationType.email);
                    },
                    icon: const Icon(Icons.email, size: 20),
                    label: const Text('Email Only'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _sendNotifications(context, provider, hoursInPeriod, NotificationType.both);
                    },
                    icon: const Icon(Icons.notifications, size: 20),
                    label: const Text('SMS & Email'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
        ],
      ),
    );
  }

  void _showRateChangeDialog(BuildContext context, WaterManagementProvider provider) {
    double rate = provider.currentRate;
    NotificationType selectedNotificationType = NotificationType.sms;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Rate Change Notification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send a notification to all ${provider.waterUsers.length} water users regarding a rate change.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Rate',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                controller: TextEditingController(text: rate.toStringAsFixed(1)),
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _sendRateChangeNotification(context, provider, rate, selectedNotificationType);
                  },
                  icon: const Icon(Icons.trending_up, size: 20),
                  label: const Text('Send Rate Change Notification'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _sendNotifications(
    BuildContext context,
    WaterManagementProvider provider,
    int hoursInPeriod,
    NotificationType notificationType,
  ) async {
    try {
      print('Starting notification process for ${provider.waterUsers.length} users');
      
      if (notificationType == NotificationType.rateChange) {
        // Handle rate change notifications
        await NotificationService.notifyRateChangeToAppUsers(
          oldRate: provider.currentRate, // Use current rate as old rate for now
          newRate: provider.currentRate, // Use current rate as new rate for now
          waterUsers: provider.waterUsers,
          notificationType: NotificationType.both, // Always send both SMS and email for rate changes
          context: context,
        );
      } else {
        // Handle regular notifications
        await provider.notifyAllUsers(hoursInPeriod, notificationType: notificationType, context: context);
      }
      
      print('Notification process completed');
      // Note: The notification service will show its own completion message
    } catch (e) {
      print('Error in _sendNotifications: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sendRateChangeNotification(
    BuildContext context,
    WaterManagementProvider provider,
    double rate,
    NotificationType notificationType,
  ) async {
    try {
      print('Starting rate change notification process for ${provider.waterUsers.length} users');
      print('Rate: $rate, Notification Type: $notificationType');
      
      await NotificationService.notifyRateChangeToAppUsers(
        oldRate: provider.currentRate, // Use current rate as old rate
        newRate: rate, // Use the new rate entered by user
        waterUsers: provider.waterUsers,
        notificationType: notificationType,
        context: context,
      );
      
      print('Rate change notification process completed');
    } catch (e) {
      print('Error in _sendRateChangeNotification: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending rate change notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUserDirectory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UserDirectoryScreen(),
      ),
    );
  }
} 