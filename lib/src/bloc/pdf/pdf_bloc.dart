import 'package:rxdart/rxdart.dart';
import '../../api/repository.dart';
import '../../model/pdf/pdf_file.dart';

class PdfBloc {
  final Repository _repository = Repository();

  final _pdfListController = BehaviorSubject<List<PdfFile>>.seeded([]);
  Stream<List<PdfFile>> get pdfStream => _pdfListController.stream;
  List<PdfFile> get currentList => _pdfListController.value;

  /// 📥 Barcha PDF fayllarni olish
  Future<void> getPdfFiles() async {
    try {
      final data = await _repository.getPdfFiles(); // repository orqali
      _pdfListController.add(data);
    } catch (e) {
      _pdfListController.addError(e);
    }
  }

  /// ➕ Yangi PDF faylni qo‘shish
  Future<void> addPdf({
    required String title,
    required String downloadDate,
    required String author,
    required String coverImage,
    required int size,
    required String path,
  }) async {
    try {
      await _repository.insertPdf(title, downloadDate, author, coverImage, size, path);
      await getPdfFiles(); // ro‘yxatni yangilash
    } catch (e) {
      _pdfListController.addError(e);
    }
  }

  /// ❌ PDF faylni o‘chirish
  Future<void> deletePdf(int id) async {
    try {
      await _repository.deletePdf(id);
      await getPdfFiles();
    } catch (e) {
      _pdfListController.addError(e);
    }
  }

  void dispose() {
    _pdfListController.close();
  }
}

final pdfBloc = PdfBloc();
