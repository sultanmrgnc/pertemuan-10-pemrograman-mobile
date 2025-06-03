import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart' as app_notification;
import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  late Future<List<app_notification.Notification>> _notificationsFuture;
  late TabController _tabController;
  int _unreadCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshNotifications() {
    setState(() {
      _isLoading = true;
      _notificationsFuture = _notificationService.getNotifications();
    });

    // Hitung notifikasi yang belum dibaca
    _notificationService.getUnreadNotifications().then((unreadNotifications) {
      setState(() {
        _unreadCount = unreadNotifications.length;
        _isLoading = false;
      });
    });
  }

  // Menampilkan icon yang berbeda berdasarkan tipe notifikasi
  IconData _getIconData(String type) {
    switch (type) {
      case 'berita_baru':
        return Icons.article_rounded;
      case 'update':
        return Icons.sync_rounded;
      case 'info':
        return Icons.info_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  // Memformat tanggal ke format lokal Indonesia
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return "Waktu tidak diketahui";
    }

    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor:
                  innerBoxIsScrolled ? Colors.blue : Colors.transparent,
              elevation: innerBoxIsScrolled ? 4 : 0,
              stretch: true,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                title: const Text(
                  'Notifikasi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 2,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1565C0),
                        Color(0xFF1976D2),
                        Color(0xFF2196F3),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                if (_unreadCount > 0 && !_isLoading)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      tooltip: 'Tandai semua dibaca',
                      icon: const Icon(Icons.mark_email_read,
                          color: Colors.white),
                      onPressed: () async {
                        setState(() {
                          _isLoading = true;
                        });
                        await _notificationService.markAllAsRead();
                        _refreshNotifications();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'Semua notifikasi ditandai telah dibaca'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ),
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _refreshNotifications,
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: Colors.blue.shade700,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withOpacity(0.7),
                    tabs: [
                      const Tab(
                        text: 'Semua',
                        icon: Icon(Icons.all_inbox),
                      ),
                      Tab(
                        text: 'Belum Dibaca',
                        icon: Badge(
                          isLabelVisible: _unreadCount > 0,
                          label: Text(
                            _unreadCount > 9 ? '9+' : '$_unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: Colors.red,
                          child: const Icon(Icons.mark_email_unread),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  // Tab semua notifikasi
                  _buildNotificationList(false),
                  // Tab notifikasi belum dibaca
                  _buildNotificationList(true),
                ],
              ),
      ),
    );
  }

  Widget _buildNotificationList(bool unreadOnly) {
    return RefreshIndicator(
      onRefresh: () async {
        _refreshNotifications();
      },
      child: FutureBuilder<List<app_notification.Notification>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _refreshNotifications,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada notifikasi ${unreadOnly ? 'belum dibaca' : ''}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          } else {
            final allNotifications = snapshot.data!;
            final notifications = unreadOnly
                ? allNotifications.where((n) => !n.isRead).toList()
                : allNotifications;

            if (notifications.isEmpty && unreadOnly) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.mark_email_read,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Semua notifikasi sudah dibaca',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: notifications.length,
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              itemBuilder: (context, index) {
                final notification = notifications[index];

                // Warna gradient berdasarkan tipe notifikasi
                List<Color> cardGradient;
                Color iconColor;

                switch (notification.type) {
                  case 'berita_baru':
                    cardGradient = notification.isRead
                        ? [Colors.grey.shade100, Colors.grey.shade200]
                        : [Colors.blue.shade50, Colors.blue.shade100];
                    iconColor = notification.isRead
                        ? Colors.blue.shade300
                        : Colors.blue;
                    break;
                  case 'update':
                    cardGradient = notification.isRead
                        ? [Colors.grey.shade100, Colors.grey.shade200]
                        : [Colors.green.shade50, Colors.green.shade100];
                    iconColor = notification.isRead
                        ? Colors.green.shade300
                        : Colors.green;
                    break;
                  case 'info':
                    cardGradient = notification.isRead
                        ? [Colors.grey.shade100, Colors.grey.shade200]
                        : [Colors.amber.shade50, Colors.amber.shade100];
                    iconColor = notification.isRead
                        ? Colors.amber.shade300
                        : Colors.amber;
                    break;
                  default:
                    cardGradient = notification.isRead
                        ? [Colors.grey.shade100, Colors.grey.shade200]
                        : [Colors.purple.shade50, Colors.purple.shade100];
                    iconColor = notification.isRead
                        ? Colors.purple.shade300
                        : Colors.purple;
                }

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Card(
                    elevation: notification.isRead ? 1 : 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: cardGradient,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          if (!notification.isRead) {
                            await _notificationService
                                .markAsRead(notification.id);
                            _refreshNotifications();
                          }

                          // Navigasi ke berita jika ada target_id
                          if (notification.targetId != null &&
                              (notification.type == 'berita_baru' ||
                                  notification.type == 'update')) {
                            Navigator.pushNamed(
                              context,
                              '/berita/detail',
                              arguments: notification.targetId,
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: iconColor.withOpacity(
                                      notification.isRead ? 0.2 : 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getIconData(notification.type),
                                  color: iconColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notification.title,
                                            style: TextStyle(
                                              fontWeight: notification.isRead
                                                  ? FontWeight.normal
                                                  : FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        if (!notification.isRead)
                                          Container(
                                            width: 10,
                                            height: 10,
                                            margin:
                                                const EdgeInsets.only(left: 8),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      notification.message,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            _formatDate(notification.createdAt),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
