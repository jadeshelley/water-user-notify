import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/water_user.dart';

class StorageService {
  static const String _waterUsersKey = 'water_users';
  static const String _rateKey = 'current_rate';
  static const String _groupContactNameKey = 'group_contact_name';
  static const String _groupContactPhoneKey = 'group_contact_phone';
  static const String _groupContactEmailKey = 'group_contact_email';

  static Future<void> saveWaterUsers(List<WaterUser> waterUsers) async {
    final prefs = await SharedPreferences.getInstance();
    final waterUsersJson = waterUsers.map((user) => user.toJson()).toList();
    await prefs.setString(_waterUsersKey, jsonEncode(waterUsersJson));
  }

  static Future<List<WaterUser>> loadWaterUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final waterUsersString = prefs.getString(_waterUsersKey);
    
    if (waterUsersString == null) {
      return [];
    }

    try {
      final waterUsersJson = jsonDecode(waterUsersString) as List;
      return waterUsersJson
          .map((json) => WaterUser.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading water users: $e');
      return [];
    }
  }

  static Future<void> addWaterUser(WaterUser waterUser) async {
    final waterUsers = await loadWaterUsers();
    waterUsers.add(waterUser);
    await saveWaterUsers(waterUsers);
  }

  static Future<void> updateWaterUser(WaterUser updatedUser) async {
    final waterUsers = await loadWaterUsers();
    final index = waterUsers.indexWhere((user) => user.id == updatedUser.id);
    
    if (index != -1) {
      waterUsers[index] = updatedUser;
      await saveWaterUsers(waterUsers);
    }
  }

  static Future<void> deleteWaterUser(String userId) async {
    final waterUsers = await loadWaterUsers();
    waterUsers.removeWhere((user) => user.id == userId);
    await saveWaterUsers(waterUsers);
  }

  static Future<void> saveRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_rateKey, rate);
  }

  static Future<double> loadRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_rateKey) ?? 1.0; // Default rate of 1.0
  }

  static Future<void> saveGroupContact({
    required String name,
    String? phoneNumber,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_groupContactNameKey, name);
    if (phoneNumber != null) {
      await prefs.setString(_groupContactPhoneKey, phoneNumber);
    } else {
      await prefs.remove(_groupContactPhoneKey);
    }
    if (email != null) {
      await prefs.setString(_groupContactEmailKey, email);
    } else {
      await prefs.remove(_groupContactEmailKey);
    }
  }

  static Future<Map<String, String?>> loadGroupContact() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_groupContactNameKey),
      'phoneNumber': prefs.getString(_groupContactPhoneKey),
      'email': prefs.getString(_groupContactEmailKey),
    };
  }

  static Future<void> clearGroupContact() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_groupContactNameKey);
    await prefs.remove(_groupContactPhoneKey);
    await prefs.remove(_groupContactEmailKey);
  }

  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_waterUsersKey);
    await prefs.remove(_rateKey);
    await prefs.remove(_groupContactNameKey);
    await prefs.remove(_groupContactPhoneKey);
    await prefs.remove(_groupContactEmailKey);
  }
} 