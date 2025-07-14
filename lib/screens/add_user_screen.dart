import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_management_provider.dart';
import '../models/water_user.dart';
import '../services/contact_service.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _sharesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _sharesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Water User'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Import from Contacts Button
                    ElevatedButton.icon(
                      onPressed: _importFromContacts,
                      icon: const Icon(Icons.contacts),
                      label: const Text('Import from Contacts'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    const Divider(),
                    
                    const SizedBox(height: 16),
                    
                    // Manual Entry Form
                    Text(
                      'Manual Entry',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _sharesController,
                      decoration: const InputDecoration(
                        labelText: 'Water Shares *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.water_drop),
                        helperText: 'Enter the number of water shares',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter water shares';
                        }
                        final shares = double.tryParse(value);
                        if (shares == null || shares <= 0) {
                          return 'Please enter a valid positive number';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    ElevatedButton(
                      onPressed: _saveUser,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Add Water User'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _importFromContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final contacts = await ContactService.getDeviceContacts();
      final filteredContacts = ContactService.filterContactsWithPhoneOrEmail(contacts);
      
      if (mounted) {
        _showContactSelectionDialog(filteredContacts);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading contacts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showContactSelectionDialog(List<dynamic> contacts) {
    final searchController = TextEditingController();
    List<dynamic> filteredContacts = List.from(contacts);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select Contact'),
          content: SizedBox(
            width: double.maxFinite,
            height: 450,
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search contacts...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
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
                const SizedBox(height: 12),
                // Contact list
                Expanded(
                  child: filteredContacts.isEmpty
                      ? const Center(
                          child: Text(
                            'No contacts found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredContacts.length,
                          itemBuilder: (context, index) {
                            final contact = filteredContacts[index];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  ContactService.getContactDisplayName(contact)[0].toUpperCase(),
                                ),
                              ),
                              title: Text(ContactService.getContactDisplayName(contact)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (ContactService.extractPhoneNumber(contact) != null)
                                    Text('Phone: ${ContactService.extractPhoneNumber(contact)}'),
                                  if (ContactService.extractEmail(contact) != null)
                                    Text('Email: ${ContactService.extractEmail(contact)}'),
                                ],
                              ),
                              onTap: () {
                                Navigator.of(context).pop();
                                _showSharesDialog(contact);
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
      ),
    );
  }

  void _showSharesDialog(dynamic contact) {
    final sharesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Water Shares for ${ContactService.getContactDisplayName(contact)}'),
        content: TextField(
          controller: sharesController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Water Shares',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final shares = double.tryParse(sharesController.text);
              if (shares != null && shares > 0) {
                Navigator.of(context).pop();
                _addContactAsUser(contact, shares);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addContactAsUser(dynamic contact, double shares) {
    final waterUser = ContactService.contactToWaterUser(
      contact: contact,
      sharesOfWater: shares,
    );
    
    final provider = Provider.of<WaterManagementProvider>(context, listen: false);
    provider.addWaterUser(waterUser);
    
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${waterUser.name} added successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _saveUser() {
    if (_formKey.currentState!.validate()) {
      final waterUser = WaterUser(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        sharesOfWater: double.parse(_sharesController.text),
        createdAt: DateTime.now(),
      );
      
      final provider = Provider.of<WaterManagementProvider>(context, listen: false);
      provider.addWaterUser(waterUser);
      
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${waterUser.name} added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
} 