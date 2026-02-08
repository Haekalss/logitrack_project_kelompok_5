import 'package:flutter/material.dart';
import 'package:kirimtrack/user_profile_model.dart';
import 'package:kirimtrack/services/offline_user_profile_service.dart';

class OfflineUserProfileProvider with ChangeNotifier {
  final OfflineUserProfileService _profileService = OfflineUserProfileService();
  
  UserProfile? _currentProfile;
  bool _isLoading = false;
  String? _error;
  
  // App Settings
  bool _isDarkModeEnabled = false;
  bool _isNotificationsEnabled = true;
  bool _isAutoBackupEnabled = true;

  // Getters
  UserProfile? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isDarkModeEnabled => _isDarkModeEnabled;
  bool get isNotificationsEnabled => _isNotificationsEnabled;
  bool get isAutoBackupEnabled => _isAutoBackupEnabled;

  /// Initialize provider - load profile and settings
  Future<void> initialize() async {
    _setLoading(true);
    _error = null;
    
    try {
      // Load profile
      _currentProfile = await _profileService.getCurrentUserProfile();
      
      // Load settings
      _isDarkModeEnabled = await _profileService.getDarkModeEnabled();
      _isNotificationsEnabled = await _profileService.getNotificationsEnabled();
      _isAutoBackupEnabled = await _profileService.getAutoBackupEnabled();
      
      notifyListeners();
      print('✅ Profile provider initialized successfully');
    } catch (e) {
      _error = 'Error initializing profile: $e';
      print('❌ Error in profile initialization: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update user profile information
  Future<void> updateProfile({
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    _setLoading(true);
    _error = null;
    
    try {
      _currentProfile = await _profileService.updateProfile(
        name: name,
        phoneNumber: phoneNumber,
        profileImageUrl: profileImageUrl,
      );
      
      notifyListeners();
      print('✅ Profile updated successfully');
    } catch (e) {
      _error = 'Error updating profile: $e';
      print('❌ Error updating profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Mark delivery as completed (update stats)
  Future<void> completeDelivery() async {
    try {
      await _profileService.incrementCompletedDeliveries();
      
      // Refresh profile to get updated stats
      _currentProfile = await _profileService.getCurrentUserProfile();
      notifyListeners();
      
      print('✅ Delivery completed, stats updated');
    } catch (e) {
      print('❌ Error updating delivery stats: $e');
    }
  }

  /// Toggle dark mode
  Future<void> toggleDarkMode(bool enabled) async {
    try {
      await _profileService.setDarkModeEnabled(enabled);
      _isDarkModeEnabled = enabled;
      notifyListeners();
      print('✅ Dark mode ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      print('❌ Error updating dark mode setting: $e');
    }
  }

  /// Toggle notifications
  Future<void> toggleNotifications(bool enabled) async {
    try {
      await _profileService.setNotificationsEnabled(enabled);
      _isNotificationsEnabled = enabled;
      notifyListeners();
      print('✅ Notifications ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      print('❌ Error updating notifications setting: $e');
    }
  }

  /// Toggle auto backup
  Future<void> toggleAutoBackup(bool enabled) async {
    try {
      await _profileService.setAutoBackupEnabled(enabled);
      _isAutoBackupEnabled = enabled;
      notifyListeners();
      print('✅ Auto backup ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      print('❌ Error updating auto backup setting: $e');
    }
  }

  /// Logout - clear user data
  Future<void> logout() async {
    try {
      await _profileService.clearUserData();
      _currentProfile = null;
      _isDarkModeEnabled = false;
      _isNotificationsEnabled = true;
      _isAutoBackupEnabled = true;
      notifyListeners();
      print('✅ User data cleared on logout');
    } catch (e) {
      print('❌ Error clearing user data: $e');
    }
  }

  /// Get profile statistics - dengan opsi pass tasks untuk perhitungan dinamis
  Map<String, dynamic> getProfileStats({List<dynamic>? tasks}) {
    // Jika tasks diberikan, hitung dari tasks aktual
    if (tasks != null && tasks.isNotEmpty) {
      final totalDeliveries = tasks.length;
      final completedDeliveries = tasks.where((t) => t.isCompleted ?? false).length;
      final completionRate = totalDeliveries > 0 
          ? (completedDeliveries / totalDeliveries) * 100 
          : 0.0;
      
      // Tentukan rating berdasarkan completion rate
      double rating = (completionRate / 20).clamp(0.0, 5.0);
      
      // Tentukan experience level
      String experienceLevel;
      if (totalDeliveries >= 100) {
        experienceLevel = 'Expert Driver';
      } else if (totalDeliveries >= 50) {
        experienceLevel = 'Experienced Driver';
      } else if (totalDeliveries >= 20) {
        experienceLevel = 'Regular Driver';
      } else if (totalDeliveries >= 5) {
        experienceLevel = 'New Driver';
      } else {
        experienceLevel = 'Rookie Driver';
      }
      
      return {
        'totalDeliveries': totalDeliveries,
        'completedDeliveries': completedDeliveries,
        'completionRate': completionRate,
        'rating': rating,
        'experienceLevel': experienceLevel,
      };
    }
    
    // Fallback ke profile jika tidak ada tasks
    if (_currentProfile == null) {
      return {
        'totalDeliveries': 0,
        'completedDeliveries': 0,
        'completionRate': 0.0,
        'rating': 0.0,
        'experienceLevel': 'Rookie Driver',
      };
    }

    return {
      'totalDeliveries': _currentProfile!.totalDeliveries,
      'completedDeliveries': _currentProfile!.completedDeliveries,
      'completionRate': _currentProfile!.completionRate,
      'rating': _currentProfile!.rating,
      'experienceLevel': _currentProfile!.experienceLevel,
    };
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _profileService.dispose();
    super.dispose();
  }
}