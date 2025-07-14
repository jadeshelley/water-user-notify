import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/water_management_provider.dart';

class EditRateScreen extends StatefulWidget {
  const EditRateScreen({super.key});

  @override
  State<EditRateScreen> createState() => _EditRateScreenState();
}

class _EditRateScreenState extends State<EditRateScreen> {
  late TextEditingController _rateController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _rateController = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<WaterManagementProvider>(context);
    _rateController.text = provider.currentRate.toString();
    
    // Auto-focus and select text after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _rateController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _rateController.text.length,
      );
    });
  }

  @override
  void dispose() {
    _rateController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Current Rate'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          TextButton(
            onPressed: _saveRate,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<WaterManagementProvider>(
          builder: (context, provider, child) {
            return Column(
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
                              Icons.speed,
                              color: Theme.of(context).colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Current Rate',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _rateController,
                          focusNode: _focusNode,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Rate Value',
                            hintText: 'Enter rate...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Current Rate: ${provider.currentRate.toStringAsFixed(1)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
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
                          'Formula Information',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Formula: (Rate × 3 × Shares) ÷ Hours = Sprinkler Heads',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The rate value is used in calculations to determine the number of sprinkler heads each user can operate based on their water shares and the duration of operation.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveRate,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }

  void _saveRate() async {
    final newRate = double.tryParse(_rateController.text);
    if (newRate != null && newRate > 0) {
      final provider = Provider.of<WaterManagementProvider>(context, listen: false);
      final oldRate = provider.currentRate;
      
      provider.updateRate(newRate);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rate updated to ${newRate.toStringAsFixed(1)}'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid positive number'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 