import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/water_user.dart';
import '../models/notification_type.dart';
import '../services/storage_service.dart';
import '../services/water_calculator.dart';
import '../services/notification_service.dart';

class WaterManagementProvider extends ChangeNotifier {
  List<WaterUser> _waterUsers = [];
  double _currentRate = 1.0;
  bool _isLoading = false;
  String? _groupContactName;
  String? _groupContactPhone;
  String? _groupContactEmail;

  List<WaterUser> get waterUsers => _waterUsers;
  double get currentRate => _currentRate;
  bool get isLoading => _isLoading;
  String? get groupContactName => _groupContactName;
  String? get groupContactPhone => _groupContactPhone;
  String? get groupContactEmail => _groupContactEmail;

  WaterManagementProvider() {
    _loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _waterUsers = await StorageService.loadWaterUsers();
      _currentRate = await StorageService.loadRate();
      
      // Load group contact settings
      final groupContact = await StorageService.loadGroupContact();
      _groupContactName = groupContact['name'];
      _groupContactPhone = groupContact['phoneNumber'];
      _groupContactEmail = groupContact['email'];
    } catch (e) {
      print('Error loading data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadData() async {
    await loadData();
  }

  Future<void> addWaterUser(WaterUser waterUser) async {
    _waterUsers.add(waterUser);
    await StorageService.saveWaterUsers(_waterUsers);
    notifyListeners();
  }

  Future<void> updateWaterUser(WaterUser waterUser) async {
    final index = _waterUsers.indexWhere((user) => user.id == waterUser.id);
    if (index != -1) {
      _waterUsers[index] = waterUser;
      await StorageService.saveWaterUsers(_waterUsers);
      notifyListeners();
    }
  }

  Future<void> deleteWaterUser(String userId) async {
    _waterUsers.removeWhere((user) => user.id == userId);
    await StorageService.saveWaterUsers(_waterUsers);
    notifyListeners();
  }

  Future<void> updateRate(double newRate) async {
    _currentRate = newRate;
    await StorageService.saveRate(newRate);
    notifyListeners();
  }

  double calculateSprinklerHeadsForUser(WaterUser user, int hoursInPeriod) {
    return WaterCalculator.calculateSprinklerHeads(
      rate: _currentRate,
      sharesOfWater: user.sharesOfWater,
      hoursInPeriod: hoursInPeriod,
    );
  }

  double calculateFor12HourPeriod(WaterUser user) {
    return calculateSprinklerHeadsForUser(user, 12);
  }

  double calculateFor24HourPeriod(WaterUser user) {
    return calculateSprinklerHeadsForUser(user, 24);
  }

  Future<void> notifyUser(WaterUser user, int hoursInPeriod, {NotificationType notificationType = NotificationType.both, required BuildContext context}) async {
    final sprinklerHeads = calculateSprinklerHeadsForUser(user, hoursInPeriod);
    
    try {
      await NotificationService.notifyWaterUser(
        userName: user.name,
        sprinklerHeads: sprinklerHeads,
        currentRate: _currentRate,
        userShares: user.sharesOfWater,
        hoursInPeriod: hoursInPeriod,
        phoneNumber: user.phoneNumber,
        email: user.email,
        notificationType: notificationType,
        context: context,
      );
      
      // Show success message
      print('Notification sent to ${user.name} for ${hoursInPeriod}-hour period');
    } catch (e) {
      print('Error sending notification to ${user.name}: $e');
    }
  }

  Future<void> notifyAllUsers(int hoursInPeriod, {NotificationType notificationType = NotificationType.both, required BuildContext context}) async {
    // Prepare user data for bulk notification
    List<Map<String, dynamic>> userData = [];
    
    for (final user in _waterUsers) {
      final sprinklerHeads = calculateSprinklerHeadsForUser(user, hoursInPeriod);
      userData.add({
        'userName': user.name,
        'sprinklerHeads': sprinklerHeads,
        'currentRate': _currentRate,
        'userShares': user.sharesOfWater,
        'hoursInPeriod': hoursInPeriod,
        'phoneNumber': user.phoneNumber,
        'email': user.email,
      });
    }
    
    // Use the bulk notification method
    await NotificationService.notifyAllUsersWithConfirmation(
      userData: userData,
      notificationType: notificationType,
      context: context,
    );
  }

  Future<void> notifyRateChange({
    required double oldRate,
    required double newRate,
    required List<Map<String, dynamic>> userData,
    required NotificationType notificationType,
    required BuildContext context,
  }) async {
    await NotificationService.notifyRateChange(
      oldRate: oldRate,
      newRate: newRate,
      userData: userData,
      notificationType: notificationType,
      context: context,
    );
  }

  List<WaterUser> searchUsers(String query) {
    if (query.isEmpty) return _waterUsers;
    
    return _waterUsers.where((user) {
      return user.name.toLowerCase().contains(query.toLowerCase()) ||
             (user.email?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
             (user.phoneNumber?.contains(query) ?? false);
    }).toList();
  }

  double getTotalShares() {
    return _waterUsers.fold(0.0, (sum, user) => sum + user.sharesOfWater);
  }

  void clearAllData() async {
    _waterUsers.clear();
    _currentRate = 1.0;
    await StorageService.clearAllData();
    notifyListeners();
  }

  Future<void> updateGroupContact({
    required String name,
    String? phoneNumber,
    String? email,
  }) async {
    _groupContactName = name;
    _groupContactPhone = phoneNumber;
    _groupContactEmail = email;
    
    await StorageService.saveGroupContact(
      name: name,
      phoneNumber: phoneNumber,
      email: email,
    );
    notifyListeners();
  }

  Future<void> clearGroupContact() async {
    _groupContactName = null;
    _groupContactPhone = null;
    _groupContactEmail = null;
    
    await StorageService.clearGroupContact();
    notifyListeners();
  }
} 