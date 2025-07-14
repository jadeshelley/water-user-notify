import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../providers/water_management_provider.dart';
import '../services/notification_service.dart';

class UserDirectoryScreen extends StatelessWidget {
  const UserDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Directory'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.email),
            onPressed: () => _exportToPdfAndEmail(context),
            tooltip: 'Export to PDF & Email',
          ),
        ],
      ),
      body: Consumer<WaterManagementProvider>(
        builder: (context, provider, child) {
          if (provider.waterUsers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No water users found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add users to see them in the directory',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          // Sort users alphabetically by name
          final sortedUsers = List.from(provider.waterUsers)
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

          return Column(
            children: [
              // Header with export button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${sortedUsers.length} Users',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _exportToPdfAndEmail(context),
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text('Export PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              // User list
              Expanded(
                child: ListView.builder(
                  itemCount: sortedUsers.length,
                  itemBuilder: (context, index) {
                    final user = sortedUsers[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name and shares row
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${user.sharesOfWater} shares',
                                    style: TextStyle(
                                      color: Colors.blue[800],
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Contact info row
                            if (user.phoneNumber != null || user.email != null)
                              Row(
                                children: [
                                  if (user.phoneNumber != null) ...[
                                    Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        user.phoneNumber!,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (user.phoneNumber != null && user.email != null)
                                    const SizedBox(width: 16),
                                  if (user.email != null) ...[
                                    Icon(Icons.email, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        user.email!,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportToPdfAndEmail(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating PDF...'),
            ],
          ),
        ),
      );

      final provider = Provider.of<WaterManagementProvider>(context, listen: false);
      final sortedUsers = List.from(provider.waterUsers)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      // Generate PDF
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Water Users Directory',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Generated: ${DateTime.now().toString().split('.')[0]}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Summary
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Text(
                    'Total Users: ${sortedUsers.length}',
                    style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Users table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Phone', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Email', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Shares', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    // User rows
                    ...sortedUsers.map((user) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(user.name),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(user.phoneNumber ?? '-'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(user.email ?? '-'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(user.sharesOfWater.toString()),
                        ),
                      ],
                    )).toList(),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Save PDF to Downloads directory (more accessible)
      final directory = await getApplicationDocumentsDirectory();
      final downloadsPath = '${directory.path}/Downloads';
      
      // Create Downloads directory if it doesn't exist
      final downloadsDir = Directory(downloadsPath);
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      
      final file = File('$downloadsPath/water_users_directory.pdf');
      await file.writeAsBytes(await pdf.save());

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Launch email with PDF attachment
      await NotificationService.launchEmailWithAttachment(
        context: context,
        subject: 'Water Users Directory - ${DateTime.now().toString().split(' ')[0]}',
        body: 'Please find attached the water users directory as of ${DateTime.now().toString().split('.')[0]}.',
        attachmentPath: file.path,
        attachmentName: 'water_users_directory.pdf',
      );

    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 