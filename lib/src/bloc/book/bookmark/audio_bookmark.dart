import 'package:rxdart/rxdart.dart';
import 'package:sahhof/src/database/database_helper.dart';
import 'package:sahhof/src/model/audio/audio_model.dart';

class DownloadedBooksBloc {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Streams
  final _fetchDownloadedBooks = PublishSubject<List<DownloadedBookModel>>();
  final _fetchSingleBook = PublishSubject<DownloadedBookModel?>();
  final _fetchBookParts = PublishSubject<List<AudioPartModel>>();
  final _fetchDownloadProgress = PublishSubject<double>();
  final _fetchTotalSize = PublishSubject<int>();

  // Stream getters
  Stream<List<DownloadedBookModel>> get getDownloadedBooksStream => _fetchDownloadedBooks.stream;
  Stream<DownloadedBookModel?> get getSingleBookStream => _fetchSingleBook.stream;
  Stream<List<AudioPartModel>> get getBookPartsStream => _fetchBookParts.stream;
  Stream<double> get getDownloadProgressStream => _fetchDownloadProgress.stream;
  Stream<int> get getTotalSizeStream => _fetchTotalSize.stream;

  // Get all downloaded books
  Future<void> getAllDownloadedBooks() async {
    try {
      List<DownloadedBookModel> books = await _databaseHelper.getAllDownloadedBooks();
      _fetchDownloadedBooks.add(books);
    } catch (e) {
      print('Error getting downloaded books: $e');
      _fetchDownloadedBooks.addError(e);
    }
  }

  // Get single book by ID
  Future<void> getDownloadedBook(int bookId) async {
    try {
      DownloadedBookModel? book = await _databaseHelper.getDownloadedBook(bookId);
      _fetchSingleBook.add(book);
    } catch (e) {
      print('Error getting book: $e');
      _fetchSingleBook.addError(e);
    }
  }

  // Get book parts (audio files)
  Future<void> getBookParts(int bookId) async {
    try {
      List<AudioPartModel> parts = await _databaseHelper.getAudioParts(bookId);
      _fetchBookParts.add(parts);
    } catch (e) {
      print('Error getting book parts: $e');
      _fetchBookParts.addError(e);
    }
  }

  // Check if book is downloaded
  Future<bool> isBookDownloaded(int bookId) async {
    try {
      return await _databaseHelper.isBookDownloaded(bookId);
    } catch (e) {
      print('Error checking download status: $e');
      return false;
    }
  }

  // Get download progress
  Future<void> getDownloadProgress(int bookId) async {
    try {
      double progress = await _databaseHelper.getDownloadProgress(bookId);
      _fetchDownloadProgress.add(progress);
    } catch (e) {
      print('Error getting download progress: $e');
      _fetchDownloadProgress.addError(e);
    }
  }

  // Get total downloaded size
  Future<void> getTotalDownloadedSize() async {
    try {
      int totalSize = await _databaseHelper.getTotalDownloadedSize();
      _fetchTotalSize.add(totalSize);
    } catch (e) {
      print('Error getting total size: $e');
      _fetchTotalSize.addError(e);
    }
  }

  // Delete downloaded book
  Future<bool> deleteDownloadedBook(int bookId) async {
    try {
      bool success = await _databaseHelper.deleteBook(bookId);
      if (success) {
        // Refresh list after deletion
        await getAllDownloadedBooks();
      }
      return success;
    } catch (e) {
      print('Error deleting book: $e');
      return false;
    }
  }

  // Search downloaded books
  Future<void> searchDownloadedBooks(String query) async {
    try {
      List<DownloadedBookModel> books = await _databaseHelper.searchDownloadedBooks(query);
      _fetchDownloadedBooks.add(books);
    } catch (e) {
      print('Error searching books: $e');
      _fetchDownloadedBooks.addError(e);
    }
  }

  // Get books by author
  Future<void> getBooksByAuthor(String authorName) async {
    try {
      List<DownloadedBookModel> books = await _databaseHelper.getBooksByAuthor(authorName);
      _fetchDownloadedBooks.add(books);
    } catch (e) {
      print('Error getting books by author: $e');
      _fetchDownloadedBooks.addError(e);
    }
  }

  // Update last played position
  Future<void> updateLastPlayedPosition(int bookId, int position) async {
    try {
      await _databaseHelper.updateLastPlayedPosition(bookId, position);
    } catch (e) {
      print('Error updating last played position: $e');
    }
  }

  // Get recently played books
  Future<void> getRecentlyPlayedBooks({int limit = 10}) async {
    try {
      List<DownloadedBookModel> books = await _databaseHelper.getRecentlyPlayedBooks(limit: limit);
      _fetchDownloadedBooks.add(books);
    } catch (e) {
      print('Error getting recently played books: $e');
      _fetchDownloadedBooks.addError(e);
    }
  }

  // Dispose streams
  void dispose() {
    _fetchDownloadedBooks.close();
    _fetchSingleBook.close();
    _fetchBookParts.close();
    _fetchDownloadProgress.close();
    _fetchTotalSize.close();
  }
}

// Global instance
final downloadedBooksBloc = DownloadedBooksBloc();