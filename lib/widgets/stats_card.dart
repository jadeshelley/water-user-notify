import 'package:flutter/material.dart';
import '../screens/edit_rate_screen.dart';

class StatsCard extends StatelessWidget {
  final int totalUsers;
  final double totalShares;
  final double currentRate;

  const StatsCard({
    super.key,
    required this.totalUsers,
    required this.totalShares,
    required this.currentRate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Users',
                    totalUsers.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Shares',
                    totalShares.toStringAsFixed(2),
                    Icons.water_drop,
                    Colors.cyan,
                  ),
                ),
                Expanded(
                  child: _buildTouchableRateItem(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTouchableRateItem(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const EditRateScreen(),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
                width: 1,
              ),
              // Add subtle shadow to indicate it's clickable
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.speed,
                  color: Colors.green,
                  size: 24,
                ),
                // Add a small edit icon overlay
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                currentRate.toStringAsFixed(1),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.touch_app,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Text(
            'Current Rate',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
} 