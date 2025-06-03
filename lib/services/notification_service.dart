import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';

class NotificationService {
  // URL API sesuai dengan server yang sedang berjalan (sama dengan ApiService)
  final String baseUrl = 'http://localhost:8080/api';
  // Untuk emulator, gunakan: final String baseUrl = 'http://10.0.2.2:8081/api';
  // Untuk perangkat fisik: final String baseUrl = 'http://192.168.1.X:8081/api';

  // Plugin notifikasi lokal
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Constructor
  NotificationService() {
    _initializeNotifications();
  }

  // Initialize plugin notifikasi
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Implementasi navigasi ke halaman detail notifikasi
        print('Notifikasi diklik: ${details.payload}');
      },
    );
  }

  // Mendaftarkan device token ke server
  Future<bool> registerDeviceToken(String deviceToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/device/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'device_token': deviceToken}),
      );

      if (response.statusCode == 200) {
        // Simpan device token ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('device_token', deviceToken);
        return true;
      } else {
        print('Gagal mendaftarkan device token: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error saat mendaftarkan device token: $e');
      return false;
    }
  }

  // Generate random device token (untuk simulasi)
  Future<String> getOrGenerateDeviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceToken = prefs.getString('device_token');

    if (deviceToken == null || deviceToken.isEmpty) {
      // Buat device token acak
      deviceToken = 'flutter_device_${DateTime.now().millisecondsSinceEpoch}';
      await registerDeviceToken(deviceToken);
    }

    return deviceToken;
  }

  // Mendapatkan semua notifikasi
  Future<List<Notification>> getNotifications() async {
    try {
      final deviceToken = await getOrGenerateDeviceToken();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications?device_token=$deviceToken'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => Notification.fromJson(data)).toList();
      } else {
        throw Exception('Gagal memuat notifikasi: ${response.statusCode}');
      }
    } catch (e) {
      print('Error memuat notifikasi: $e');
      throw Exception('Tidak dapat memuat notifikasi: $e');
    }
  }

  // Mendapatkan notifikasi yang belum dibaca
  Future<List<Notification>> getUnreadNotifications() async {
    try {
      final deviceToken = await getOrGenerateDeviceToken();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread?device_token=$deviceToken'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => Notification.fromJson(data)).toList();
      } else {
        throw Exception('Gagal memuat notifikasi: ${response.statusCode}');
      }
    } catch (e) {
      print('Error memuat notifikasi: $e');
      throw Exception('Tidak dapat memuat notifikasi: $e');
    }
  }

  // Menandai notifikasi sebagai telah dibaca
  Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error saat menandai notifikasi sebagai dibaca: $e');
      return false;
    }
  }

  // Menandai semua notifikasi sebagai telah dibaca
  Future<bool> markAllAsRead() async {
    try {
      final deviceToken = await getOrGenerateDeviceToken();
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/read-all?device_token=$deviceToken'),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error saat menandai semua notifikasi sebagai dibaca: $e');
      return false;
    }
  }

  // Menampilkan notifikasi lokal
  Future<void> showLocalNotification(Notification notification) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'berita_channel_id',
      'Berita Channel',
      channelDescription: 'Notifikasi untuk aplikasi berita',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      notification.id,
      notification.title,
      notification.message,
      platformChannelSpecifics,
      payload: json.encode({
        'id': notification.id,
        'type': notification.type,
        'target_id': notification.targetId,
      }),
    );
  }

  // Polling untuk notifikasi baru
  void startPollingForNotifications() async {
    // Memeriksa notifikasi baru setiap 30 detik
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));

      try {
        final unreadNotifications = await getUnreadNotifications();
        for (var notification in unreadNotifications) {
          showLocalNotification(notification);
        }
      } catch (e) {
        print('Error saat polling notifikasi: $e');
      }

      // Terus melakukan polling
      return true;
    });
  }
}
