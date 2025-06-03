import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/berita_model.dart';

class ApiService {
  // URL API CodeIgniter yang sesuai dengan server yang sedang berjalan

  // Pilih salah satu URL di bawah ini sesuai dengan jenis perangkat yang digunakan:

  // 1. Desktop/Browser Web: Gunakan localhost
  final String baseUrl = 'http://localhost:8080/api';
  final String uploadBaseUrl = 'http://localhost:8080/uploads';

  // 2. Emulator Android: Gunakan 10.0.2.2 (pengganti localhost)
  // final String baseUrl = 'http://10.0.2.2:8081/api';
  // final String uploadBaseUrl = 'http://10.0.2.2:8081/uploads';

  // 3. Perangkat Fisik atau Emulator yang terhubung ke jaringan yang sama:
  // Ganti dengan IP Address komputer server Anda
  // final String baseUrl = 'http://192.168.1.X:8081/api';
  // final String uploadBaseUrl = 'http://192.168.1.X:8081/uploads';

  Future<List<Berita>> getBerita() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/berita'));
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => Berita.fromJson(data)).toList();
      } else {
        throw Exception('Gagal memuat berita: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting berita: $e');
      throw Exception('Tidak dapat memuat berita: $e');
    }
  }

  Future<Berita> getBeritaById(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/berita/$id'));
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return Berita.fromJson(json.decode(response.body));
      } else {
        throw Exception(
            'Gagal memuat berita dengan ID $id: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting berita by id: $e');
      throw Exception('Tidak dapat memuat berita: $e');
    }
  }

  Future<Map<String, dynamic>> createBerita(Berita berita) async {
    try {
      print('Calling createBerita with data: ${berita.toJson()}');

      final response = await http.post(
        Uri.parse('$baseUrl/berita'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(berita.toJson()),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('Berhasil membuat berita: $responseData');
        return responseData;
      } else {
        final errorMsg = response.body.isNotEmpty
            ? json.decode(response.body)['messages'] ??
                'Error code ${response.statusCode}'
            : 'Error code ${response.statusCode}';
        print('Gagal membuat berita: $errorMsg');
        throw Exception('Gagal membuat berita: $errorMsg');
      }
    } catch (e) {
      print('Error creating berita: $e');
      throw Exception('Tidak dapat membuat berita: $e');
    }
  }

  Future<Map<String, dynamic>> updateBerita(int id, Berita berita) async {
    try {
      print('Calling updateBerita for ID $id with data: ${berita.toJson()}');

      final response = await http.put(
        Uri.parse('$baseUrl/berita/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(berita.toJson()),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Berhasil memperbarui berita: $responseData');
        return responseData;
      } else {
        final errorMsg = response.body.isNotEmpty
            ? json.decode(response.body)['messages'] ??
                'Error code ${response.statusCode}'
            : 'Error code ${response.statusCode}';
        print('Gagal memperbarui berita: $errorMsg');
        throw Exception('Gagal memperbarui berita: $errorMsg');
      }
    } catch (e) {
      print('Error updating berita: $e');
      throw Exception('Tidak dapat memperbarui berita: $e');
    }
  }

  Future<Map<String, dynamic>> deleteBerita(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/berita/$id'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Gagal menghapus berita: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting berita: $e');
      throw Exception('Tidak dapat menghapus berita: $e');
    }
  }

  // Method untuk upload file gambar
  Future<String> uploadGambar(File imageFile) async {
    try {
      // Log path file untuk debugging
      print('Uploading file from path: ${imageFile.path}');
      print('File exists: ${imageFile.existsSync()}');
      print('File size: ${await imageFile.length()} bytes');

      // Buat request multipart
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));

      // Dapatkan filename dari path
      String fileName = imageFile.path.split('/').last;
      // Untuk Windows: perbaiki path jika berisi backslash
      fileName = fileName.replaceAll('\\', '/').split('/').last;

      String extension = fileName.split('.').last.toLowerCase();
      print('File name: $fileName, extension: $extension');

      // Validasi extension
      if (!['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
        throw Exception(
            'Format file tidak didukung. Gunakan PNG, JPEG, atau GIF.');
      }

      // Tambahkan file ke request dengan content-type yang sesuai
      var fileStream = http.ByteStream(imageFile.openRead());
      var fileLength = await imageFile.length();

      // Batasi ukuran file
      if (fileLength > 5 * 1024 * 1024) {
        // 5MB
        throw Exception('Ukuran file terlalu besar. Maksimal 5MB.');
      }

      var multipartFile = http.MultipartFile(
        'gambar', // Nama field harus sesuai dengan yang diharapkan backend
        fileStream,
        fileLength,
        filename: fileName,
        contentType: MediaType.parse('image/$extension'),
      );

      request.files.add(multipartFile);

      // Tambahkan headers tambahan jika diperlukan
      request.headers['Accept'] = 'application/json';

      // Log request yang dikirim
      print('Sending request to: ${request.url}');
      print('Request headers: ${request.headers}');
      print(
          'Files being sent: ${request.files.map((f) => f.filename).toList()}');

      // Kirim request dengan timeout
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout saat upload gambar. Coba lagi.');
        },
      );

      var response = await http.Response.fromStream(streamedResponse);

      // Log response
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return responseData['data']['file_name'];
        } else {
          throw Exception(
              'Upload gagal: ${responseData['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Gagal upload gambar: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Tidak dapat upload gambar: $e');
    }
  }
}
