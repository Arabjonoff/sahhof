import 'package:sahhof/src/model/audio/audio_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../model/pdf/pdf_file.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();
  static Database? _db;
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'audio_books.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
      CREATE TABLE audio_books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        format TEXT NOT NULL,
        description TEXT NOT NULL,
        cover_image TEXT NOT NULL,
        audio_duration INTEGER NOT NULL,
        author_name TEXT NOT NULL,
        download_date TEXT NOT NULL,
        total_size INTEGER NOT NULL
      )
    ''');
        await db.execute('''
      CREATE TABLE audio_parts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER,
        part_id INTEGER,
        name TEXT,
        path TEXT,
        url TEXT,
        size INTEGER,
        is_downloaded INTEGER DEFAULT 0,
        download_progress REAL DEFAULT 0.0,
        FOREIGN KEY(book_id) REFERENCES audio_books(id) ON DELETE CASCADE
      )
    ''');
        await db.execute('''
          CREATE TABLE pdf_files (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            download_date TEXT NOT NULL,
            author TEXT NOT NULL,
            cover_image TEXT NOT NULL,
            size INTEGER,
            path TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_book_id ON audio_parts(book_id)');
        await db.execute('CREATE INDEX idx_downloaded_at ON downloaded_books(downloaded_at)');
        await db.execute('CREATE INDEX idx_last_played ON downloaded_books(last_played_at)');
      },
    );

  }

  Future<int> insertPdf(String title, String downloadDate, String author, String coverImage, int size, String path) async {
    final db = await database;
    return await db.insert('pdf_files',
        {
      'title': title,
      'download_date':downloadDate,
      'author':author,
      'cover_image':coverImage,
      'size':size,
      'path':path
    }
    );
  }
  Future<List<PdfFile>> getPdfFiles() async {
    final db = await database;
    final result = await db.query('pdf_files', orderBy: 'id DESC');
    return result.map((e) => PdfFile.fromMap(e)).toList();
  }
  Future<void> deletePdf(int id) async {
    final db = await database;
    await db.delete('pdf_files', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<DownloadedBookModel>> getAllDownloadedBooks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'downloaded_books',
      orderBy: 'downloaded_at DESC',
    );
    return maps.map((map) => DownloadedBookModel.fromMap(map)).toList();
  }

  // Get single book
  Future<DownloadedBookModel?> getDownloadedBook(int bookId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'downloaded_books',
      where: 'book_id = ?',
      whereArgs: [bookId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return DownloadedBookModel.fromMap(maps.first);
  }

  // Insert book
  Future<int> insertBook({
    required int bookId,
    required String title,
    required String format,
    required String description,
    required String coverImage,
    required int audioDuration,
    required String authorName,
    required int totalSize,
  }) async {
    final db = await database;
    return await db.insert(
      'downloaded_books',
      {
        'book_id': bookId,
        'title': title,
        'format': format,
        'description': description,
        'cover_image': coverImage,
        'audio_duration': audioDuration,
        'author_name': authorName,
        'total_size': totalSize,
        'downloaded_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Delete book
  Future<bool> deleteBook(int bookId) async {
    try {
      final db = await database;

      // Delete audio parts first
      await db.delete(
        'audio_parts',
        where: 'book_id IN (SELECT id FROM downloaded_books WHERE book_id = ?)',
        whereArgs: [bookId],
      );

      // Delete book
      final count = await db.delete(
        'downloaded_books',
        where: 'book_id = ?',
        whereArgs: [bookId],
      );

      return count > 0;
    } catch (e) {
      print('Error deleting book: $e');
      return false;
    }
  }

  // Check if book is downloaded
  Future<bool> isBookDownloaded(int bookId) async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM downloaded_books WHERE book_id = ?',
        [bookId],
      ),
    );
    return count != null && count > 0;
  }

  // ============= AUDIO PARTS OPERATIONS =============

  // Get audio parts for a book
  Future<List<AudioPartModel>> getAudioParts(int bookId) async {
    final db = await database;

    // Get internal book ID first
    final bookResult = await db.query(
      'downloaded_books',
      columns: ['id'],
      where: 'book_id = ?',
      whereArgs: [bookId],
      limit: 1,
    );

    if (bookResult.isEmpty) return [];

    final internalBookId = bookResult.first['id'] as int;

    final List<Map<String, dynamic>> maps = await db.query(
      'audio_parts',
      where: 'book_id = ?',
      whereArgs: [internalBookId],
      orderBy: 'part_id ASC',
    );

    return maps.map((map) => AudioPartModel.fromMap(map)).toList();
  }

  // Insert audio part
  Future<int> insertAudioPart({
    required int bookId,
    required int partId,
    required String name,
    required String path,
    required String url,
    required int size,
  }) async {
    final db = await database;
    return await db.insert(
      'audio_parts',
      {
        'book_id': bookId,
        'part_id': partId,
        'name': name,
        'path': path,
        'url': url,
        'size': size,
        'downloaded_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ============= SEARCH & FILTER =============

  // Search downloaded books
  Future<List<DownloadedBookModel>> searchDownloadedBooks(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'downloaded_books',
      where: 'title LIKE ? OR author_name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'downloaded_at DESC',
    );
    return maps.map((map) => DownloadedBookModel.fromMap(map)).toList();
  }

  // Get books by author
  Future<List<DownloadedBookModel>> getBooksByAuthor(String authorName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'downloaded_books',
      where: 'author_name = ?',
      whereArgs: [authorName],
      orderBy: 'downloaded_at DESC',
    );
    return maps.map((map) => DownloadedBookModel.fromMap(map)).toList();
  }

  // ============= STATISTICS =============

  // Get total downloaded size
  Future<int> getTotalDownloadedSize() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(total_size) as total FROM downloaded_books',
    );
    return result.first['total'] as int? ?? 0;
  }

  // Get download count
  Future<int> getDownloadedBooksCount() async {
    final db = await database;
    return Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM downloaded_books'),
    ) ?? 0;
  }

  // Get download progress (for incomplete downloads)
  Future<double> getDownloadProgress(int bookId) async {
    final db = await database;

    final bookResult = await db.query(
      'downloaded_books',
      columns: ['id', 'total_size'],
      where: 'book_id = ?',
      whereArgs: [bookId],
      limit: 1,
    );

    if (bookResult.isEmpty) return 0.0;

    final internalBookId = bookResult.first['id'] as int;
    final totalSize = bookResult.first['total_size'] as int;

    final partsResult = await db.rawQuery(
      'SELECT SUM(size) as downloaded FROM audio_parts WHERE book_id = ?',
      [internalBookId],
    );

    final downloadedSize = partsResult.first['downloaded'] as int? ?? 0;

    if (totalSize == 0) return 0.0;
    return downloadedSize / totalSize;
  }

  // ============= PLAYBACK TRACKING =============

  // Update last played position
  Future<void> updateLastPlayedPosition(int bookId, int position) async {
    final db = await database;
    await db.update(
      'downloaded_books',
      {
        'last_played_position': position,
        'last_played_at': DateTime.now().toIso8601String(),
      },
      where: 'book_id = ?',
      whereArgs: [bookId],
    );
  }

  // Get recently played books
  Future<List<DownloadedBookModel>> getRecentlyPlayedBooks({int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'downloaded_books',
      where: 'last_played_at IS NOT NULL',
      orderBy: 'last_played_at DESC',
      limit: limit,
    );
    return maps.map((map) => DownloadedBookModel.fromMap(map)).toList();
  }

  // ============= CLEANUP =============

  // Clear all data
  Future<void> clearAllDownloads() async {
    final db = await database;
    await db.delete('audio_parts');
    await db.delete('downloaded_books');
  }

}
