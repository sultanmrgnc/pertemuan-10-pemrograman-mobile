import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/berita_model.dart';
import '../providers/berita_provider.dart';
import '../widgets/berita_card.dart';
import 'berita_detail_screen.dart';
import 'tambah_edit_berita_screen.dart';

class BeritaListScreen extends StatefulWidget {
  const BeritaListScreen({Key? key}) : super(key: key);

  @override
  _BeritaListScreenState createState() => _BeritaListScreenState();
}

class _BeritaListScreenState extends State<BeritaListScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _isScrolled = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<BeritaProvider>(context, listen: false).fetchBerita(),
    );

    _scrollController = ScrollController();
    _scrollController.addListener(_listenToScrollChange);

    // Inisialisasi animasi controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  void _listenToScrollChange() {
    if (_scrollController.offset > 0 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 0 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_listenToScrollChange);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Konfirmasi hapus berita
  Future<void> _konfirmasiHapus(BuildContext context, int id) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Anda yakin ingin menghapus berita ini?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('HAPUS'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await Provider.of<BeritaProvider>(context, listen: false)
            .deleteBerita(id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Berita berhasil dihapus'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus berita: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Navigasi ke layar tambah berita
  Future<void> _navigateToTambahBerita(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TambahEditBeritaScreen(),
      ),
    );

    if (result == true) {
      // Refresh daftar berita jika berhasil ditambahkan
      Provider.of<BeritaProvider>(context, listen: false).fetchBerita();
    }
  }

  // Navigasi ke layar edit berita
  Future<void> _navigateToEditBerita(
      BuildContext context, Berita berita) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TambahEditBeritaScreen(
          berita: berita,
          isEditing: true,
        ),
      ),
    );

    if (result == true) {
      // Refresh daftar berita jika berhasil diupdate
      Provider.of<BeritaProvider>(context, listen: false).fetchBerita();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 150,
                floating: false,
                pinned: true,
                elevation: _isScrolled ? 4 : 0,
                backgroundColor:
                    _isScrolled ? Colors.white : Colors.transparent,
                foregroundColor:
                    _isScrolled ? Colors.blue.shade700 : Colors.white,
                stretch: true,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding:
                      const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  title: Text(
                    'Portal Berita',
                    style: TextStyle(
                      fontSize: _isScrolled ? 20 : 26,
                      fontWeight: FontWeight.bold,
                      color: _isScrolled ? Colors.blue.shade700 : Colors.white,
                      shadows: _isScrolled
                          ? []
                          : const [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 2,
                                offset: Offset(1, 1),
                              ),
                            ],
                    ),
                  ),
                  centerTitle: false,
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
                    child: const Padding(
                      padding: EdgeInsets.only(left: 20, bottom: 70),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Berita Terkini by Sadit aditya',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ];
          },
          body: Consumer<BeritaProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Memuat berita...',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              if (provider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 50, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Terjadi kesalahan:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          provider.error!,
                          style: TextStyle(color: Colors.red[700]),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => provider.fetchBerita(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (provider.beritaList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 70,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada berita',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mulai tambahkan berita baru sekarang',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.blue, Colors.blueAccent],
                          ),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToTambahBerita(context),
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                          label: const Text(
                            'Tambah Berita Baru',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 15,
                            ),
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => provider.fetchBerita(),
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 12, bottom: 80),
                  itemCount: provider.beritaList.length,
                  itemBuilder: (context, index) {
                    final berita = provider.beritaList[index];
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Dismissible(
                          key: Key('berita-${berita.id}'),
                          background: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            await _konfirmasiHapus(context, berita.id);
                            return false;
                          },
                          child: BeritaCard(
                            berita: berita,
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      BeritaDetailScreen(id: berita.id),
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    const begin = Offset(1.0, 0.0);
                                    const end = Offset.zero;
                                    const curve = Curves.easeInOut;
                                    var tween = Tween(begin: begin, end: end)
                                        .chain(CurveTween(curve: curve));
                                    var offsetAnimation =
                                        animation.drive(tween);
                                    return SlideTransition(
                                        position: offsetAnimation,
                                        child: child);
                                  },
                                  transitionDuration:
                                      const Duration(milliseconds: 300),
                                ),
                              );
                            },
                            onEdit: () =>
                                _navigateToEditBerita(context, berita),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16, right: 10),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  spreadRadius: 3,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue, Colors.blueAccent],
              ),
            ),
            child: FloatingActionButton.extended(
              onPressed: () => _navigateToTambahBerita(context),
              backgroundColor: Colors.transparent,
              elevation: 0,
              icon: const Icon(
                Icons.add_circle_outline,
                color: Colors.white,
              ),
              label: const Text(
                'Berita Baru',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
