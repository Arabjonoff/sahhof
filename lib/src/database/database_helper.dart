import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/audio/audio_model.dart';
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
      version: 2, // Increased version for migration
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Main downloaded books table
    await db.execute('''
      CREATE TABLE downloaded_books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER UNIQUE NOT NULL,
        title TEXT NOT NULL,
        format TEXT,
        description TEXT,
        cover_image TEXT,
        audio_duration INTEGER DEFAULT 0,
        author_name TEXT,
        total_size INTEGER DEFAULT 0,
        downloaded_at TEXT,
        last_played_position INTEGER DEFAULT 0,
        last_played_at TEXT
      )
    ''');

    // Audio parts table
    await db.execute('''
      CREATE TABLE audio_parts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER NOT NULL,
        part_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        path TEXT NOT NULL,
        url TEXT,
        size INTEGER DEFAULT 0,
        is_downloaded INTEGER DEFAULT 1,
        download_progress REAL DEFAULT 1.0,
        downloaded_at TEXT,
        FOREIGN KEY (book_id) REFERENCES downloaded_books (id) ON DELETE CASCADE
      )
    ''');

    // PDF files table
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

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_book_id ON audio_parts(book_id)');
    await db.execute('CREATE INDEX idx_downloaded_at ON downloaded_books(downloaded_at)');
    await db.execute('CREATE INDEX idx_last_played ON downloaded_books(last_played_at)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration from old structure
      try {
        // Check if downloaded_books exists
        var tables = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='downloaded_books'"
        );

        if (tables.isEmpty) {
          // Create new table
          await db.execute('''
            CREATE TABLE downloaded_books (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              book_id INTEGER UNIQUE NOT NULL,
              title TEXT NOT NULL,
              format TEXT,
              description TEXT,
              cover_image TEXT,
              audio_duration INTEGER DEFAULT 0,
              author_name TEXT,
              total_size INTEGER DEFAULT 0,
              downloaded_at TEXT,
              last_played_position INTEGER DEFAULT 0,
              last_played_at TEXT
            )
          ''');

          await db.execute('CREATE INDEX idx_downloaded_at ON downloaded_books(downloaded_at)');
          await db.execute('CREATE INDEX idx_last_played ON downloaded_books(last_played_at)');
        }
      } catch (e) {
        print('Migration error: $e');
      }
    }
  }

  // ============= PDF OPERATIONS =============

  Future<int> insertPdf(
      String title,
      String downloadDate,
      String author,
      String coverImage,
      int size,
      String path,
      ) async {
    final db = await database;
    return await db.insert('pdf_files', {
      'title': title,
      'download_date': downloadDate,
      'author': author,
      'cover_image': coverImage,
      'size': size,
      'path': path
    });
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

  // ============= BOOK OPERATIONS =============

  Future<List<DownloadedBookModel>> getAllDownloadedBooks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'downloaded_books',
      orderBy: 'downloaded_at DESC',
    );
    return maps.map((map) => DownloadedBookModel.fromMap(map)).toList();
  }

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
        'last_played_position': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

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
        'is_downloaded': path.isNotEmpty ? 1 : 0,
        'download_progress': path.isNotEmpty ? 1.0 : 0.0,
        'downloaded_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateAudioPartPath({
    required int partId,
    required String path,
  }) async {
    final db = await database;
    await db.update(
      'audio_parts',
      {
        'path': path,
        'is_downloaded': 1,
        'download_progress': 1.0,
      },
      where: 'id = ?',
      whereArgs: [partId],
    );
  }

  // ============= SEARCH & FILTER =============

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

  Future<int> getTotalDownloadedSize() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(total_size) as total FROM downloaded_books',
    );
    return result.first['total'] as int? ?? 0;
  }

  Future<int> getDownloadedBooksCount() async {
    final db = await database;
    return Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM downloaded_books'),
    ) ??
        0;
  }

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
      'SELECT SUM(size) as downloaded FROM audio_parts WHERE book_id = ? AND is_downloaded = 1',
      [internalBookId],
    );

    final downloadedSize = partsResult.first['downloaded'] as int? ?? 0;

    if (totalSize == 0) return 0.0;
    return downloadedSize / totalSize;
  }

  // ============= PLAYBACK TRACKING =============

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

  Future<void> clearAllDownloads() async {
    final db = await database;
    await db.delete('audio_parts');
    await db.delete('downloaded_books');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}