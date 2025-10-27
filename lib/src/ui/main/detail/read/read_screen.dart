import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:sahhof/src/theme/app_style.dart';
import 'package:sahhof/src/theme/app_colors.dart';

class ReadScreen extends StatefulWidget {
  final String bookTitle;
  final int? pdfUrl;        // Online stream uchun
  final String? pdfPath;    // Offline o'qish uchun
  final int? initialPage;

  const ReadScreen({
    Key? key,
    required this.bookTitle,
    this.pdfUrl,
    this.pdfPath,
    this.initialPage,
  }) : super(key: key);

  @override
  State<ReadScreen> createState() => _ReadScreenState();
}

class _ReadScreenState extends State<ReadScreen> {
  PDFViewController? _pdfController;
  bool _isLoading = true;
  bool _showBottomBar = true;
  int _currentPage = 1;
  int _totalPages = 0;
  double _fontSize = 16.0;
  bool _isDarkMode = false;
  String? _localPath;
  String? _errorMessage;
  bool _isOnlineMode = false;

  @override
  void initState() {
    super.initState();

    // Agar pdfPath mavjud bo'lsa - offline, aks holda online
    if (widget.pdfPath != null) {
      _isOnlineMode = false;
      _loadLocalPdf();
    } else if (widget.pdfUrl != null) {
      _isOnlineMode = true;
      _loadPdfFromNetwork();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'PDF topilmadi';
      });
    }
  }

  // Lokal PDF'ni yuklash (offline)
  Future<void> _loadLocalPdf() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final file = File(widget.pdfPath!);

      if (await file.exists()) {
        setState(() {
          _localPath = widget.pdfPath;
          _isLoading = false;
        });
      } else {
        throw Exception('PDF fayl topilmadi');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Xatolik: ${e.toString()}';
      });
    }
  }

  // Tarmoqdan PDF yuklash (online stream)
  Future<void> _loadPdfFromNetwork() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final url = "http://buxoro-sf.uz/api/v1/books/${widget.pdfUrl}/pdf_download/";

      // Stream orqali yuklash
      final request = http.Request('GET', Uri.parse(url));
      final response = await request.send();

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/temp_${widget.pdfUrl}_${DateTime.now().millisecondsSinceEpoch}.pdf');

        // Stream orqali yozish
        final sink = file.openWrite();
        await response.stream.pipe(sink);
        await sink.close();

        if (mounted) {
          setState(() {
            _localPath = file.path;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Xatolik: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _toggleBottomBar() {
    setState(() {
      _showBottomBar = !_showBottomBar;
    });
  }

  void _goToPage(int page) {
    if (page > 0 && page <= _totalPages && _pdfController != null) {
      _pdfController!.setPage(page - 1);
      setState(() {
        _currentPage = page;
      });
    }
  }

  void _showPageJumpDialog() {
    TextEditingController pageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sahifaga o\'tish', style: AppStyle.font600(Colors.black)),
        content: TextField(
          style: AppStyle.font600(Colors.black),
          controller: pageController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '1-$_totalPages orasida kiriting',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () {
              int? page = int.tryParse(pageController.text);
              if (page != null && page > 0 && page <= _totalPages) {
                _goToPage(page);
                Navigator.pop(context);
              }
            },
            child: Text('O\'tish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.bookTitle,
              style: AppStyle.font600(Colors.black).copyWith(fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(_isOnlineMode ? 'PDF yuklanmoqda...' : 'PDF ochilmoqda...'),
          ],
        ),
      )
          : _localPath == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 20),
            Text(_errorMessage ?? 'Xatolik yuz berdi'),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isOnlineMode ? _loadPdfFromNetwork : _loadLocalPdf,
              child: Text('Qayta urinish'),
            ),
          ],
        ),
      )
          : GestureDetector(
        onTap: _toggleBottomBar,
        child: PDFView(
          filePath: _localPath!,
          enableSwipe: true,
          swipeHorizontal: true,
          autoSpacing: false,
          pageFling: true,
          pageSnap: true,
          defaultPage: (widget.initialPage ?? 1) - 1,
          fitPolicy: FitPolicy.BOTH,
          onRender: (pages) {
            setState(() {
              _totalPages = pages!;
            });
          },
          onError: (error) {
            print('PDF Error: $error');
            setState(() {
              _errorMessage = 'PDF ochishda xatolik: $error';
            });
          },
          onViewCreated: (PDFViewController controller) {
            _pdfController = controller;
          },
          onPageChanged: (int? page, int? total) {
            setState(() {
              _currentPage = (page ?? 0) + 1;
              _totalPages = total ?? 0;
            });
          },
        ),
      ),
      bottomNavigationBar: _showBottomBar && _localPath != null
          ? Container(
        height: 80,
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.grey[800] : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.navigate_before,
                  size: 30,
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
                onPressed: _currentPage > 1
                    ? () => _goToPage(_currentPage - 1)
                    : null,
              ),
              GestureDetector(
                onTap: _showPageJumpDialog,
                child: Container(
                  padding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isDarkMode
                        ? Colors.grey[700]
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_currentPage / ${_totalPages > 0 ? _totalPages : '?'}',
                    style: TextStyle(
                      fontSize: _fontSize,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.navigate_next,
                  size: 30,
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
                onPressed: _currentPage < _totalPages && _totalPages > 0
                    ? () => _goToPage(_currentPage + 1)
                    : null,
              ),
            ],
          ),
        ),
      )
          : null,
    );
  }

  @override
  void dispose() {
    // Faqat online temp fayllarni o'chirish
    if (_localPath != null && _isOnlineMode) {
      final file = File(_localPath!);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    super.dispose();
  }
}