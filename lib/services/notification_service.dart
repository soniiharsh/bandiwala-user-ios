import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('📩 Background message: ${message.notification?.title}');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('✅ Notification permission granted');
      }
    } else {
      if (kDebugMode) {
        print('❌ Notification permission denied');
      }
      return;
    }

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'admin_channel',
      'Admin Notifications',
      description: 'Notifications from admin',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Subscribe to admin topic
    await subscribeToAdminTopic();

    // Get FCM token
    String? token = await _messaging.getToken();
    if (kDebugMode) {
      print('📱 FCM Token: $token');
    }

    _initialized = true;
  }

  Future<void> subscribeToAdminTopic() async {
    try {
      await _messaging.subscribeToTopic('admin');
      if (kDebugMode) {
        print('✅ Subscribed to admin topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to subscribe to admin topic: $e');
      }
    }
  }

  Future<void> unsubscribeFromAdminTopic() async {
    try {
      await _messaging.unsubscribeFromTopic('admin');
      if (kDebugMode) {
        print('✅ Unsubscribed from admin topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to unsubscribe from admin topic: $e');
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('📩 Foreground message: ${message.notification?.title}');
    }

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'admin_channel',
            'Admin Notifications',
            channelDescription: 'Notifications from admin',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('📩 Notification tapped: ${message.notification?.title}');
    }
    // Handle navigation based on message data
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('📩 Local notification tapped: ${response.payload}');
    }
    // Handle navigation
  }

  // ── FCM Token Management ──────────────────────────────────────────────────

  Future<void> updateCustomerToken(String phone) async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        // Normalize: always remove +91 for document ID
        final phoneWithoutCode = phone.replaceAll('+91', '');
        
        await FirebaseFirestore.instance
            .collection('customers')
            .doc(phoneWithoutCode)
            .set({
          'FCMToken': token,
        }, SetOptions(merge: true));
        
        if (kDebugMode) {
          print('✅ FCM token updated for customer: $phoneWithoutCode');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating customer FCM token: $e');
      }
    }
  }

  Future<void> deleteCustomerToken(String phone) async {
    try {
      // Normalize: always remove +91 for document ID
      final phoneWithoutCode = phone.replaceAll('+91', '');
      
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(phoneWithoutCode)
          .update({
        'FCMToken': FieldValue.delete(),
      });
      
      if (kDebugMode) {
        print('✅ FCM token deleted for customer: $phoneWithoutCode');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting customer FCM token: $e');
      }
    }
  }
}
