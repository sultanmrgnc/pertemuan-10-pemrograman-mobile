# Aplikasi Berita Flutter

Aplikasi portal berita dengan Flutter yang terintegrasi dengan backend CodeIgniter 4.

## Fitur

- Daftar berita
- Detail berita
- Pull to refresh
- Menampilkan gambar berita
- Tampilan responsif

## Persiapan

1. Pastikan Anda telah menginstal Flutter SDK (https://flutter.dev/docs/get-started/install)
2. Pastikan backend CodeIgniter 4 sudah berjalan
3. Pastikan database MySQL sudah dikonfigurasi dan diimpor

## Menjalankan Aplikasi

1. Import database MySQL dari file `db_news.sql` ke server MySQL Anda
2. Pastikan XAMPP/server web Anda berjalan
3. Buka direktori proyek CodeIgniter dan jalankan:
   ```
   php spark serve
   ```
4. Buka direktori Flutter dan jalankan:
   ```
   flutter pub get
   flutter run
   ```

## Konfigurasi API

- Jika API backend Anda tidak berjalan di `http://localhost/ci-berita/api`, ubah URL di file `lib/services/api_service.dart`

## Struktur Proyek

- **lib/models/**: Model data untuk aplikasi
- **lib/screens/**: Halaman UI aplikasi
- **lib/services/**: Layanan komunikasi dengan API
- **lib/providers/**: Provider state management
- **lib/widgets/**: Komponen UI yang dapat digunakan kembali
- **assets/**: Gambar dan font aplikasi
