class Berita {
  final int id;
  final String judul;
  final String isi;
  final String? gambar;
  final String? createdAt;
  final String? updatedAt;

  Berita({
    required this.id,
    required this.judul,
    required this.isi,
    this.gambar,
    this.createdAt,
    this.updatedAt,
  });

  factory Berita.fromJson(Map<String, dynamic> json) {
    // Handle ID yang bisa berupa string atau integer
    int beritaId;
    if (json['id'] is String) {
      beritaId = int.parse(json['id']);
    } else if (json['id'] is int) {
      beritaId = json['id'];
    } else {
      beritaId = 0; // Default value jika null atau tipe lain
    }

    return Berita(
      id: beritaId,
      judul: json['judul']?.toString() ?? '',
      isi: json['isi']?.toString() ?? '',
      gambar: json['gambar']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'judul': judul,
      'isi': isi,
    };

    // Hanya kirim gambar jika ada nilainya
    if (gambar != null && gambar!.isNotEmpty) {
      data['gambar'] = gambar;
    }

    // ID hanya dikirim jika bukan 0 (untuk update)
    if (id > 0) {
      data['id'] = id;
    }

    return data;
  }
}
