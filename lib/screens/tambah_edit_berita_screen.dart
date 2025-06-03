import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/berita_model.dart';
import '../providers/berita_provider.dart';
import '../services/api_service.dart';

class TambahEditBeritaScreen extends StatefulWidget {
  final Berita? berita;
  final bool isEditing;

  const TambahEditBeritaScreen({
    Key? key,
    this.berita,
    this.isEditing = false,
  }) : super(key: key);

  @override
  _TambahEditBeritaScreenState createState() => _TambahEditBeritaScreenState();
}

class _TambahEditBeritaScreenState extends State<TambahEditBeritaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _isiController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  bool _isValidating = false;
  String? _existingImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.berita != null) {
      _judulController.text = widget.berita!.judul;
      _isiController.text = widget.berita!.isi;
      if (widget.berita!.gambar != null && widget.berita!.gambar!.isNotEmpty) {
        _existingImage = widget.berita!.gambar;
      }
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _isiController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          print('Image selected: ${pickedFile.path}');
        });
      } else {
        print('No image selected.');
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih gambar: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _existingImage = null;
    });
  }

  Future<void> _simpanBerita() async {
    if (_isValidating) return;

    setState(() {
      _isValidating = true;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isValidating = false;
      });
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
      _isValidating = false;
    });

    final apiService = ApiService();
    String? gambarNama;

    try {
      // Upload gambar jika ada
      if (_imageFile != null) {
        // Periksa apakah file ada
        if (await _imageFile!.exists()) {
          final fileSize = await _imageFile!.length();
          print('File exists, size: $fileSize bytes');

          try {
            gambarNama = await apiService.uploadGambar(_imageFile!);
            print('Gambar berhasil diupload: $gambarNama');
          } catch (e) {
            print('Gagal upload gambar: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gambar gagal diupload: ${e.toString()}'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
            // Lanjutkan tanpa gambar
          }
        } else {
          print('File does not exist!');
        }
      }

      final berita = Berita(
        id: widget.isEditing ? widget.berita!.id : 0,
        judul: _judulController.text,
        isi: _isiController.text,
        gambar: gambarNama ?? _existingImage,
      );

      if (widget.isEditing) {
        await Provider.of<BeritaProvider>(context, listen: false)
            .updateBerita(widget.berita!.id, berita);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Berita berhasil diperbarui'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        await Provider.of<BeritaProvider>(context, listen: false)
            .createBerita(berita);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Berita berhasil ditambahkan'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      print('Error saving news: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan berita: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Berita' : 'Tambah Berita'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Menyimpan berita...'),
                ],
              ),
            )
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Container(
                color: Colors.grey[50],
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Card untuk gambar
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Gambar Berita',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Preview gambar
                              Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: _imageFile != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          _imageFile!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : _existingImage != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(
                                              '${apiService.uploadBaseUrl}/$_existingImage',
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                print(
                                                    'Error loading image: $error');
                                                return const Center(
                                                  child: Icon(
                                                    Icons.image_not_supported,
                                                    size: 50,
                                                    color: Colors.grey,
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                        : const Center(
                                            child: Icon(
                                              Icons.image,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
                                          ),
                              ),

                              const SizedBox(height: 16),

                              // Tombol-tombol gambar
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _pickImage,
                                      icon: const Icon(Icons.photo_library),
                                      label: const Text('Pilih Gambar'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  if (_imageFile != null ||
                                      _existingImage != null)
                                    ElevatedButton.icon(
                                      onPressed: _removeImage,
                                      icon: const Icon(Icons.delete),
                                      label: const Text('Hapus'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Card untuk form
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Input judul
                              TextFormField(
                                controller: _judulController,
                                decoration: InputDecoration(
                                  labelText: 'Judul Berita',
                                  hintText: 'Masukkan judul berita',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.title),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Judul tidak boleh kosong';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              // Input isi
                              TextFormField(
                                controller: _isiController,
                                decoration: InputDecoration(
                                  labelText: 'Isi Berita',
                                  hintText:
                                      'Masukkan isi berita (HTML diperbolehkan)',
                                  alignLabelWithHint: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.article),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                maxLines: 10,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Isi berita tidak boleh kosong';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Tombol simpan
                      ElevatedButton(
                        onPressed: _simpanBerita,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          widget.isEditing
                              ? 'PERBARUI BERITA'
                              : 'SIMPAN BERITA',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
