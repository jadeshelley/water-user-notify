import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_management_provider.dart';
import '../services/contact_service.dart';
import '../models/notification_type.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _groupNameController;
  late TextEditingController _groupPhoneController;
  late TextEditingController _groupEmailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _groupNameController = TextEditingController();
    _groupPhoneController = TextEditingController();
    _groupEmailController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<WaterManagementProvider>(context);
    
    // Load current group contact settings
    _groupNameController.text = provider.groupContactName ?? '';
    _groupPhoneController.text = provider.groupContactPhone ?? '';
    _groupEmailController.text = provider.groupContactEmail ?? '';
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupPhoneController.dispose();
    _groupEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Consumer<WaterManagementProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.group,
                              color: Theme.of(context).colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Group Contact Settings',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Configure a group contact for sending notifications to all water users at once. This should be a group contact you create in your phone\'s contacts app.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _groupNameController,
                          decoration: const InputDecoration(
                            labelText: 'Group Contact Name',
                            hintText: 'e.g., Water Users Group',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.group),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _groupPhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Group Phone Number (Optional)',
                            hintText: 'e.g., +1234567890',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _groupEmailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Group Email (Optional)',
                            hintText: 'e.g., waterusers@example.com',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _importFromContacts,
                                icon: _isLoading 
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.contacts),
                                label: const Text('Import from Contacts'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveGroupContact,
                                child: const Text('Save Settings'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How Group Notifications Work',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '1. Create a group contact in your phone\'s contacts app\n'
                          '2. Add all water users to this group\n'
                          '3. Configure the group contact details above\n'
                          '4. When you change the rate, notifications will be sent to the entire group at once\n'
                          '5. This is more efficient than sending individual messages to each user',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (provider.groupContactName != null) ...[
                  Card(
                    elevation: 1,
                    color: Colors.green.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Group Contact Configured',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Group: ${provider.groupContactName}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (provider.groupContactPhone != null)
                            Text('Phone: ${provider.groupContactPhone}'),
                          if (provider.groupContactEmail != null)
                            Text('Email: ${provider.groupContactEmail}'),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _clearGroupContact,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Clear Group Contact'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _saveGroupContact() {
    final name = _groupNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a group contact name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = Provider.of<WaterManagementProvider>(context, listen: false);
    provider.updateGroupContact(
      name: name,
      phoneNumber: _groupPhoneController.text.trim().isEmpty 
        ? null 
        : _groupPhoneController.text.trim(),
      email: _groupEmailController.text.trim().isEmpty 
        ? null 
        : _groupEmailController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Group contact settings saved'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _clearGroupContact() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Group Contact'),
        content: const Text(
          'Are you sure you want to clear the group contact settings? This will remove the configured group contact for notifications.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final provider = Provider.of<WaterManagementProvider>(context, listen: false);
              provider.clearGroupContact();
              _groupNameController.clear();
              _groupPhoneController.clear();
              _groupEmailController.clear();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Group contact cleared'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _importFromContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final groupContacts = await ContactService.getGroupContacts();
      
      if (groupContacts.isEmpty) {
        // If no groups found, show all contacts but with a warning
        final allContacts = await ContactService.getDeviceContacts();
        final contactsWithPhoneOrEmail = ContactService.filterContactsWithPhoneOrEmail(allContacts);
        
        if (contactsWithPhoneOrEmail.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No contacts found. Please create a group contact in your phone\'s contacts app first.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // Show warning dialog
        final shouldShowAll = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('No Group Contacts Found'),
            content: const Text(
              'No group contacts were detected. You can either:\n\n'
              '1. Create a group contact in your phone\'s contacts app first, or\n'
              '2. Browse all contacts to find a suitable contact to use as a group.\n\n'
              'Would you like to browse all contacts?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Browse All Contacts'),
              ),
            ],
          ),
        );

        if (shouldShowAll == true && mounted) {
          _showContactPickerDialog(contactsWithPhoneOrEmail, showAllContacts: true);
        }
        return;
      }

      // Check if these are group members (from twincreek water users group)
      final isGroupMembers = groupContacts.length > 1 && 
        groupContacts.every((contact) => contact.groups.any((group) => 
          group.name.toLowerCase().contains('twincreek water users')));
      
      if (isGroupMembers) {
        // Get the actual group name from the first contact
        final actualGroupName = groupContacts.first.groups
            .firstWhere((group) => group.name.toLowerCase().contains('twincreek water users'))
            .name;
        
        // Show group member picker
        if (mounted) {
          _showGroupMemberPicker(groupContacts, actualGroupName);
        }
      } else {
        // Show regular contact picker
        if (mounted) {
          _showContactPickerDialog(groupContacts, showAllContacts: false);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading group contacts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showContactPickerDialog(List<dynamic> contacts, {bool showAllContacts = false}) {
    final searchController = TextEditingController();
    List<dynamic> filteredContacts = List.from(contacts);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(showAllContacts ? 'Select Contact (All Contacts)' : 'Select Group Contact'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  if (showAllContacts) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: const Text(
                        '⚠️ No group contacts detected. Look for contacts with "group", "team", or multiple phone numbers.',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    showAllContacts 
                      ? 'Choose a contact to use as your group contact:'
                      : 'Choose a group contact that contains all your water users:',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: showAllContacts ? 'Search contacts' : 'Search group contacts',
                      hintText: 'Type to search...',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        if (value.isEmpty) {
                          filteredContacts = List.from(contacts);
                        } else {
                          filteredContacts = contacts.where((contact) {
                            final name = ContactService.getContactDisplayName(contact).toLowerCase();
                            final phone = ContactService.extractPhoneNumber(contact)?.toLowerCase() ?? '';
                            final email = ContactService.extractEmail(contact)?.toLowerCase() ?? '';
                            final searchTerm = value.toLowerCase();
                            
                            return name.contains(searchTerm) || 
                                   phone.contains(searchTerm) || 
                                   email.contains(searchTerm);
                          }).toList();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredContacts.isEmpty
                        ? const Center(
                            child: Text('No contacts found'),
                          )
                        : ListView.builder(
                            itemCount: filteredContacts.length,
                            itemBuilder: (context, index) {
                              final contact = filteredContacts[index];
                              final name = ContactService.getContactDisplayName(contact);
                              final phone = ContactService.extractPhoneNumber(contact);
                              final email = ContactService.extractEmail(contact);
                              
                              // Check if this contact is a group (has multiple members)
                              final isGroup = ContactService.isGroupContact(contact);
                              
                              return ListTile(
                                leading: Icon(
                                  isGroup ? Icons.group : Icons.person,
                                  color: isGroup ? Colors.blue : Colors.grey,
                                ),
                                title: Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: isGroup ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isGroup) ...[
                                      Text(
                                        ContactService.getGroupMemberCount(contact),
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                    if (phone != null) Text('Phone: $phone'),
                                    if (email != null) Text('Email: $email'),
                                  ],
                                ),
                                onTap: () {
                                  _groupNameController.text = name;
                                  if (phone != null) _groupPhoneController.text = phone;
                                  if (email != null) _groupEmailController.text = email;
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showGroupMemberPicker(List<dynamic> groupMembers, String groupName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Contact for $groupName'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Text(
                'Choose which contact to use for the group. This contact will be used in the SMS/email app:',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: groupMembers.length,
                  itemBuilder: (context, index) {
                    final contact = groupMembers[index];
                    final name = ContactService.getContactDisplayName(contact);
                    final phone = ContactService.extractPhoneNumber(contact);
                    final email = ContactService.extractEmail(contact);
                    
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (phone != null) Text('Phone: $phone'),
                          if (email != null) Text('Email: $email'),
                        ],
                      ),
                      onTap: () {
                        _groupNameController.text = '$groupName (${groupMembers.length} members)';
                        // Store group information instead of individual contact
                        _groupPhoneController.text = 'group:$groupName';
                        if (email != null) _groupEmailController.text = email;
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
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
} 