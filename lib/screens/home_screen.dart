import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_management_provider.dart';
import '../widgets/water_users_list.dart';
import '../widgets/quick_actions_card.dart';
import '../widgets/stats_card.dart';
import 'add_user_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Management'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<WaterManagementProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Reload data
              await provider.loadData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Card
                  StatsCard(
                    totalUsers: provider.waterUsers.length,
                    totalShares: provider.getTotalShares(),
                    currentRate: provider.currentRate,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Quick Actions Card
                  const QuickActionsCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Water Users Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Water Users (${provider.waterUsers.length})',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AddUserScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add User'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Water Users List
                  const WaterUsersList(),
                ],
              ),
            ),
          );
        },
      ),

    );
  }
} 