import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/notification_type.dart';
import '../main.dart'; // Import for navigatorKey
import 'dart:async'; // Added for Completer
import '../models/water_user.dart'; // Added for WaterUser model
import 'package:intl/intl.dart'; // Added for date formatting
import 'package:share_plus/share_plus.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(initSettings);
  }

  static Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'water_management',
      'Water Management',
      channelDescription: 'Notifications for water management app',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  static Future<void> sendSMS({
    required String phoneNumber,
    required String message,
  }) async {
    print('sendSMS called with phoneNumber: $phoneNumber');
    print('sendSMS message: $message');
    
    // Check if this is a group contact (starts with group:)
    if (phoneNumber.startsWith('group:')) {
      final groupName = phoneNumber.substring(6); // Remove 'group:' prefix
      print('Sending SMS to group: $groupName');
      
      // Try to use the contacts app to send to the group
      await _sendSMSViaContactsApp(groupName, message);
    } else {
      // Regular phone number handling
      final encodedMessage = Uri.encodeComponent(message);
      print('sendSMS encoded message: $encodedMessage');
      
      final Uri smsUri = Uri.parse('sms:$phoneNumber?body=$encodedMessage');
      print('sendSMS URI: $smsUri');

      print('Checking if canLaunchUrl for SMS...');
      if (await canLaunchUrl(smsUri)) {
        print('canLaunchUrl returned true, launching SMS app...');
        await launchUrl(smsUri);
        print('launchUrl completed for SMS');
      } else {
        print('canLaunchUrl returned false for SMS');
        throw Exception('Could not launch SMS app');
      }
    }
  }

  static Future<void> _sendSMSViaContactsApp(String groupName, String message) async {
    print('Attempting to send SMS via contacts app for group: $groupName');
    
    try {
      // First, try to get the actual group members and send to them individually
      final groupMembers = await _getGroupMembers(groupName);
      if (groupMembers.isNotEmpty) {
        print('Found ${groupMembers.length} group members, sending individual SMS');
        await _sendSMSToGroupMembers(groupMembers, message);
        return;
      }
      
      // If we can't get group members, try to open the contacts app
      
      // Approach 1: Try to open contacts app and search for the group
      final contactsUri = Uri.parse('content://contacts/groups');
      if (await canLaunchUrl(contactsUri)) {
        await launchUrl(contactsUri);
        print('Opened contacts app - user should search for group: $groupName');
        return;
      }
      
      // Approach 2: Try to open the default SMS app with a search query
      final encodedMessage = Uri.encodeComponent(message);
      final encodedGroupName = Uri.encodeComponent(groupName);
      final smsUri = Uri.parse('sms:?body=$encodedMessage&query=$encodedGroupName');
      
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        print('Opened SMS app with group search - user should select group: $groupName');
        return;
      }
      
      // Approach 3: Try to open contacts app directly
      final contactsAppUri = Uri.parse('content://com.android.contacts/contacts');
      if (await canLaunchUrl(contactsAppUri)) {
        await launchUrl(contactsAppUri);
        print('Opened contacts app - user should navigate to groups and find: $groupName');
        return;
      }
      
      // Fallback: Open SMS app and let user manually select group
      final fallbackSmsUri = Uri.parse('sms:?body=${Uri.encodeComponent(message)}');
      await launchUrl(fallbackSmsUri);
      print('Opened SMS app - user should manually select group: $groupName');
      
    } catch (e) {
      print('Failed to open contacts/SMS app for group: $e');
      throw Exception('Could not open contacts app for group messaging');
    }
  }

  static Future<List<Contact>> _getGroupMembers(String groupName) async {
    try {
      print('_getGroupMembers called with groupName: "$groupName"');
      
      // Get all contacts with group information
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
        withGroups: true,
      );
      
      print('Total contacts loaded: ${contacts.length}');
      
      // First, let's see what groups are available
      final groups = await FlutterContacts.getGroups();
      print('Available groups:');
      for (final group in groups) {
        print('  - "${group.name}" (ID: ${group.id})');
      }
      
      // Find contacts that belong to the specified group
      final groupMembers = contacts.where((contact) {
        final hasGroup = contact.groups.any((group) {
          final groupMatches = group.name.toLowerCase().contains(groupName.toLowerCase()) ||
                              groupName.toLowerCase().contains(group.name.toLowerCase());
          if (groupMatches) {
            print('Found contact "${contact.displayName}" in group "${group.name}"');
          }
          return groupMatches;
        });
        return hasGroup;
      }).toList();
      
      print('Found ${groupMembers.length} members in group: $groupName');
      
      // If no members found, try a broader search
      if (groupMembers.isEmpty) {
        print('No members found with exact group name, trying broader search...');
        
        // Try searching for contacts with "twincreek" in their name or groups
        final broaderSearch = contacts.where((contact) {
          final nameContainsTwincreek = contact.displayName.toLowerCase().contains('twincreek');
          final inTwincreekGroup = contact.groups.any((group) => 
            group.name.toLowerCase().contains('twincreek'));
          
          if (nameContainsTwincreek || inTwincreekGroup) {
            print('Found potential twincreek contact: "${contact.displayName}"');
            print('  - Name contains twincreek: $nameContainsTwincreek');
            print('  - In twincreek group: $inTwincreekGroup');
            print('  - Groups: ${contact.groups.map((g) => g.name).join(', ')}');
          }
          
          return nameContainsTwincreek || inTwincreekGroup;
        }).toList();
        
        print('Broader search found ${broaderSearch.length} potential twincreek contacts');
        return broaderSearch;
      }
      
      return groupMembers;
    } catch (e) {
      print('Error getting group members: $e');
      return [];
    }
  }

  static Future<void> _sendSMSToGroupMembers(List<Contact> groupMembers, String message) async {
    print('_sendSMSToGroupMembers called with ${groupMembers.length} members');
    print('Message: $message');
    
    // Collect all phone numbers from group members
    final phoneNumbers = <String>[];
    final contactsWithPhones = <Contact>[];
    
    for (int i = 0; i < groupMembers.length; i++) {
      final contact = groupMembers[i];
      final phoneNumber = contact.phones.isNotEmpty ? contact.phones.first.number : null;
      
      print('Processing member ${i + 1}/${groupMembers.length}: ${contact.displayName}');
      print('  - Phone numbers: ${contact.phones.map((p) => p.number).join(', ')}');
      print('  - Emails: ${contact.emails.map((e) => e.address).join(', ')}');
      print('  - Groups: ${contact.groups.map((g) => g.name).join(', ')}');
      
      if (phoneNumber != null) {
        phoneNumbers.add(phoneNumber);
        contactsWithPhones.add(contact);
        print('  - Added phone number: $phoneNumber');
      } else {
        print('  - No phone number found for ${contact.displayName}');
      }
    }
    
    if (phoneNumbers.isEmpty) {
      print('No phone numbers found in group members');
      _showNoPhoneNumbersDialog();
      return;
    }
    
    print('Found ${phoneNumbers.length} phone numbers: ${phoneNumbers.join(', ')}');
    
    // Try to send as a group SMS with all numbers
    await _sendGroupSMS(phoneNumbers, message, contactsWithPhones.map((c) => c.displayName).toList());
  }
  
  static Future<void> _sendGroupSMS(List<String> phoneNumbers, String message, List<String> userNames) async {
    print('_sendGroupSMS called with ${phoneNumbers.length} phone numbers');
    
    // Try different approaches for group SMS
    
    // Approach 1: Try to send to all numbers at once (some SMS apps support this)
    final allNumbers = phoneNumbers.join(',');
    final encodedMessage = Uri.encodeComponent(message);
    final smsUri = Uri.parse('sms:$allNumbers?body=$encodedMessage');
    
    print('Attempting group SMS with URI: $smsUri');
    
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        print('Group SMS launched successfully');
        return;
      }
    } catch (e) {
      print('Failed to launch group SMS: $e');
    }
    
    // Approach 2: If group SMS fails, show instructions to user
    _showGroupSMSInstructions(phoneNumbers, message, userNames);
  }
  
  static void _showGroupSMSInstructions(List<String> phoneNumbers, String message, List<String> userNames) {
    final phoneList = phoneNumbers.join('\n• ');
    final nameList = userNames.join('\n• ');
    
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('Group SMS Instructions'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your SMS app will open. Please follow these steps:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('1. Tap the recipient field'),
              const Text('2. Add the following phone numbers:'),
              const SizedBox(height: 8),
              Text('• $phoneList'),
              const SizedBox(height: 16),
              const Text(
                'Recipients:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('• $nameList'),
              const SizedBox(height: 16),
              const Text(
                'Message:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(message),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Open SMS app with empty message for user to add recipients
              final smsUri = Uri.parse('sms:?body=${Uri.encodeComponent(message)}');
              launchUrl(smsUri);
            },
            child: const Text('Open SMS App'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  static void _showNoPhoneNumbersDialog() {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('No Phone Numbers Found'),
        content: const Text(
          'None of the group members have phone numbers in your contacts. '
          'Please add phone numbers to the group members or try sending via email instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Future<void> sendEmail({
    required String email,
    required String subject,
    required String message,
  }) async {
    print('sendEmail called with email: $email');
    print('sendEmail subject: $subject');
    print('sendEmail message: $message');
    
    // Check if this is a group contact
    if (email.startsWith('group:')) {
      final groupName = email.substring(6);
      print('Sending email to group: $groupName');
      await _sendEmailViaContactsApp(groupName, subject, message);
    } else {
      // Regular email handling
      final encodedSubject = Uri.encodeComponent(subject);
      final encodedMessage = Uri.encodeComponent(message);
      
      // Create mailto URI
      final mailtoUri = Uri.parse('mailto:$email?subject=$encodedSubject&body=$encodedMessage');
      
      print('Attempting to launch email URI: $mailtoUri');
      
      try {
        // Try to launch directly first
        await launchUrl(mailtoUri);
        print('Email app launched successfully');
        return;
      } catch (e) {
        print('Direct email launch failed: $e');
      }
      
      // If direct launch fails, try with canLaunchUrl check
      try {
        if (await canLaunchUrl(mailtoUri)) {
          await launchUrl(mailtoUri);
          print('Email app launched successfully with canLaunchUrl check');
          return;
        } else {
          print('canLaunchUrl returned false for email URI');
        }
      } catch (e) {
        print('canLaunchUrl check failed: $e');
      }
      
      // If all attempts fail, show error
      print('All email launch attempts failed');
      throw Exception('Could not launch email app. Please check if you have an email app installed.');
    }
  }

  static Future<void> _sendEmailViaContactsApp(String groupName, String subject, String message) async {
    print('Attempting to send email via contacts app for group: $groupName');
    
    try {
      // First, try to get the actual group members and send to them individually
      final groupMembers = await _getGroupMembers(groupName);
      if (groupMembers.isNotEmpty) {
        print('Found ${groupMembers.length} group members, sending individual emails');
        await _sendEmailToGroupMembers(groupMembers, subject, message);
        return;
      }
      
      // If we can't get group members, try to open the default email app
      final encodedSubject = Uri.encodeComponent(subject);
      final encodedMessage = Uri.encodeComponent(message);
      final mailtoUri = Uri.parse('mailto:?subject=$encodedSubject&body=$encodedMessage');
      
      if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri);
        print('Opened email app - user should select group: $groupName');
        return;
      }
      
      // Fallback: Show message content for manual copying
      throw Exception('Could not open email app - please manually select the group contact');
      
    } catch (e) {
      print('Failed to open email app for group: $e');
      throw Exception('Could not open email app for group messaging');
    }
  }

  static Future<void> _sendEmailToGroupMembers(List<Contact> groupMembers, String subject, String message) async {
    print('Sending email to ${groupMembers.length} group members individually');
    
    for (int i = 0; i < groupMembers.length; i++) {
      final contact = groupMembers[i];
      final email = contact.emails.isNotEmpty ? contact.emails.first.address : null;
      
      if (email != null) {
        print('Sending email to ${contact.displayName} at $email');
        try {
          await sendEmail(email: email, subject: subject, message: message);
          print('Email sent successfully to ${contact.displayName}');
        } catch (e) {
          print('Failed to send email to ${contact.displayName}: $e');
        }
      } else {
        print('No email found for ${contact.displayName}');
      }
    }
  }

  static Future<void> notifyWaterUser({
    required String userName,
    required double sprinklerHeads,
    required double currentRate,
    required double userShares,
    required int hoursInPeriod,
    String? phoneNumber,
    String? email,
    NotificationType notificationType = NotificationType.both,
    required BuildContext context,
    bool showConfirmation = true,
  }) async {
    final dateStr = DateFormat('MM/dd/yy').format(DateTime.now());
    final message = '''
Water Usage Notification
$dateStr
$userName
${userShares.toStringAsFixed(2)} Shares

Current rate setting is now ${currentRate.toInt()}. At the current rate setting of ${currentRate.toInt()}, you can use ${sprinklerHeads.round()} sprinkler heads in a ${hoursInPeriod} hour period.
''';
    final emailSubject = 'Water Usage Notification - $userName - $dateStr';

    // Show local notification
    await showLocalNotification(
      title: 'Water Usage Update',
      body: 'New calculation available for $userName',
    );

    // Send SMS based on notification type
    if ((notificationType == NotificationType.sms || notificationType == NotificationType.both) &&
        phoneNumber != null && phoneNumber.isNotEmpty) {
      try {
        print('Attempting to send SMS to: $phoneNumber');
        if (showConfirmation) {
          await _showSMSConfirmation(context, phoneNumber, message);
        } else {
          await sendSMS(phoneNumber: phoneNumber, message: message);
        }
        print('SMS sent successfully');
      } catch (e) {
        print('Failed to send SMS: $e');
      }
    } else if (notificationType == NotificationType.sms) {
      print('No phone number available for SMS');
    }

    // Send email based on notification type
    if ((notificationType == NotificationType.email || notificationType == NotificationType.both) &&
        email != null && email.isNotEmpty) {
      try {
        print('Attempting to send email to: $email');
        if (showConfirmation) {
          await _showEmailConfirmation(context, email, userName, message);
        } else {
          await sendEmail(
            email: email,
            subject: emailSubject,
            message: message,
          );
        }
        print('Email sent successfully');
      } catch (e) {
        print('Failed to send email: $e');
      }
    } else if (notificationType == NotificationType.email) {
      print('No email available for email notification');
    }
  }

  static Future<void> _showSMSConfirmation(
    BuildContext context,
    String phoneNumber,
    String message,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send SMS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To: $phoneNumber'),
            const SizedBox(height: 16),
            const Text('Message:'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                message,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'The SMS app will open with this message. You will need to manually send it.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await sendSMS(phoneNumber: phoneNumber, message: message);
            },
            child: const Text('Open SMS App'),
          ),
        ],
      ),
    );
  }

  static Future<void> _showEmailConfirmation(
    BuildContext context,
    String email,
    String userName,
    String message,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To: $email'),
            const SizedBox(height: 8),
            Text('Subject: Water Usage Notification - $userName'),
            const SizedBox(height: 16),
            const Text('Message:'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                message,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'The email app will open with this message. You will need to manually send it.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await sendEmail(
                email: email,
                subject: 'Water Usage Notification - $userName',
                message: message,
              );
            },
            child: const Text('Open Email App'),
          ),
        ],
      ),
    );
  }

  static Future<void> notifyAllUsersWithConfirmation({
    required List<Map<String, dynamic>> userData,
    required NotificationType notificationType,
    required BuildContext context,
  }) async {
    print('notifyAllUsersWithConfirmation called with ${userData.length} users');
    print('Notification type: $notificationType');
    
    // Create a summary of what will be sent
    String summary = '';
    int smsCount = 0;
    int emailCount = 0;
    
    for (final data in userData) {
      final userName = data['userName'] as String;
      final phoneNumber = data['phoneNumber'] as String?;
      final email = data['email'] as String?;
      
      if ((notificationType == NotificationType.sms || notificationType == NotificationType.both) && 
          phoneNumber != null && phoneNumber.isNotEmpty) {
        smsCount++;
        summary += 'SMS to $userName ($phoneNumber)\n';
      }
      
      if ((notificationType == NotificationType.email || notificationType == NotificationType.both) && 
          email != null && email.isNotEmpty) {
        emailCount++;
        summary += 'Email to $userName ($email)\n';
      }
    }
    
    // Show confirmation dialog
    bool confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send ${notificationType.name.toUpperCase()} to All Users'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will send notifications to ${userData.length} users:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                summary.trim(),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Total: ${smsCount > 0 ? '$smsCount SMS' : ''}${smsCount > 0 && emailCount > 0 ? ' and ' : ''}${emailCount > 0 ? '$emailCount Email' : ''}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How it works:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• The app will open each notification one by one\n'
                    '• Send each message in the SMS/Email app\n'
                    '• Return to this app and tap "Continue to Next"\n'
                    '• Repeat until all notifications are sent',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Start Sending'),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirmed) {
      print('User confirmed, starting sequential notifications');
      // Send notifications one by one
      await _sendNotificationsSequentially(userData, notificationType, context);
    } else {
      print('User cancelled the notification process');
    }
  }

  static Future<void> _sendNotificationsSequentially(
    List<Map<String, dynamic>> userData,
    NotificationType notificationType,
    BuildContext context,
  ) async {
    print('_sendNotificationsSequentially started with ${userData.length} users');
    int currentIndex = 0;
    int totalNotifications = 0;
    
    // Count total notifications
    for (final data in userData) {
      final phoneNumber = data['phoneNumber'] as String?;
      final email = data['email'] as String?;
      final userName = data['userName'] as String;
      
      print('Checking user: $userName, phone: $phoneNumber, email: $email');
      
      if ((notificationType == NotificationType.sms || notificationType == NotificationType.both) && 
          phoneNumber != null && phoneNumber.isNotEmpty) {
        totalNotifications++;
        print('Will send SMS to $userName');
      }
      
      if ((notificationType == NotificationType.email || notificationType == NotificationType.both) && 
          email != null && email.isNotEmpty) {
        totalNotifications++;
        print('Will send Email to $userName');
      }
    }
    
    print('Total notifications to send: $totalNotifications');
    
    // Send notifications one by one
    print('Starting to process ${userData.length} users for notifications');
    for (final data in userData) {
      final userName = data['userName'] as String;
      print('Processing user: $userName');
      final sprinklerHeads = data['sprinklerHeads'] as double;
      final currentRate = data['currentRate'] as double;
      final userShares = data['userShares'] as double;
      final hoursInPeriod = data['hoursInPeriod'] as int;
      final phoneNumber = data['phoneNumber'] as String?;
      final email = data['email'] as String?;
      
      final dateStr = DateFormat('MM/dd/yy').format(DateTime.now());
      final message = '''
Water Usage Notification
$dateStr
$userName
${userShares.toStringAsFixed(2)} Shares

Current rate setting is now ${currentRate.toInt()}. At the current rate setting of ${currentRate.toInt()}, you can use ${sprinklerHeads.round()} sprinkler heads in a ${hoursInPeriod} hour period.
''';
      final emailSubject = 'Water Usage Notification - $userName - $dateStr';

      print('Processing user: $userName');

      // Send SMS if requested
      if ((notificationType == NotificationType.sms || notificationType == NotificationType.both) && 
          phoneNumber != null && phoneNumber.isNotEmpty) {
        currentIndex++;
        print('Sending SMS ${currentIndex} of $totalNotifications to $userName');
        

        
        // Show progress dialog and open SMS app
        print('About to show SMS progress dialog for $userName');
        bool shouldContinue = await _showSMSProgressDialog(
          context, 
          currentIndex, 
          totalNotifications, 
          userName, 
          phoneNumber,
          message,
        );
        
        print('SMS progress dialog result: $shouldContinue');
        
        if (shouldContinue) {
          // Show continue dialog after SMS app opens
          if (currentIndex < totalNotifications) {
            print('Showing continue dialog for next notification');
            bool continueToNext = await _showContinueDialog(context, userName, 'SMS', totalNotifications - currentIndex);
            print('Continue dialog result: $continueToNext');
            if (!continueToNext) {
              print('User cancelled at continue dialog');
              break;
            } else {
              print('User chose to continue, moving to next notification');
            }
          } else {
            print('No more notifications to send');
          }
        } else {
          print('User cancelled SMS to $userName');
          break; // User cancelled
        }
      }
      
      // Send email if requested
      if ((notificationType == NotificationType.email || notificationType == NotificationType.both) && 
          email != null && email.isNotEmpty) {
        currentIndex++;
        print('Sending Email ${currentIndex} of $totalNotifications to $userName');
        

        
        // Show progress dialog and open email app
        bool shouldContinue = await _showEmailProgressDialog(
          context, 
          currentIndex, 
          totalNotifications, 
          userName, 
          email,
          message,
        );
        
        if (shouldContinue) {
          // Show continue dialog after email app opens
          if (currentIndex < totalNotifications) {
            bool continueToNext = await _showContinueDialog(context, userName, 'Email', totalNotifications - currentIndex);
            if (!continueToNext) break;
          }
        } else {
          print('User cancelled email to $userName');
          break; // User cancelled
        }
      }
      
      print('Finished processing user: $userName');
    }
    
    // Show completion message
    BuildContext? validContext = context.mounted ? context : navigatorKey.currentContext;
    if (validContext != null) {
      ScaffoldMessenger.of(validContext).showSnackBar(
        SnackBar(
          content: Text('Completed sending ${currentIndex} notifications!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      print('No valid context available, cannot show completion message');
    }
  }

  static Future<bool> _showSMSProgressDialog(
    BuildContext context,
    int currentIndex,
    int totalNotifications,
    String userName,
    String phoneNumber,
    String message,
  ) async {
    print('_showSMSProgressDialog called for $userName');
    
    // Get a valid context - use global navigator key if original context is invalid
    BuildContext? validContext = context.mounted ? context : navigatorKey.currentContext;
    
    if (validContext == null) {
      print('No valid context available, opening SMS app directly');
      await sendSMS(phoneNumber: phoneNumber, message: message);
      await Future.delayed(const Duration(milliseconds: 2000));
      return true;
    }
    
    // Show a progress dialog
    showDialog(
      context: validContext,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Sending SMS ${currentIndex} of $totalNotifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Opening SMS app for $userName...'),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
    
    // Wait a moment, then open SMS app
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Close the progress dialog
    if (validContext.mounted) {
      Navigator.of(validContext).pop();
    }
    
    print('Opening SMS app for $userName');
    await sendSMS(phoneNumber: phoneNumber, message: message);
    print('Returned from SMS app for $userName');
    
    // Give user time to see the SMS app before showing continue dialog
    await Future.delayed(const Duration(milliseconds: 2000));
    
    return true;
  }

  static Future<bool> _showEmailProgressDialog(
    BuildContext context,
    int currentIndex,
    int totalNotifications,
    String userName,
    String email,
    String message,
  ) async {
    print('_showEmailProgressDialog called for $userName');
    
    // Get a valid context - use global navigator key if original context is invalid
    BuildContext? validContext = context.mounted ? context : navigatorKey.currentContext;
    
    if (validContext == null) {
      print('No valid context available, opening email app directly');
      await sendEmail(
        email: email,
        subject: 'Water Usage Notification - $userName',
        message: message,
      );
      await Future.delayed(const Duration(milliseconds: 2000));
      return true;
    }
    
    // Show a progress dialog
    showDialog(
      context: validContext,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Sending Email ${currentIndex} of $totalNotifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Opening Email app for $userName...'),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
    
    // Wait a moment, then open email app
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Close the progress dialog
    if (validContext.mounted) {
      Navigator.of(validContext).pop();
    }
    
    print('Opening email app for $userName');
    try {
      await sendEmail(
        email: email,
        subject: 'Water Usage Notification - $userName',
        message: message,
      );
      print('Returned from email app for $userName');
    } catch (e) {
      print('Email failed: $e');
      // Show error dialog with option to copy email content
      if (validContext != null && validContext.mounted) {
        await _showEmailErrorDialog(validContext, email, userName, message);
      }
    }
    
    // Give user time to see the email app before showing continue dialog
    await Future.delayed(const Duration(milliseconds: 2000));
    
    return true;
  }

  static Future<void> _showEmailErrorDialog(
    BuildContext context,
    String email,
    String userName,
    String message,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email App Not Found'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Could not open an email app. You can copy the email content below and send it manually:',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('To: $email'),
                  const SizedBox(height: 8),
                  Text('Subject: Water Usage Notification - $userName'),
                  const SizedBox(height: 8),
                  const Text('Message:'),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              // Copy email content to clipboard
              final emailContent = '''
To: $email
Subject: Water Usage Notification - $userName

$message
''';
              Clipboard.setData(ClipboardData(text: emailContent));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email content copied to clipboard'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Copy to Clipboard'),
          ),
        ],
      ),
    );
  }

  static Future<bool> _showContinueDialog(
    BuildContext context,
    String userName,
    String notificationType,
    int remainingCount,
  ) async {
    print('_showContinueDialog called for $userName, $notificationType, $remainingCount remaining');
    
    // Get a valid context - use global navigator key if original context is invalid
    BuildContext? validContext = context.mounted ? context : navigatorKey.currentContext;
    
    if (validContext == null) {
      print('No valid context available, auto-continuing to next notification');
      return true;
    }
    
    // Show dialog asking user if they want to continue to the next notification
    bool shouldContinue = await showDialog<bool>(
      context: validContext,
      barrierDismissible: false, // User must make a choice
      builder: (dialogContext) => AlertDialog(
        title: const Text('Continue to Next Notification?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You just sent a $notificationType to $userName.'),
              const SizedBox(height: 16),
              Text(
                'There are $remainingCount more notifications to send.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instructions:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Send the message in the $notificationType app\n'
                      '2. Return to this app\n'
                      '3. Tap "Continue to Next" for the next user',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Stop'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Continue to Next'),
          ),
        ],
      ),
    ) ?? false;
    
    print('Continue dialog result: $shouldContinue');
    return shouldContinue;
  }

  static Future<void> notifyRateChange({
    required double oldRate,
    required double newRate,
    required List<Map<String, dynamic>> userData,
    required NotificationType notificationType,
    required BuildContext context,
  }) async {
    print('notifyRateChange called with oldRate: $oldRate, newRate: $newRate');
    print('User data count: ${userData.length}');
    
    final message = '''
Rate Change Notification
${DateFormat('MM/dd/yy').format(DateTime.now())}

The water rate has been updated to:

${newRate.toStringAsFixed(1)}

Please update your sprinkler head usage.''';

    final subject = 'Water Rate Change - ${newRate.toStringAsFixed(1)} - ${DateFormat('MM/dd/yy').format(DateTime.now())}';

    // Show local notification
    await showLocalNotification(
      title: 'Rate Change Notification',
      body: 'Water rate updated to ${newRate.toStringAsFixed(1)}',
    );

    // Process each user
    for (int i = 0; i < userData.length; i++) {
      final data = userData[i];
      final userName = data['userName'] as String;
      final phoneNumber = data['phoneNumber'] as String?;
      final email = data['email'] as String?;

      print('Processing user $i: $userName');

      // Send SMS if requested and available
      if ((notificationType == NotificationType.sms || notificationType == NotificationType.both) &&
          phoneNumber != null && phoneNumber.isNotEmpty) {
        try {
          print('Sending rate change SMS to: $phoneNumber');
          await sendSMS(phoneNumber: phoneNumber, message: message);
          print('Rate change SMS sent successfully to $userName');
        } catch (e) {
          print('Failed to send rate change SMS to $userName: $e');
        }
      }

      // Send email if requested and available
      if ((notificationType == NotificationType.email || notificationType == NotificationType.both) &&
          email != null && email.isNotEmpty) {
        try {
          print('Sending rate change email to: $email');
          await sendEmail(
            email: email,
            subject: subject,
            message: message,
          );
          print('Rate change email sent successfully to $userName');
        } catch (e) {
          print('Failed to send rate change email to $userName: $e');
        }
      }
    }

    // Show completion dialog
    await _showRateChangeCompletionDialog(context, userData.length);
  }

  static Future<void> _showRateChangeCompletionDialog(
    BuildContext context,
    int userCount,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Rate Change Notifications Sent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rate change notifications have been sent to $userCount users.'),
            const SizedBox(height: 16),
            const Text(
              'All users have been notified about the rate change via their preferred notification method.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static String _generateRateChangeMessage(double oldRate, double newRate) {
    return '''Rate Change Notification\n${DateFormat('MM/dd/yy').format(DateTime.now())}\n\nThe water rate has been updated to:\n\n${newRate.toStringAsFixed(1)}\n\nPlease update your sprinkler head usage.''';
  }

  static Future<void> notifyRateChangeToGroup({
    required double oldRate,
    required double newRate,
    required String groupContactName,
    String? groupPhoneNumber,
    String? groupEmail,
    required NotificationType notificationType,
    required BuildContext context,
  }) async {
    print('notifyRateChangeToGroup called');
    print('groupContactName: $groupContactName');
    print('groupPhoneNumber: $groupPhoneNumber');
    print('groupEmail: $groupEmail');
    print('notificationType: $notificationType');

    final message = _generateRateChangeMessage(oldRate, newRate);
    print('Rate change message: $message');

    try {
      if (notificationType == NotificationType.sms || notificationType == NotificationType.both) {
        if (groupPhoneNumber != null && groupPhoneNumber.isNotEmpty) {
          print('Sending SMS to group...');
          
          // Check if this is a group contact
          if (groupPhoneNumber.startsWith('group:')) {
            final groupName = groupPhoneNumber.substring(6);
            print('This is a group contact: $groupName');
            
            // Show instructions to user before launching SMS app
            final shouldContinue = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Send SMS to Group'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('The SMS app will open. Please:'),
                    const SizedBox(height: 8),
                    Text('1. Select the "$groupName" group contact'),
                    const Text('2. The message will be sent to all group members'),
                    const SizedBox(height: 16),
                    Text('Message: $message'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Continue'),
                  ),
                ],
              ),
            );
            
            if (shouldContinue == true) {
              await sendSMS(phoneNumber: groupPhoneNumber, message: message);
            }
          } else {
            await sendSMS(phoneNumber: groupPhoneNumber, message: message);
          }
        } else {
          print('No group phone number available for SMS');
        }
      }

      if (notificationType == NotificationType.email || notificationType == NotificationType.both) {
        if (groupEmail != null && groupEmail.isNotEmpty) {
          print('Sending email to group...');
          await sendEmail(email: groupEmail, subject: 'Water Rate Change - ${newRate.toStringAsFixed(1)} - ${DateFormat('MM/dd/yy').format(DateTime.now())}', message: message);
        } else {
          print('No group email available');
        }
      }

      print('Group rate change notifications completed successfully');
    } catch (e) {
      print('Error in notifyRateChangeToGroup: $e');
      rethrow;
    }
  }

  static Future<void> _showGroupRateChangeCompletionDialog(
    BuildContext context,
    String groupContactName,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Rate Change Notification Sent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rate change notification has been sent to the group contact: $groupContactName'),
            const SizedBox(height: 16),
            const Text(
              'All water users in this group contact have been notified about the rate change.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Future<void> notifyRateChangeToAppUsers({
    required double oldRate,
    required double newRate,
    required List<WaterUser> waterUsers,
    required NotificationType notificationType,
    required BuildContext context,
  }) async {
    print('notifyRateChangeToAppUsers called');
    print('waterUsers count: ${waterUsers.length}');
    print('notificationType: $notificationType');

    final message = _generateRateChangeMessage(oldRate, newRate);
    print('Rate change message: $message');

    // Filter users who have phone numbers
    final usersWithPhones = waterUsers.where((user) => user.phoneNumber != null && user.phoneNumber!.isNotEmpty).toList();
    final usersWithEmails = waterUsers.where((user) => user.email != null && user.email!.isNotEmpty).toList();
    
    print('Users with phones: ${usersWithPhones.length}');
    print('Users with emails: ${usersWithEmails.length}');

    if (usersWithPhones.isEmpty && usersWithEmails.isEmpty) {
      _showNoContactInfoDialog();
      return;
    }

    try {
      if (notificationType == NotificationType.sms || notificationType == NotificationType.both) {
        if (usersWithPhones.isNotEmpty) {
          print('Sending SMS notifications to ${usersWithPhones.length} users');
          await _sendRateChangeSMSToAppUsers(usersWithPhones, message);
          print('SMS notifications completed');
        } else {
          print('No users with phone numbers found for SMS');
        }
      }

      // Add a small delay between SMS and email to make it more noticeable
      if (notificationType == NotificationType.both) {
        print('Waiting 2 seconds before sending email notifications...');
        await Future.delayed(const Duration(seconds: 2));
      }

      if (notificationType == NotificationType.email || notificationType == NotificationType.both) {
        if (usersWithEmails.isNotEmpty) {
          print('Sending email notifications to ${usersWithEmails.length} users');
          await _sendRateChangeEmailToAppUsers(usersWithEmails, message, newRate);
          print('Email notifications completed');
        } else {
          print('No users with email addresses found for email');
        }
      }

      _showRateChangeSuccessDialog(usersWithPhones.length, usersWithEmails.length, notificationType);
    } catch (e) {
      print('Error sending rate change notifications: $e');
      _showRateChangeErrorDialog(e.toString());
    }
  }

  static Future<void> _sendRateChangeSMSToAppUsers(List<WaterUser> users, String message) async {
    print('_sendRateChangeSMSToAppUsers called with ${users.length} users');
    
    // Collect all phone numbers
    final phoneNumbers = users.map((user) => user.phoneNumber!).toList();
    final userNames = users.map((user) => user.name).toList();
    
    print('Phone numbers: ${phoneNumbers.join(', ')}');
    print('User names: ${userNames.join(', ')}');
    
    // Try to send as a group SMS
    await _sendGroupSMS(phoneNumbers, message, userNames);
  }

  static Future<void> _sendRateChangeEmailToAppUsers(List<WaterUser> users, String message, double newRate) async {
    print('_sendRateChangeEmailToAppUsers called with ${users.length} users');
    
    // Collect all email addresses
    final emails = users.map((user) => user.email!).toList();
    final userNames = users.map((user) => user.name).toList();
    
    print('Emails: ${emails.join(', ')}');
    print('User names: ${userNames.join(', ')}');
    
    // Try to send as a group email
    await _sendGroupEmail(emails, 'Water Rate Change - ${newRate.toStringAsFixed(1)} - ${DateFormat('MM/dd/yy').format(DateTime.now())}', message, userNames);
  }

  static Future<void> _sendGroupEmail(List<String> emails, String subject, String message, List<String> userNames) async {
    print('_sendGroupEmail called with ${emails.length} emails');
    
    // Try to send with all emails in TO field
    final encodedSubject = Uri.encodeComponent(subject);
    final encodedMessage = Uri.encodeComponent(message);
    final allEmails = emails.join(',');
    
    // Use TO field for all emails
    final mailtoUri = Uri.parse('mailto:$allEmails?subject=$encodedSubject&body=$encodedMessage');
    
    print('Attempting group email with URI: $mailtoUri');
    
    try {
      if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri);
        print('Group email launched successfully');
        return;
      }
    } catch (e) {
      print('Failed to launch email with canLaunchUrl: $e');
    }
    
    // If canLaunchUrl fails, try direct launch
    print('Trying direct email launch');
    try {
      await launchUrl(mailtoUri);
      print('Group email launched successfully with direct approach');
      return;
    } catch (e) {
      print('Direct email launch failed: $e');
    }
    
    // If all attempts fail, show instructions
    print('All email attempts failed, showing instructions');
    _showGroupEmailInstructions(emails, subject, message, userNames);
  }

  static void _showGroupEmailInstructions(List<String> emails, String subject, String message, List<String> userNames) {
    final emailList = emails.join('\n• ');
    final nameList = userNames.join('\n• ');
    
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('Group Email Instructions'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your email app will open. Please follow these steps:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('1. Add the following emails to TO field:'),
              const SizedBox(height: 8),
              Text('• $emailList'),
              const SizedBox(height: 16),
              const Text(
                'Recipients:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('• $nameList'),
              const SizedBox(height: 16),
              const Text(
                'Subject:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(subject),
              const SizedBox(height: 16),
              const Text(
                'Message:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(message),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Open email app with empty message for user to add recipients
              final mailtoUri = Uri.parse('mailto:?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(message)}');
              launchUrl(mailtoUri);
            },
            child: const Text('Open Email App'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  static void _showRateChangeSuccessDialog(int smsCount, int emailCount, NotificationType notificationType) {
    String message = '';
    
    if (notificationType == NotificationType.sms) {
      message = 'Rate change notification sent to $smsCount water users via SMS.';
    } else if (notificationType == NotificationType.email) {
      message = 'Rate change notification sent to $emailCount water users via email.';
    } else {
      message = 'Rate change notification sent to $smsCount water users via SMS and $emailCount via email.';
    }
    
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void _showRateChangeErrorDialog(String error) {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text('Failed to send rate change notifications: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void _showNoContactInfoDialog() {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('No Contact Information'),
        content: const Text(
          'None of the water users have phone numbers or email addresses. '
          'Please add contact information to the water users first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Future<void> launchEmailWithAttachment({
    required BuildContext context,
    required String subject,
    required String body,
    required String attachmentPath,
    required String attachmentName,
  }) async {
    try {
      print('Attempting to share PDF with email apps...');
      
      // Use Share.shareXFiles to share the PDF file
      // This will show a share sheet with available apps including email apps
      await Share.shareXFiles(
        [XFile(attachmentPath)],
        subject: subject,
        text: body,
      );
      
      print('Share sheet opened successfully');
      
      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Share sheet opened. Select your email app to send with attachment.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      print('Error in launchEmailWithAttachment: $e');
      
      // Fallback to manual instructions
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Share PDF'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'To share the PDF via email:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text('1. Open your email app'),
                const Text('2. Create a new email'),
                Text('3. Set subject to: $subject'),
                const Text('4. Add the PDF as an attachment'),
                const SizedBox(height: 12),
                Text(
                  'PDF location: $attachmentPath',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
} 