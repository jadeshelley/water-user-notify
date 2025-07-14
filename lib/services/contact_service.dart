import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/water_user.dart';

class ContactService {
  static Future<bool> requestContactPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  static Future<List<Contact>> getDeviceContacts() async {
    if (!await requestContactPermission()) {
      throw Exception('Contact permission not granted');
    }

    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
        withGroups: true, // Enable group information
      );
      return contacts;
    } catch (e) {
      throw Exception('Failed to load contacts: $e');
    }
  }

  static Future<List<Group>> getAllGroups() async {
    if (!await requestContactPermission()) {
      throw Exception('Contact permission not granted');
    }

    try {
      final groups = await FlutterContacts.getGroups();
      print('Available groups:');
      for (final group in groups) {
        print('  - ${group.name} (ID: ${group.id})');
      }
      return groups;
    } catch (e) {
      throw Exception('Failed to load groups: $e');
    }
  }

  static Future<List<Contact>> getGroupContacts() async {
    if (!await requestContactPermission()) {
      throw Exception('Contact permission not granted');
    }

    try {
      // First, let's see what groups are available
      final groups = await getAllGroups();
      
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
        withGroups: true,
      );
      
      print('Total contacts loaded: ${contacts.length}');
      
      // Look for the specific "twincreek water users" group
      final twincreekMembers = contacts.where((contact) {
        return contact.groups.any((group) => 
          group.name.toLowerCase().contains('twincreek water users'));
      }).toList();
      
      if (twincreekMembers.isNotEmpty) {
        print('Found ${twincreekMembers.length} members of twincreek water users group');
        
        // Return the actual group members so user can choose which one to use
        return twincreekMembers;
      }
      
      // If no twincreek group found, look for other group contacts
      final otherGroupContacts = contacts.where((contact) {
        final isGroup = isGroupContact(contact);
        if (isGroup) {
          print('Found other group contact: ${contact.displayName}');
        }
        return isGroup;
      }).toList();
      
      print('Other group contacts found: ${otherGroupContacts.length}');
      return otherGroupContacts;
    } catch (e) {
      throw Exception('Failed to load group contacts: $e');
    }
  }

  static List<Contact> filterContactsWithPhoneOrEmail(List<Contact> contacts) {
    return contacts.where((contact) {
      // Include contacts with phone/email OR groups
      return contact.phones.isNotEmpty || 
             contact.emails.isNotEmpty || 
             contact.groups.isNotEmpty;
    }).toList();
  }

  static bool isGroupContact(Contact contact) {
    final name = contact.displayName.toLowerCase();
    
    print('Checking contact: $name');
    print('  - Groups: ${contact.groups.length}');
    print('  - Phones: ${contact.phones.length}');
    print('  - Emails: ${contact.emails.length}');
    
    // Check if this contact IS a group (not belongs to a group)
    // Look for contacts that represent groups themselves
    
    // Check for common group naming patterns in the contact name itself
    final groupKeywords = [
      'group', 'team', 'family', 'water', 'irrigation', 'sprinkler',
      'users', 'members', 'contact', 'list', 'distribution', 'notify',
      'water users', 'irrigation group', 'sprinkler users'
    ];
    
    for (final keyword in groupKeywords) {
      if (name.contains(keyword)) {
        print('  -> Is group (contains keyword: $keyword)');
        return true;
      }
    }
    
    // Check if it has multiple phone numbers or emails (might indicate a group)
    if (contact.phones.length > 2 || contact.emails.length > 2) {
      print('  -> Is group (has multiple contacts)');
      return true;
    }
    
    // Check if the name suggests it's a group (contains numbers, etc.)
    if (name.contains(RegExp(r'\d+')) && 
        (name.contains('group') || name.contains('users') || name.contains('team'))) {
      print('  -> Is group (contains numbers and group keywords)');
      return true;
    }
    
    // Check if this contact represents a group (not just belongs to one)
    // This is tricky - we need to look for contacts that ARE groups, not IN groups
    if (name.contains('twincreek') && name.contains('water')) {
      print('  -> Is group (twincreek water group)');
      return true;
    }
    
    print('  -> Not a group');
    return false;
  }

  static String getGroupMemberCount(Contact contact) {
    // Since we can't get member count directly, we'll show it's a group contact
    if (contact.groups.isNotEmpty) {
      return 'Group contact';
    }
    
    // Try to estimate based on contact info
    final phoneCount = contact.phones.length;
    final emailCount = contact.emails.length;
    
    if (phoneCount > 0 || emailCount > 0) {
      return 'Group contact';
    }
    
    return 'Group contact';
  }

  static WaterUser contactToWaterUser({
    required Contact contact,
    required double sharesOfWater,
  }) {
    return WaterUser(
      id: contact.id,
      name: contact.displayName,
      phoneNumber: contact.phones.isNotEmpty ? contact.phones.first.number : null,
      email: contact.emails.isNotEmpty ? contact.emails.first.address : null,
      sharesOfWater: sharesOfWater,
      createdAt: DateTime.now(),
    );
  }

  static String? extractPhoneNumber(Contact contact) {
    return contact.phones.isNotEmpty ? contact.phones.first.number : null;
  }

  static String? extractEmail(Contact contact) {
    return contact.emails.isNotEmpty ? contact.emails.first.address : null;
  }

  static String getContactDisplayName(Contact contact) {
    return contact.displayName;
  }
} 