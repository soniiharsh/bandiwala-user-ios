import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class VersionChecker {
  static Future<bool> isUpdateRequired(String currentVersion) async {
    try {
      // Fetch the latest-version collection
      final snapshot = await FirebaseFirestore.instance
          .collection('latest-version')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        if (kDebugMode) {
          print('⚠️ No version document found in Firestore');
        }
        return false; // Allow app to continue if no version info
      }

      final doc = snapshot.docs.first;
      final minimumVersion = doc.data()['minimum-version'] as String?;

      if (minimumVersion == null) {
        if (kDebugMode) {
          print('⚠️ minimum-version field not found');
        }
        return false;
      }

      if (kDebugMode) {
        print('📱 Current version: $currentVersion');
        print('📱 Minimum version: $minimumVersion');
      }

      // Compare versions
      final isOutdated = _compareVersions(currentVersion, minimumVersion) < 0;

      if (isOutdated) {
        if (kDebugMode) {
          print('❌ Update required: $currentVersion < $minimumVersion');
        }
      } else {
        if (kDebugMode) {
          print('✅ Version is up to date');
        }
      }

      return isOutdated;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking version: $e');
      }
      return false; // Allow app to continue on error
    }
  }

  /// Compare two version strings (e.g., "1.0.0" vs "1.2.3")
  /// Returns:
  ///   -1 if version1 < version2
  ///    0 if version1 == version2
  ///    1 if version1 > version2
  static int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();

    // Pad with zeros if needed
    while (v1Parts.length < 3) {
      v1Parts.add(0);
    }
    while (v2Parts.length < 3) {
      v2Parts.add(0);
    }

    for (int i = 0; i < 3; i++) {
      if (v1Parts[i] < v2Parts[i]) return -1;
      if (v1Parts[i] > v2Parts[i]) return 1;
    }

    return 0;
  }

  static Future<String> getMinimumVersion() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('latest-version')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return '0.0.0';

      final doc = snapshot.docs.first;
      return doc.data()['minimum-version'] as String? ?? '0.0.0';
    } catch (e) {
      return '0.0.0';
    }
  }
}
