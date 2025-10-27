class PdfFile {
  final int id;
  final String title;
  final String downloadDate;
  final String author;
  final String coverImage;
  final int size;
  final String path;

  PdfFile({
    required this.id,
    required this.title,
    required this.downloadDate,
    required this.author,
    required this.coverImage,
    required this.size,
    required this.path,
  });

  factory PdfFile.fromMap(Map<String, dynamic> map) {
    return PdfFile(
      id: map['id'],
      title: map['title'],
      downloadDate: map['download_date'],
      author: map['author'],
      coverImage: map['cover_image'],
      size: map['size'],
      path: map['path'],
    );
  }
}
