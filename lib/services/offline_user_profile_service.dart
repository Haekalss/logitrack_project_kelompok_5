import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kirimtrack/user_profile_model.dart';
import 'package:kirimtrack/database_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineUserProfileService {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  OfflineUserProfileService() {
    _initConnectivity();
  }

  void _initConnectivity() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      // Track connectivity for future sync features
    });
  }

  /// Get current user profile - OFFLINE FIRST
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // 1. Load dari database lokal dulu
      final profileMap = await _dbService.getUserProfile(user.uid);
      
      if (profileMap != null) {
        print('✅ Profile loaded from local database');
        return _mapToUserProfile(profileMap);
      }

      // 2. Jika tidak ada di lokal, buat dari Firebase Auth
      print('📝 Creating profile from Firebase Auth data');
      return await _createProfileFromFirebaseUser(user);
      
    } catch (e) {
      print('❌ Error loading profile: $e');
      return null;
    }
  }

  /// Create initial profile from Firebase user data
  Future<UserProfile> _createProfileFromFirebaseUser(User user) async {
    final profile = UserProfile(
      id: user.uid,
      name: user.displayName ?? 'Driver ${user.uid.substring(0, 8)}',
      email: user.email ?? '',
      phoneNumber: user.phoneNumber,
      profileImageUrl: user.photoURL,
      joinDate: user.metadata.creationTime ?? DateTime.now(),
      lastUpdated: DateTime.now(),
    );

    // Simpan ke database lokal
    await _dbService.insertOrUpdateProfile(profile.toJson());
    print('✅ Profile created and saved locally');

    return profile;
  }

  /// Update user profile - OFFLINE FIRST
  Future<UserProfile> updateProfile({
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // 1. Get current profile
      final currentProfile = await getCurrentUserProfile();
      if (currentProfile == null) throw Exception('Profile not found');

      // 2. Create updated profile
      final updatedProfile = currentProfile.copyWith(
        name: name,
        phoneNumber: phoneNumber,
        profileImageUrl: profileImageUrl,
      );

      // 3. Save to local database immediately
      await _dbService.insertOrUpdateProfile(updatedProfile.toJson());
      
      // 4. Update Firebase Auth profile if needed
      if (name != null && name != user.displayName) {
        await user.updateDisplayName(name);
      }
      
      if (profileImageUrl != null && profileImageUrl != user.photoURL) {
        await user.updatePhotoURL(profileImageUrl);
      }

      print('✅ Profile updated offline-first');
      return updatedProfile;

    } catch (e) {
      print('❌ Error updating profile: $e');
      rethrow;
    }
  }

  /// Update delivery statistics - OFFLINE FIRST
  Future<void> updateDeliveryStats({
    int? totalDeliveries,
    int? completedDeliveries,
    double? rating,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _dbService.updateProfileStats(
        user.uid,
        totalDeliveries: totalDeliveries,
        completedDeliveries: completedDeliveries,
        rating: rating,
      );
      print('✅ Delivery stats updated offline');
    } catch (e) {
      print('❌ Error updating delivery stats: $e');
    }
  }

  /// Increment completed deliveries counter
  Future<void> incrementCompletedDeliveries() async {
    final profile = await getCurrentUserProfile();
    if (profile == null) return;

    await updateDeliveryStats(
      totalDeliveries: profile.totalDeliveries + 1,
      completedDeliveries: profile.completedDeliveries + 1,
    );
  }

  /// Get app theme setting
  Future<bool> getDarkModeEnabled() async {
    return await _dbService.getBoolSetting('dark_mode_enabled', defaultValue: false);
  }

  /// Set app theme setting
  Future<void> setDarkModeEnabled(bool enabled) async {
    await _dbService.setBoolSetting('dark_mode_enabled', enabled);
  }

  /// Get notification setting
  Future<bool> getNotificationsEnabled() async {
    return await _dbService.getBoolSetting('notifications_enabled', defaultValue: true);
  }

  /// Set notification setting
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _dbService.setBoolSetting('notifications_enabled', enabled);
  }

  /// Get auto backup setting
  Future<bool> getAutoBackupEnabled() async {
    return await _dbService.getBoolSetting('auto_backup_enabled', defaultValue: true);
  }

  /// Set auto backup setting  
  Future<void> setAutoBackupEnabled(bool enabled) async {
    await _dbService.setBoolSetting('auto_backup_enabled', enabled);
  }

  /// Clear user data (logout)
  Future<void> clearUserData() async {
    try {
      await _dbService.clearAllData();
      print('✅ User data cleared');
    } catch (e) {
      print('❌ Error clearing user data: $e');
    }
  }

  /// Helper method to convert database map to UserProfile
  UserProfile _mapToUserProfile(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phoneNumber: map['phone_number'] as String?,
      profileImageUrl: map['profile_image_url'] as String?,
      totalDeliveries: map['total_deliveries'] as int? ?? 0,
      completedDeliveries: map['completed_deliveries'] as int? ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      joinDate: DateTime.fromMillisecondsSinceEpoch(map['join_date'] as int),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['last_updated'] as int),
    );
  }

  void dispose() {
    _connectivitySubscription.cancel();
  }
}