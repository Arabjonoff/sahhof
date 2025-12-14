import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sahhof/src/model/pdf/pdf_file.dart';
import 'package:sahhof/src/theme/app_colors.dart';
import 'package:sahhof/src/theme/app_style.dart';
import 'package:sahhof/src/ui/main/detail/audio/audio_screen.dart';
import 'package:sahhof/src/ui/main/detail/audio/auido_dowload.dart';
import 'package:sahhof/src/ui/main/detail/read/read_screen.dart';

import '../../../bloc/pdf/pdf_bloc.dart' show pdfBloc;
import '../detail/audio/local_audio.dart';

class MyDownloadsScreen extends StatefulWidget {
  const MyDownloadsScreen({super.key});

  @override
  State<MyDownloadsScreen> createState() => _MyDownloadsScreenState();
}

class _MyDownloadsScreenState extends State<MyDownloadsScreen>
    with TickerProviderStateMixin {

  // UNCOMMENT qiling
  final AudioDownloadManager _audioManager = AudioDownloadManager();

  late TabController _mainTabController;
  late TabController _audioTabController;

  final TextEditingController _searchController = TextEditingController();

  // Audio data
  List<Map<String, dynamic>> _allAudioBooks = [];
  List<Map<String, dynamic>> _filteredAudioBooks = [];
  List<Map<String, dynamic>> _recentAudioBooks = [];

  // States
  bool _isLoading = true;
  bool _isAudioGridView = false;
  bool _isAudioSelectionMode = false;
  Set<int> _selectedAudioBooks = {};
  String _audioSortBy = 'date';

  Map<String, dynamic>? _storageInfo;

  @override
  void initState() {
    super.initState();

    // Main TabController (PDF va Audio)
    _mainTabController = TabController(length: 2, vsync: this);
    _mainTabController.addListener(_onMainTabChanged);

    // Audio SubTabs Controller
    _audioTabController = TabController(length: 3, vsync: this);
    _audioTabController.addListener(_onAudioTabChanged);

    _loadAllData();

    // UNCOMMENT qiling - PDF stream
    pdfBloc.getPdfFiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mainTabController.dispose();
    _audioTabController.dispose();
    pdfBloc.dispose(); // UNCOMMENT qiling
    super.dispose();
  }

  void _onMainTabChanged() {
    setState(() {
      _searchController.clear();
      if (_mainTabController.index == 1) {
        // Audio tab selected
        _loadAudioData();
      }
    });
  }

  void _onAudioTabChanged() {
    if (_audioTabController.index == 1) {
      _loadRecentAudioBooks();
    }
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
    });

    await _loadAudioData();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadAudioData() async {
    try {
      // UNCOMMENT qiling
      final books = await _audioManager.getDownloadedBooks();
      final storage = await _audioManager.getStorageInfo();

      // Test uchun:
      // final books = <Map<String, dynamic>>[];
      // final storage = {
      //   'total_size': 0,
      //   'formatted_size': '0 B',
      //   'books_count': 0,
      // };

      setState(() {
        _allAudioBooks = books;
        _filteredAudioBooks = books;
        _storageInfo = storage;
      });

      _applyAudioSorting();
    } catch (e) {
      print('Error loading audio data: $e');
    }
  }

  Future<void> _loadRecentAudioBooks() async {
    try {
      // UNCOMMENT qiling
      final recent = await _audioManager.getRecentlyPlayed(limit: 20);
      // final recent = <Map<String, dynamic>>[];

      setState(() {
        _recentAudioBooks = recent;
      });
    } catch (e) {
      print('Error loading recent audio: $e');
    }
  }

  void _searchAudio(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredAudioBooks = _allAudioBooks;
      });
    } else {
      setState(() {
        _filteredAudioBooks = _allAudioBooks.where((book) {
          final title = book['title'].toString().toLowerCase();
          final author = book['author_name'].toString().toLowerCase();
          return title.contains(query.toLowerCase()) ||
              author.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  void _applyAudioSorting() {
    setState(() {
      switch (_audioSortBy) {
        case 'name':
          _filteredAudioBooks.sort((a, b) =>
              a['title'].toString().compareTo(b['title'].toString())
          );
          break;
        case 'size':
          _filteredAudioBooks.sort((a, b) =>
              (b['total_size'] as int).compareTo(a['total_size'] as int)
          );
          break;
        case 'duration':
          _filteredAudioBooks.sort((a, b) =>
              (b['audio_duration'] as int).compareTo(a['audio_duration'] as int)
          );
          break;
        case 'date':
        default:
          _filteredAudioBooks.sort((a, b) =>
              b['downloaded_at'].toString().compareTo(a['downloaded_at'].toString())
          );
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text("Kutubxona"),
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          if (!_isAudioSelectionMode) _buildMainTabBar(),
          // Content
          Expanded(
            child: TabBarView(
              controller: _mainTabController,
              children: [
                _buildPdfTab(),
                _buildAudioTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _isAudioSelectionMode && _selectedAudioBooks.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: _deleteSelectedAudioBooks,
        backgroundColor: Colors.red,
        icon: Icon(Icons.delete_rounded),
        label: Text('${_selectedAudioBooks.length} ta o\'chirish'),
      )
          : null,
    );
  }


  PreferredSizeWidget _buildAudioSelectionAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary ?? Colors.blue,
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          setState(() {
            _isAudioSelectionMode = false;
            _selectedAudioBooks.clear();
          });
        },
        icon: Icon(Icons.close_rounded, color: Colors.white),
      ),
      title: Text(
        '${_selectedAudioBooks.length} tanlandi',
        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            if (_selectedAudioBooks.length == _filteredAudioBooks.length) {
              setState(() {
                _selectedAudioBooks.clear();
              });
            } else {
              setState(() {
                _selectedAudioBooks = _filteredAudioBooks
                    .map((b) => b['book_id'] as int)
                    .toSet();
              });
            }
          },
          icon: Icon(
            _selectedAudioBooks.length == _filteredAudioBooks.length
                ? Icons.deselect_rounded
                : Icons.select_all_rounded,
            color: Colors.white,
          ),
          label: Text(
            _selectedAudioBooks.length == _filteredAudioBooks.length
                ? 'Bekor qilish'
                : 'Hammasi',
            style: TextStyle(color: Colors.white),
          ),
        ),
        SizedBox(width: 8.w),
      ],
    );
  }


  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28.sp),
            SizedBox(height: 8.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        controller: _mainTabController,
        indicator: BoxDecoration(
          color: AppColors.primary ?? Colors.blue,
          borderRadius: BorderRadius.circular(12.r),
        ),
        labelColor: Colors.white,
        indicatorSize: TabBarIndicatorSize.tab,
        unselectedLabelColor: AppColors.grey ?? Colors.grey,
        labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chrome_reader_mode_outlined, size: 18.sp),
                SizedBox(width: 8.w),
                Text('Ebook'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.audiotrack_rounded, size: 18.sp),
                SizedBox(width: 8.w),
                Text('Audio'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // ==================== PDF TAB ====================
  Widget _buildPdfTab() {
    return Column(
      children: [
        // PDF List
        Expanded(
          child: StreamBuilder<List<PdfFile>>(
            stream: pdfBloc.pdfStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text("Kitoblar yoq");
              }

              final pdfs = snapshot.data!;

              return RefreshIndicator(
                onRefresh: () async {
                  // UNCOMMENT qiling
                  await pdfBloc.getPdfFiles();
                },
                color: AppColors.primary,
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  itemCount: pdfs.length,
                  itemBuilder: (context, index) {
                    return _buildPdfItem(pdfs[index]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPdfItem(PdfFile pdf) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.white,
        boxShadow:[
          BoxShadow(
            color: Colors.grey,blurRadius: 3,spreadRadius: -1
          )
        ]
      ),
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () {
          // UNCOMMENT qiling
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReadScreen(
                bookTitle: pdf.title,
                pdfPath: pdf.path,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              // Cover
              Container(
                width: 60.w,
                height: 80.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  image: DecorationImage(
                    image: pdf.coverImage.startsWith('http')
                        ? NetworkImage(pdf.coverImage)
                        : FileImage(File(pdf.coverImage)) as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pdf.title,
                      style: AppStyle.font600(AppColors.black).copyWith(fontSize: 15.sp),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),

                    Text(
                      pdf.author,
                      style: AppStyle.font400(AppColors.grey).copyWith(fontSize: 13.sp),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),

                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 12.sp, color: AppColors.grey),
                        SizedBox(width: 4.w),
                        Text(
                          pdf.downloadDate.substring(0,16),
                          style: AppStyle.font400(AppColors.grey).copyWith(fontSize: 11.sp),
                        ),
                        SizedBox(width: 12.w),
                        Icon(Icons.storage_rounded, size: 12.sp, color: AppColors.grey),
                        SizedBox(width: 4.w),
                        Text(
                          '${(pdf.size / 1024 / 1024).toStringAsFixed(1)} MB',
                          style: AppStyle.font400(AppColors.grey).copyWith(fontSize: 11.sp),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),

              // Delete button
              IconButton(
                onPressed: () => _deletePdf(pdf),
                icon: Icon(Icons.delete_outline_rounded, color: Colors.red),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deletePdf(PdfFile pdf) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28.sp),
            SizedBox(width: 8.w),
            Expanded(child: Text('O\'chirish')),
          ],
        ),
        content: Text('${pdf.title} kitobini o\'chirmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text('O\'chirish'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // UNCOMMENT qiling
      await pdfBloc.deletePdf(pdf.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8.w),
                Text('PDF o\'chirildi'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ==================== AUDIO TAB ====================

  Widget _buildAudioTab() {
    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: AppColors.primary))
              : TabBarView(
            controller: _audioTabController,
            children: [
              _buildAllAudioTab(),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildAllAudioTab() {
    if (_filteredAudioBooks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.audiotrack_rounded,
        title: 'Yuklab olingan audio kitoblar yo\'q',
        subtitle: 'Audio kitoblarni yuklab olib, offline tinglang',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAudioData,
      color: AppColors.primary,
      child: _isAudioGridView
          ? _buildAudioGridView()
          : _buildAudioListView(),
    );
  }

  Widget _buildAudioListView() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: _filteredAudioBooks.length,
      itemBuilder: (context, index) {
        final book = _filteredAudioBooks[index];
        final isSelected = _selectedAudioBooks.contains(book['book_id']);

        return Container(
          margin: EdgeInsets.symmetric(vertical: 4.sp),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.black,blurRadius: 5,spreadRadius: -4
              )
            ]
          ),
          child: InkWell(
            onTap: () {
              if (_isAudioSelectionMode) {
                _toggleAudioBookSelection(book['book_id']);
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (builder){
                  return LocalAudioPlayerScreen(bookId: book['book_id']);
                }));
              }
            },
            onLongPress: () {
              if (!_isAudioSelectionMode) {
                setState(() {
                  _isAudioSelectionMode = true;
                });
              }
              _toggleAudioBookSelection(book['book_id']);
            },
            borderRadius: BorderRadius.circular(16.r),
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  if (_isAudioSelectionMode) ...[
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleAudioBookSelection(book['book_id']),
                      activeColor: AppColors.primary,
                    ),
                    SizedBox(width: 8.w),
                  ],

                  // Cover
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: CachedNetworkImage(
                      imageUrl: book['cover_image'],
                      width: 70.w,
                      height: 95.h,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.audiotrack_rounded, size: 35.sp),
                      ),
                    ),
                  ),

                  SizedBox(width: 12.w),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book['title'],
                          style: AppStyle.font600(AppColors.black).copyWith(fontSize: 15.sp),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 6.h),

                        Text(
                          book['author_name'],
                          style: AppStyle.font400(AppColors.grey).copyWith(fontSize: 13.sp),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 10.h),

                        Wrap(
                          spacing: 12.w,
                          children: [
                            _buildSmallStat(Icons.storage_rounded, book['formatted_size']),
                          ],
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAudioGridView() {
    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: _filteredAudioBooks.length,
      itemBuilder: (context, index) {
        final book = _filteredAudioBooks[index];
        final isSelected = _selectedAudioBooks.contains(book['book_id']);

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: isSelected
                ? BorderSide(color: AppColors.primary ?? Colors.blue, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: () {
              if (_isAudioSelectionMode) {
                _toggleAudioBookSelection(book['book_id']);
              }
            },
            onLongPress: () {
              if (!_isAudioSelectionMode) {
                setState(() {
                  _isAudioSelectionMode = true;
                });
              }
              _toggleAudioBookSelection(book['book_id']);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.all(8.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['title'],
                        style: AppStyle.font600(AppColors.black).copyWith(fontSize: 13.sp),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),

                      Text(
                        book['author_name'],
                        style: AppStyle.font400(AppColors.grey).copyWith(fontSize: 11.sp),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentAudioTab() {
    if (_recentAudioBooks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 80.sp, color: Colors.grey.withOpacity(0.5)),
            SizedBox(height: 16.h),
            Text('Yaqinda tinglanganlar yo\'q', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: _recentAudioBooks.length,
      itemBuilder: (context, index) {
        final book = _recentAudioBooks[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          child: ListTile(
            title: Text(book['title']),
            subtitle: Text(book['author_name']),
            trailing: Icon(Icons.play_arrow_rounded, color: AppColors.primary),
          ),
        );
      },
    );
  }


  // ==================== COMMON WIDGETS ====================


  Widget _buildSmallStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.sp, color: AppColors.grey),
        SizedBox(width: 4.w),
        Text(text, style: AppStyle.font400(AppColors.grey).copyWith(fontSize: 11.sp)),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600,color: Colors.black),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== AUDIO HELPERS ====================

  void _toggleAudioBookSelection(int bookId) {
    setState(() {
      if (_selectedAudioBooks.contains(bookId)) {
        _selectedAudioBooks.remove(bookId);
      } else {
        _selectedAudioBooks.add(bookId);
      }
    });
  }

  Future<void> _deleteAudioBook(Map<String, dynamic> book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28.sp),
            SizedBox(width: 8.w),
            Expanded(child: Text('O\'chirish',style: AppStyle.font800(AppColors.black),)),
          ],
        ),
        content: Text('${book['title']} kitobini o\'chirmoqchimisiz?',style: AppStyle.font600(AppColors.grey),),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text('O\'chirish',style: AppStyle.font800(AppColors.white),),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // UNCOMMENT qiling
      final success = await _audioManager.deleteDownloadedBook(book['book_id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8.w),
                Text('Audio o\'chirildi'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadAudioData();
      }
    }
  }

  Future<void> _deleteSelectedAudioBooks() async {
    if (_selectedAudioBooks.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('${_selectedAudioBooks.length} ta kitobni o\'chirish'),
        content: Text('Tanlangan kitoblar va ularning barcha faylari o\'chiriladi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('O\'chirish'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // UNCOMMENT qiling
      for (final bookId in _selectedAudioBooks) {
        await _audioManager.deleteDownloadedBook(bookId);
      }

      setState(() {
        _selectedAudioBooks.clear();
        _isAudioSelectionMode = false;
      });

      _loadAudioData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kitoblar o\'chirildi'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAudioSortDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sort_rounded, color: AppColors.primary),
                SizedBox(width: 12.w),
                Text('Saralash', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600)),
              ],
            ),
            SizedBox(height: 20.h),
            _buildSortOption('date', Icons.access_time_rounded, 'Yuklab olingan sana', 'Eng yangi birinchi'),
            _buildSortOption('name', Icons.sort_by_alpha_rounded, 'Nomi', 'A dan Z gacha'),
            _buildSortOption('size', Icons.storage_rounded, 'Hajmi', 'Eng katta birinchi'),
            _buildSortOption('duration', Icons.timer_rounded, 'Davomiyligi', 'Eng uzun birinchi'),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String value, IconData icon, String title, String subtitle) {
    final isSelected = _audioSortBy == value;

    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: isSelected ? (AppColors.primary).withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, color: isSelected ? AppColors.primary : AppColors.grey, size: 24.sp),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
          color: isSelected ? AppColors.primary : AppColors.black,
        ),
      ),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12.sp, color: AppColors.grey)),
      trailing: isSelected ? Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24.sp) : null,
      onTap: () {
        setState(() {
          _audioSortBy = value;
        });
        _applyAudioSorting();
        Navigator.pop(context);
      },
    );
  }

  void _showStorageInfo() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage_rounded, color: AppColors.primary, size: 28.sp),
                SizedBox(width: 12.w),
                Text(
                  'Xotira ma\'lumoti',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600,color: AppColors.black),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            _buildStorageItem(
              icon: Icons.download_rounded,
              title: 'Jami yuklab olingan',
              value: _storageInfo?['formatted_size'] ?? '0 B',
              color: AppColors.primary ?? Colors.blue,
            ),

            _buildStorageItem(
              icon: Icons.library_books_rounded,
              title: 'Jami kitoblar',
              value: '${(_storageInfo?['books_count'] ?? 0)} ta',
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13.sp, color: Colors.grey[600])),
                SizedBox(height: 4.h),
                Text(value, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600,color: AppColors.black)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}