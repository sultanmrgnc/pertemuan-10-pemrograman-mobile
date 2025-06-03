import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/berita_provider.dart';
import 'screens/berita_list_screen.dart';
import 'screens/berita_detail_screen.dart';
import 'screens/tambah_edit_berita_screen.dart';
import 'screens/notification_screen.dart';
import 'services/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi service notifikasi
  final notificationService = NotificationService();

  runApp(
    MultiProvider(
      providers: [
        Provider<NotificationService>.value(value: notificationService),
        ChangeNotifierProvider(create: (context) => BeritaProvider()),
      ],
      child: const MyApp(),
    ),
  );

  // Mulai polling notifikasi
  notificationService.startPollingForNotifications();
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portal Berita',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => const NotificationAwareHomePage(),
        '/notifications': (context) => const NotificationScreen(),
      },
      // Gunakan onGenerateRoute untuk route yang membutuhkan parameter
      onGenerateRoute: (settings) {
        if (settings.name == '/berita/detail') {
          final beritaId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => BeritaDetailScreen(id: beritaId),
          );
        } else if (settings.name == '/berita/form') {
          // Menghandle jika ada parameter untuk edit berita
          final args = settings.arguments;
          if (args != null && args is Map<String, dynamic>) {
            return MaterialPageRoute(
              builder: (context) => TambahEditBeritaScreen(
                berita: args['berita'],
                isEditing: args['isEditing'] ?? false,
              ),
            );
          }
          // Jika tidak ada parameter, buat berita baru
          return MaterialPageRoute(
            builder: (context) => const TambahEditBeritaScreen(),
          );
        }
        // Fallback untuk route yang tidak dikenal
        return MaterialPageRoute(
          builder: (context) => const NotificationAwareHomePage(),
        );
      },
      initialRoute: '/',
    );
  }
}

// Wrapper untuk menambahkan tombol notifikasi pada layar utama
class NotificationAwareHomePage extends StatefulWidget {
  const NotificationAwareHomePage({Key? key}) : super(key: key);

  @override
  State<NotificationAwareHomePage> createState() =>
      _NotificationAwareHomePageState();
}

class _NotificationAwareHomePageState extends State<NotificationAwareHomePage> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();

    // Dapatkan token perangkat dan inisialisasi notifikasi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationService =
          Provider.of<NotificationService>(context, listen: false);
      notificationService.getOrGenerateDeviceToken();

      // Periksa notifikasi yang belum dibaca
      _refreshUnreadCount();
    });
  }

  // Memperbarui counter notifikasi yang belum dibaca
  Future<void> _refreshUnreadCount() async {
    try {
      final notificationService =
          Provider.of<NotificationService>(context, listen: false);
      final unreadNotifications =
          await notificationService.getUnreadNotifications();

      setState(() {
        _unreadCount = unreadNotifications.length;
      });
    } catch (e) {
      print('Error refreshing unread count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Tampilan utama dengan BeritaListScreen
          const BeritaListScreen(),

          // Tombol notifikasi yang diposisikan di kanan atas
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            right: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade700.withOpacity(0.4),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Material(
                color: Colors.transparent,
                child: Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                        size: 28,
                      ),
                      tooltip: 'Notifikasi',
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/notifications');
                        // Refresh counter setelah kembali dari layar notifikasi
                        _refreshUnreadCount();
                      },
                    ),
                    if (_unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
