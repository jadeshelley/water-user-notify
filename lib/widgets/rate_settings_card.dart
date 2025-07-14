import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_management_provider.dart';

class RateSettingsCard extends StatefulWidget {
  const RateSettingsCard({super.key});

  @override
  State<RateSettingsCard> createState() => _RateSettingsCardState();
}

class _RateSettingsCardState extends State<RateSettingsCard> {
  late TextEditingController _rateController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _rateController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<WaterManagementProvider>(context);
    _rateController.text = provider.currentRate.toString();
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rate Settings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = !_isEditing;
                          if (_isEditing) {
                            _rateController.text = provider.currentRate.toString();
                          }
                        });
                      },
                      icon: Icon(_isEditing ? Icons.save : Icons.edit),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _isEditing
                          ? TextField(
                              controller: _rateController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Rate',
                                border: OutlineInputBorder(),
                                helperText: 'Enter the current rate value',
                              ),
                            )
                          : _buildRateDisplay(context, provider.currentRate),
                    ),
                    if (_isEditing) ...[
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () => _saveRate(provider),
                        child: const Text('Save'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                            _rateController.text = provider.currentRate.toString();
                          });
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Formula: (Rate × 3 × Shares) ÷ Hours = Sprinkler Heads',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRateDisplay(BuildContext context, double rate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.speed,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Current Rate: ${rate.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _saveRate(WaterManagementProvider provider) {
    final newRate = double.tryParse(_rateController.text);
    if (newRate != null && newRate > 0) {
      provider.updateRate(newRate);
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rate updated to ${newRate.toStringAsFixed(2)}'),
          backgroundColor: Colors.green,
        ),
      );
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