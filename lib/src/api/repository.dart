import 'package:sahhof/src/api/api_provider.dart';
import 'package:sahhof/src/database/database_helper.dart';
import 'package:sahhof/src/model/http_result.dart';

import '../model/pdf/pdf_file.dart';

class Repository{
  final ApiProvider _apiProvider = ApiProvider();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  /// DataBaseHelper

  Future<int> insertPdf(title, downloadDate, author, coverImage, size, path) async {
    return await _databaseHelper.insertPdf(title, downloadDate, author, coverImage, size, path);
  }
  Future<List<PdfFile>> getPdfFiles() async {
    return await _databaseHelper.getPdfFiles();
  }
  Future<void> deletePdf(int id) async {
    await _databaseHelper.deletePdf(id);
  }



  Future<HttpResult> register(Map data)async => await _apiProvider.register(data);
  Future<HttpResult> login(Map data)async => await _apiProvider.login(data);
  Future<HttpResult> verification(int id,code)async => await _apiProvider.verification(id,code);
  Future<HttpResult> getCategories()async => await _apiProvider.getCategories();
  Future<HttpResult> getBooks(id)async => await _apiProvider.getBooks(id);
  Future<HttpResult> getBookById(int id)async => await _apiProvider.getBookById(id);
  Future<HttpResult> addCommentRating(int id,data)async => await _apiProvider.addCommentRating(id,data);
  Future<HttpResult> addBookMark(int id)async => await _apiProvider.addBookMark(id);
  Future<HttpResult> getBookMark()async => await _apiProvider.getBookMark();
  Future<HttpResult> getBanner()async => await _apiProvider.getBanner();
  Future<HttpResult> getProfile()async => await _apiProvider.getProfile();
  Future<HttpResult> logout()async => await _apiProvider.logout();
  Future<HttpResult> changePassword(data)async => await _apiProvider.changePassword(data);
  Future<HttpResult> resetPassword(data)async => await _apiProvider.resetPassword(data);
  Future<HttpResult> pdfDownload(id)async => await _apiProvider.pdfDownload(id);
  Future<HttpResult> audioDownload(id)async => await _apiProvider.audioDownload(id);
  Future<HttpResult> getAuthors()async => await _apiProvider.getAuthors();
  Future<HttpResult> getAuthorById(int id)async => await _apiProvider.getAuthorById(id);
}