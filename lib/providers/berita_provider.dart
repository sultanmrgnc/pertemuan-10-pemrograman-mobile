import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/berita_model.dart';
import '../services/api_service.dart';

class BeritaProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Berita> _beritaList = [];
  Berita? _selectedBerita;
  bool _isLoading = false;
  String? _error;

  List<Berita> get beritaList => _beritaList;
  Berita? get selectedBerita => _selectedBerita;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Mengambil semua berita
  Future<void> fetchBerita() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _beritaList = await _apiService.getBerita();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Mengambil detail berita berdasarkan ID
  Future<void> fetchBeritaById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedBerita = await _apiService.getBeritaById(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Membuat berita baru
  Future<void> createBerita(Berita berita) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.createBerita(berita);
      await fetchBerita(); // Refresh list setelah menambah
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Memperbarui berita
  Future<void> updateBerita(int id, Berita berita) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.updateBerita(id, berita);
      await fetchBerita(); // Refresh list setelah update
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Menghapus berita
  Future<void> deleteBerita(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteBerita(id);
      _beritaList.removeWhere((berita) => berita.id == id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Upload gambar dan dapatkan nama file
  Future<String> uploadGambar(File imageFile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fileName = await _apiService.uploadGambar(imageFile);
      _isLoading = false;
      notifyListeners();
      return fileName;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Gagal upload gambar: $e');
    }
  }
}
