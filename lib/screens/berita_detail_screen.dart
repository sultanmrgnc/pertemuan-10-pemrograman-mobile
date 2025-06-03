import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import '../providers/berita_provider.dart';
import '../services/api_service.dart';
import 'tambah_edit_berita_screen.dart';

class BeritaDetailScreen extends StatefulWidget {
  final int id;

  const BeritaDetailScreen({Key? key, required this.id}) : super(key: key);

  @override
  _BeritaDetailScreenState createState() => _BeritaDetailScreenState();
}

class _BeritaDetailScreenState extends State<BeritaDetailScreen> {
  late ScrollController _scrollController;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<BeritaProvider>(
        context,
        listen: false,
      ).fetchBeritaById(widget.id),
    );

    _scrollController = ScrollController();
    _scrollController.addListener(_listenToScrollChange);
  }

  void _listenToScrollChange() {
    if (_scrollController.offset > 150 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 150 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_listenToScrollChange);
    _scrollController.dispose();
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
        Navigator.of(context).pop(); // Kembali ke layar daftar berita
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

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return Scaffold(
      backgroundColor: Colors.white,
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
                  Icon(Icons.error_outline, size: 50, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'Terjadi kesalahan:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      provider.error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => provider.fetchBeritaById(widget.id),
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

          final berita = provider.selectedBerita;
          if (berita == null) {
            return const Center(child: Text('Berita tidak ditemukan'));
          }

          // Format tanggal
          String formattedDate = '';
          if (berita.createdAt != null && berita.createdAt!.isNotEmpty) {
            try {
              final date = DateTime.parse(berita.createdAt!);
              formattedDate = DateFormat('dd MMMM yyyy', 'id_ID').format(date);
            } catch (e) {
              formattedDate = berita.createdAt!.substring(0, 10);
            }
          }

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: 250.0,
                floating: false,
                pinned: true,
                stretch: true,
                backgroundColor:
                    _isScrolled ? Colors.white : Colors.transparent,
                foregroundColor: _isScrolled ? Colors.blue : Colors.white,
                elevation: _isScrolled ? 4 : 0,
                title: _isScrolled
                    ? Text(berita.judul,
                        maxLines: 1, overflow: TextOverflow.ellipsis)
                    : null,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: _isScrolled ? Colors.blue : Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  // Edit button
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: _isScrolled ? Colors.blue : Colors.white,
                    ),
                    onPressed: () async {
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
                        // Refresh berita setelah diedit
                        Provider.of<BeritaProvider>(context, listen: false)
                            .fetchBeritaById(widget.id);
                      }
                    },
                    tooltip: 'Edit Berita',
                  ),
                  // Delete button
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: _isScrolled ? Colors.blue : Colors.white,
                    ),
                    onPressed: () => _konfirmasiHapus(context, berita.id),
                    tooltip: 'Hapus Berita',
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: ShaderMask(
                    shaderCallback: (rect) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ).createShader(
                          Rect.fromLTRB(0, 150, rect.width, rect.height));
                    },
                    blendMode: BlendMode.darken,
                    child: berita.gambar != null && berita.gambar!.isNotEmpty
                        ? Image.network(
                            '${apiService.uploadBaseUrl}/${berita.gambar}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading image: $error');
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.blue.shade200,
                                      Colors.blue.shade600,
                                    ],
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.white70,
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.blue.shade300,
                                  Colors.blue.shade700,
                                ],
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.article,
                                size: 50,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Judul
                        Text(
                          berita.judul,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Metadata (tanggal)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                formattedDate.isNotEmpty
                                    ? formattedDate
                                    : 'Tanggal tidak tersedia',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Divider
                        Divider(color: Colors.grey[300], height: 1),
                        const SizedBox(height: 24),

                        // Konten berita
                        Html(
                          data: berita.isi,
                          style: {
                            "body": Style(
                              fontSize: FontSize(16),
                              lineHeight: LineHeight(1.8),
                              color: const Color(0xFF4A5568),
                              fontFamily: "Roboto",
                            ),
                            "h1, h2, h3, h4, h5, h6": Style(
                              color: const Color(0xFF2D3748),
                              fontWeight: FontWeight.bold,
                              margin: Margins.only(top: 16, bottom: 8),
                            ),
                            "p": Style(
                              margin: Margins.only(bottom: 16),
                            ),
                            "a": Style(
                              color: Colors.blue,
                              textDecoration: TextDecoration.none,
                            ),
                          },
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}
