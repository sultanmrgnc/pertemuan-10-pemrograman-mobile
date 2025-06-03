# Panduan Pengembangan Lokal Flutter Berita App

## Langkah-langkah Menjalankan di Lingkungan Lokal

### 1. Persiapkan Backend CodeIgniter 4

1. Import database dari file `db_news.sql`
2. Pastikan server CodeIgniter berjalan di port 8081:
   ```
   php spark serve
   ```
   Jika pesan "Failed to listen on localhost:8080" muncul, CodeIgniter akan otomatis mencoba port 8081.

### 2. Konfigurasi Flutter

1. Pastikan URL API di `lib/services/api_service.dart` menggunakan port yang benar:

   ```dart
   // URL API CodeIgniter yang sesuai dengan server yang sedang berjalan
   final String baseUrl = 'http://localhost:8081/api';
   ```

2. Pastikan URL gambar di `lib/widgets/berita_card.dart` dan `lib/screens/berita_detail_screen.dart` menggunakan port yang benar:
   ```dart
   'http://localhost:8081/uploads/${berita.gambar}'
   ```

### 3. Mengatasi Masalah CORS

Jika mengalami masalah CORS saat mengakses API dari aplikasi Flutter (terutama dari web atau desktop), ada beberapa solusi:

1. **Tambahkan header CORS di CodeIgniter**:
   Buat file `app/Filters/Cors.php`:

   ```php
   <?php namespace App\Filters;

   use CodeIgniter\HTTP\RequestInterface;
   use CodeIgniter\HTTP\ResponseInterface;
   use CodeIgniter\Filters\FilterInterface;

   class Cors implements FilterInterface
   {
       public function before(RequestInterface $request, $arguments = null)
       {
           header('Access-Control-Allow-Origin: *');
           header("Access-Control-Allow-Headers: X-API-KEY, Origin, X-Requested-With, Content-Type, Accept, Access-Control-Request-Method, Authorization");
           header("Access-Control-Allow-Methods: GET, POST, OPTIONS, PUT, DELETE");

           $method = $_SERVER['REQUEST_METHOD'];
           if ($method == "OPTIONS") {
               die();
           }
       }

       public function after(RequestInterface $request, ResponseInterface $response, $arguments = null)
       {
           // Do nothing
       }
   }
   ```

2. **Register filter di `app/Config/Filters.php`**:

   ```php
   public $aliases = [
       'cors' => \App\Filters\Cors::class,
   ];

   public $globals = [
       'before' => [
           'cors',
       ],
   ];
   ```

### 4. Debugging

Jika terjadi error saat mengakses API:

1. Periksa server CodeIgniter di terminal untuk melihat log error
2. Cek URL API dengan browser di `http://localhost:8081/api/berita`
3. Periksa format JSON yang diterima menggunakan DevTools Flutter

### 5. Pengembangan dengan Emulator

Jika menggunakan emulator Android, Anda mungkin perlu mengubah URL API dari `localhost` menjadi `10.0.2.2` (alamat loopback emulator Android):

```dart
// URL untuk emulator Android
final String baseUrl = 'http://10.0.2.2:8081/api';
```
