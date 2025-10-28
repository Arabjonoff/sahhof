import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sahhof/src/theme/app_colors.dart';
import 'package:sahhof/src/theme/app_style.dart';
import 'package:sahhof/src/ui/main/detail/audio/audio_screen.dart';
import 'package:sahhof/src/ui/main/detail/audio/auido_dowload.dart';
import 'package:sahhof/src/ui/main/detail/audio/local_audio.dart';
import 'package:sahhof/src/ui/main/home/home_screen.dart';
import 'package:sahhof/src/ui/main/mybook/my_audio_screen.dart';
import 'package:sahhof/src/ui/main/mybook/my_book_screen.dart';
import 'package:sahhof/src/ui/main/profile/profile_screen.dart';
import 'package:sahhof/src/ui/main/search/serach_screen.dart';
import 'package:sahhof/src/ui/mini_audio_player.dart';
import 'package:sahhof/src/utils/cache.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;
  List<Widget> pages = [
    HomeScreen(),
    SearchScreen(),
    MyDownloadsScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      bottomSheet: MiniAudioPlayer(),
      body: SafeArea(
        child: IndexedStack(
          index: selectedIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
          currentIndex: selectedIndex,
          onTap: (index){
            setState(() {
              selectedIndex = index;
            });},
          items: [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled),label: "Asosiy"),
        BottomNavigationBarItem(icon: Icon(Icons.search),label: "Qidiruv"),
        BottomNavigationBarItem(icon: Icon(Icons.receipt),label: "Kutubxona"),
      ]),
    );
  }
}

// Import qilishingiz kerak
// import '../helpers/audio_download_manager.dart';
// import '../theme/app_colors.dart';
// import '../theme/app_style.dart';

class DownloadedAudioBooksScreen extends StatefulWidget {
  const DownloadedAudioBooksScreen({Key? key}) : super(key: key);

  @override
  State<DownloadedAudioBooksScreen> createState() => _DownloadedAudioBooksScreenState();
}

class _DownloadedAudioBooksScreenState extends State<DownloadedAudioBooksScreen>
    with SingleTickerProviderStateMixin {

  final AudioDownloadManager _downloadManager = AudioDownloadManager();
  late TabController _tabController;

  List<Map<String, dynamic>> _allBooks = [];
  List<Map<String, dynamic>> _filteredBooks = [];
  List<Map<String, dynamic>> _recentBooks = [];

  final TextEditingController _searchController = TextEditingController();

  String _sortBy = 'date'; // date, name, size, duration
  bool _isGridView = false;
  bool _isLoading = true;
  bool _isSelectionMode = false;
  Set<int> _selectedBooks = {};

  Map<String, dynamic>? _storageInfo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 1) {
      _loadRecentBooks();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final books = await _downloadManager.getDownloadedBooks();
      final storage = await _downloadManager.getStorageInfo();

      setState(() {
        _allBooks = books;
        _filteredBooks = books;
        _storageInfo = storage;
        _isLoading = false;
      });

      _applySorting();
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecentBooks() async {
    try {
      final recent = await _downloadManager.getRecentlyPlayed(limit: 20);
      setState(() {
        _recentBooks = recent;
      });
    } catch (e) {
      print('Error loading recent books: $e');
    }
  }

  void _searchBooks(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredBooks = _allBooks;
      });
    } else {
      setState(() {
        _filteredBooks = _allBooks.where((book) {
          final title = book['title'].toString().toLowerCase();
          final author = book['author_name'].toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return title.contains(searchLower) || author.contains(searchLower);
        }).toList();
      });
    }
  }

  void _applySorting() {
    setState(() {
      switch (_sortBy) {
        case 'name':
          _filteredBooks.sort((a, b) =>
              a['title'].toString().compareTo(b['title'].toString())
          );
          break;
        case 'size':
          _filteredBooks.sort((a, b) =>
              (b['total_size'] as int).compareTo(a['total_size'] as int)
          );
          break;
        case 'duration':
          _filteredBooks.sort((a, b) =>
              (b['audio_duration'] as int).compareTo(a['audio_duration'] as int)
          );
          break;
        case 'date':
        default:
          _filteredBooks.sort((a, b) =>
              b['downloaded_at'].toString().compareTo(a['downloaded_at'].toString())
          );
          break;
      }
    });
  }

  void _sortBooks(String sortBy) {
    setState(() {
      _sortBy = sortBy;
    });
    _applySorting();
  }

  void _toggleViewMode() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedBooks.clear();
      }
    });
  }

  void _toggleBookSelection(int bookId) {
    setState(() {
      if (_selectedBooks.contains(bookId)) {
        _selectedBooks.remove(bookId);
      } else {
        _selectedBooks.add(bookId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedBooks = _filteredBooks.map((b) => b['book_id'] as int).toSet();
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedBooks.clear();
    });
  }

  Future<void> _deleteSelectedBooks() async {
    if (_selectedBooks.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                '${_selectedBooks.length} ta kitobni o\'chirish',
                style: AppStyle.font600(AppColors.black).copyWith(fontSize: 16.sp),
              ),
            ),
          ],
        ),
        content: Text(
          'Tanlangan kitoblar va ularning barcha faylari o\'chiriladi. Davom etasizmi?',
          style: AppStyle.font400(AppColors.grey).copyWith(fontSize: 14.sp),
        ),
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
      _showLoadingDialog('O\'chirilmoqda...');

      int successCount = 0;
      for (final bookId in _selectedBooks) {
        final success = await _downloadManager.deleteDownloadedBook(bookId);
        if (success) successCount++;
      }

      Navigator.pop(context); // Close loading dialog

      setState(() {
        _selectedBooks.clear();
        _isSelectionMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount ta kitob o\'chirildi'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadData();
      }
    }
  }

  Future<void> _deleteBook(Map<String, dynamic> book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28.sp),
            SizedBox(width: 8.w),
            Expanded(child: Text('O\'chirish', style: AppStyle.font600(AppColors.black))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book['title'],
              style: AppStyle.font600(AppColors.black).copyWith(fontSize: 15.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              'Kitobni va uning barcha audio fayllarini (${book['formatted_size']}) o\'chirmoqchimisiz?',
              style: AppStyle.font400(AppColors.grey).copyWith(fontSize: 13.sp),
            ),
          ],
        ),
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
      _showLoadingDialog('O\'chirilmoqda...');

      final success = await _downloadManager.deleteDownloadedBook(book['book_id']);

      Navigator.pop(context); // Close loading dialog

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 8.w),
                  Expanded(child: Text('Kitob o\'chirildi')),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Xatolik yuz berdi'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 20.h),
              Text(
                message,
                style: AppStyle.font600(AppColors.black).copyWith(fontSize: 16.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortDialog() {
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
                Text(
                  'Saralash',
                  style: AppStyle.font600(AppColors.black).copyWith(fontSize: 18.sp),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            _buildSortOption(
              icon: Icons.access_time_rounded,
              title: 'Yuklab olingan sana',
              subtitle: 'Eng yangi birinchi',
              value: 'date',
            ),
            _buildSortOption(
              icon: Icons.sort_by_alpha_rounded,
              title: 'Nomi',
              subtitle: 'A dan Z gacha',
              value: 'name',
            ),
            _buildSortOption(
              icon: Icons.storage_rounded,
              title: 'Hajmi',
              subtitle: 'Eng katta birinchi',
              value: 'size',
            ),
            _buildSortOption(
              icon: Icons.timer_rounded,
              title: 'Davomiyligi',
              subtitle: 'Eng uzun birinchi',
              value: 'duration',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _sortBy == value;

    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary?.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.grey,
          size: 24.sp,
        ),
      ),
      title: Text(
        title,
        style: AppStyle.font500(
          isSelected ? AppColors.primary : AppColors.black,
        ).copyWith(fontSize: 15.sp),
      ),
      subtitle: Text(
        subtitle,
        style: AppStyle.font400(AppColors.grey).copyWith(fontSize: 12.sp),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24.sp)
          : null,
      onTap: () {
        _sortBooks(value);
        Navigator.pop(context);
      },
    );
  }

  void _showStorageInfo() {
    if (_storageInfo == null) return;

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
                  style: AppStyle.font600(AppColors.black).copyWith(fontSize: 18.sp),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            _buildStorageItem(
              icon: Icons.download_rounded,
              title: 'Yuklab olingan',
              value: _storageInfo!['formatted_size'] ?? '0 B',
              color: AppColors.primary ?? Colors.blue,
            ),

            _buildStorageItem(
              icon: Icons.library_books_rounded,
              title: 'Kitoblar soni',
              value: '${_storageInfo!['books_count']} ta',
              color: Colors.green,
            ),

            SizedBox(height: 16.h),

            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder_rounded, color: Colors.blue, size: 24.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saqlash joyi',
                          style: AppStyle.font400(Colors.blue[900]!).copyWith(fontSize: 12.sp),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _storageInfo!['storage_path'] ?? 'N/A',
                          style: AppStyle.font600(Colors.blue[900]!).copyWith(fontSize: 11.sp),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                Text(
                  title,
                  style: AppStyle.font400(AppColors.grey).copyWith(fontSize: 13.sp),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: AppStyle.font600(AppColors.black).copyWith(fontSize: 16.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background ?? Colors.grey[50],
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
      body: Column(
        children: [
          // Header with stats
          if (!_isSelectionMode) _buildHeaderStats(),

          // Tabs
          if (!_isSelectionMode) _buildTabBar(),

          // Search bar
          if (!_isSelectionMode && _tabController.index == 0) _buildSearchBar(),

          // Content
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                : TabBarView(
              controller: _tabController,
              children: [
                _buildAllBooksTab(),
                _buildRecentTab(),
                _buildFavoritesTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode && _selectedBooks.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: _deleteSelectedBooks,
        backgroundColor: Colors.red,
        icon: Icon(Icons.delete_rounded),
        label: Text('${_selectedBooks.length} ta o\'chirish'),
      )
          : null,
    );
  }

  PreferredSizeWidget _buildNormalAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      title: Text(
        'Yuklanmalar',
        style: AppStyle.font600(Colors.white).copyWith(fontSize: 20.sp),
      ),
      actions: [
        IconButton(
          onPressed: _toggleViewMode,
          icon: Icon(
            _isGridView ? Icons.list_rounded : Icons.grid_view_rounded,
            color: Colors.white,
          ),
          tooltip: _isGridView ? 'Ro\'yxat' : 'Grid',
        ),
        IconButton(
          onPressed: _showSortDialog,
          icon: Icon(Icons.sort_rounded, color: Colors.white),
          tooltip: 'Saralash',
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'select':
                _toggleSelectionMode();
                break;
              case 'storage':
                _showStorageInfo();
                break;
              case 'refresh':
                _loadData();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'select',
              child: Row(
                children: [
                  Icon(Icons.checklist_rounded, size: 20.sp),
                  SizedBox(width: 12.w),
                  Text('Tanlash rejimi'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'storage',
              child: Row(
                children: [
                  Icon(Icons.storage_rounded, size: 20.sp),
                  SizedBox(width: 12.w),
                  Text('Xotira ma\'lumoti'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh_rounded, size: 20.sp),
                  SizedBox(width: 12.w),
                  Text('Yangilash'),
                ],
              ),
            ),
          ],
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  PreferredSizeWidget _buildSelectionAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: IconButton(
        onPressed: _toggleSelectionMode,
        icon: Icon(Icons.close_rounded, color: Colors.white),
      ),
      title: Text(
        '${_selectedBooks.length} tanlandi',
        style: AppStyle.font600(Colors.white).copyWith(fontSize: 18.sp),
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            if (_selectedBooks.length == _filteredBooks.length) {
              _deselectAll();
            } else {
              _selectAll();
            }
          },
          icon: Icon(
            _selectedBooks.length == _filteredBooks.length
                ? Icons.deselect_rounded
                : Icons.select_all_rounded,
            color: Colors.white,
          ),
          label: Text(
            _selectedBooks.length == _filteredBooks.length ? 'Bekor qilish' : 'Hammasi',
            style: TextStyle(color: Colors.white),
          ),
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  Widget _buildHeaderStats() {
    if (_storageInfo == null) return SizedBox();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary?.withOpacity(0.3) ?? Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            icon: Icons.library_books_rounded,
            label: 'Kitoblar',
            value: '${_storageInfo!['books_count']}',
            color: Colors.white,
          ),
          Container(
            width: 1,
            height: 50.h,
            color: Colors.white.withOpacity(0.3),
          ),
          _buildStatCard(
            icon: Icons.storage_rounded,
            label: 'Hajmi',
            value: _storageInfo!['formatted_size'] ?? '0 B',
            color: Colors.white,
            onTap: _showStorageInfo,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32.sp),
            SizedBox(height: 8.h),
            Text(
              value,
              style: AppStyle.font600(color).copyWith(fontSize: 20.sp),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: AppStyle.font400(color.withOpacity(0.9))
                  .copyWith(fontSize: 12.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12.r),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.grey,
        labelStyle: AppStyle.font600(Colors.white).copyWith(fontSize: 13.sp),
        unselectedLabelStyle: AppStyle.font500(AppColors.grey).copyWith(fontSize: 13.sp),
        tabs: [
          Tab(text: 'Hammasi (${_allBooks.length})'),
          Tab(text: 'Yaqinda'),
          Tab(text: 'Sevimlilar'),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: TextField(
        controller: _searchController,
        onChanged: _searchBooks,
        decoration: InputDecoration(
          hintText: 'Kitob yoki muallif qidiring...',
          hintStyle: TextStyle(color: AppColors.grey, fontSize: 14.sp),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.grey, size: 22.sp),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear_rounded, color: AppColors.grey, size: 20.sp),
            onPressed: () {
              _searchController.clear();
              _searchBooks('');
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        ),
      ),
    );
  }

  Widget _buildAllBooksTab() {
    if (_filteredBooks.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: _isGridView
          ? _buildGridView(_filteredBooks)
          : _buildListView(_filteredBooks),
    );
  }

  Widget _buildRecentTab() {
    if (_recentBooks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 80.sp, color: AppColors.grey?.withOpacity(0.5)),
            SizedBox(height: 16.h),
            Text(
              'Yaqinda tinglanganlar yo\'q',
              style: AppStyle.font600(AppColors.black).copyWith(fontSize: 16.sp),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: _recentBooks.length,
      itemBuilder: (context, index) {
        final book = _recentBooks[index];
        return _buildRecentBookItem(book);
      },
    );
  }

  Widget _buildFavoritesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_outline_rounded, size: 80.sp, color: AppColors.grey?.withOpacity(0.5)),
          SizedBox(height: 16.h),
          Text(
            'Sevimlilar bo\'limi',
            style: AppStyle.font600(AppColors.black).copyWith(fontSize: 16.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            'Tez orada qo\'shiladi',
            style: AppStyle.font400(AppColors.grey).copyWith(fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> books) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return _buildBookListItem(book);
      },
    );
  }

  Widget _buildGridView(List<Map<String, dynamic>> books) {
    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return _buildBookGridItem(book);
      },
    );
  }

  Widget _buildBookListItem(Map<String, dynamic> book) {
    final isSelected = _selectedBooks.contains(book['book_id']);
    final lastPosition = book['last_played_position'] as int? ?? 0;
    final duration = book['audio_duration'] as int? ?? 0;

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: isSelected
            ? BorderSide(color: AppColors.primary ?? Colors.blue, width: 2)
            : BorderSide.none,
      ),
      elevation: isSelected ? 4 : 2,
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            _toggleBookSelection(book['book_id']);
          } else {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => LocalAudioPlayerScreen(bookId: book['book_id']),
            ));
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
            });
          }
          _toggleBookSelection(book['book_id']);
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              // Selection checkbox
              if (_isSelectionMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleBookSelection(book['book_id']),
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
                ),
                SizedBox(width: 8.w),
              ],

              // Cover image
              Stack(
                children: [
                  Hero(
                    tag: 'book_cover_${book['book_id']}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: CachedNetworkImage(
                        imageUrl: book['cover_image'],
                        width: 70.w,
                        height: 95.h,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.audiotrack_rounded, size: 35.sp, color: AppColors.grey),
                        ),
                      ),
                    ),
                  ),
                  if (!_isSelectionMode)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.play_circle_outline_rounded,
                          color: Colors.white,
                          size: 32.sp,
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(width: 12.w),

              // Book info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book['title'],
                      style: AppStyle.font600(AppColors.black).copyWith(
                        fontSize: 15.sp,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),

                    Text(
                      book['author_name'],
                      style: AppStyle.font400(AppColors.grey).copyWith(
                        fontSize: 13.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 10.h),

                    // Stats
                    Wrap(
                      spacing: 12.w,
                      runSpacing: 6.h,
                      children: [
                        _buildSmallStat(Icons.storage_rounded, book['formatted_size']),
                        _buildSmallStat(Icons.access_time_rounded, book['formatted_duration']),
                      ],
                    ),

                    // Progress
                    if (lastPosition > 0 && duration > 0 && !_isSelectionMode) ...[
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3.r),
                              child: LinearProgressIndicator(
                                value: lastPosition / duration,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary ?? Colors.blue,
                                ),
                                minHeight: 5.h,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '${((lastPosition / duration) * 100).toInt()}%',
                            style: AppStyle.font600(AppColors.primary).copyWith(
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(width: 8.w),

              // Delete button
              if (!_isSelectionMode)
                IconButton(
                  onPressed: () => _deleteBook(book),
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

  Widget _buildBookGridItem(Map<String, dynamic> book) {
    final isSelected = _selectedBooks.contains(book['book_id']);
    final lastPosition = book['last_played_position'] as int? ?? 0;
    final duration = book['audio_duration'] as int? ?? 0;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: isSelected
            ? BorderSide(color: AppColors.primary ?? Colors.blue, width: 2)
            : BorderSide.none,
      ),
      elevation: isSelected ? 4 : 2,
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            _toggleBookSelection(book['book_id']);
          } else {
            // Navigate to player
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
            });
          }
          _toggleBookSelection(book['book_id']);
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Hero(
                    tag: 'book_cover_${book['book_id']}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                      child: CachedNetworkImage(
                        imageUrl: book['cover_image'],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.audiotrack_rounded, size: 40.sp),
                        ),
                      ),
                    ),
                  ),

                  if (_isSelectionMode)
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: isSelected ? AppColors.primary : Colors.grey,
                          size: 24.sp,
                        ),
                      ),
                    )
                  else
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: GestureDetector(
                        onTap: () => _deleteBook(book),
                        child: Container(
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                            size: 18.sp,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(10.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book['title'],
                      style: AppStyle.font600(AppColors.black).copyWith(
                        fontSize: 13.sp,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),

                    Text(
                      book['author_name'],
                      style: AppStyle.font400(AppColors.grey).copyWith(
                        fontSize: 11.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    Spacer(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSmallStat(Icons.storage_rounded, book['formatted_size']),
                        if (lastPosition > 0 && duration > 0)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppColors.primary?.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              '${((lastPosition / duration) * 100).toInt()}%',
                              style: AppStyle.font600(AppColors.primary).copyWith(
                                fontSize: 10.sp,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBookItem(Map<String, dynamic> book) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: ListTile(
        contentPadding: EdgeInsets.all(12.w),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: CachedNetworkImage(
            imageUrl: book['cover_image'],
            width: 50.w,
            height: 50.w,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey[300]),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              child: Icon(Icons.audiotrack_rounded),
            ),
          ),
        ),
        title: Text(
          book['title'],
          style: AppStyle.font600(AppColors.black).copyWith(fontSize: 14.sp),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            Text(
              book['author_name'],
              style: AppStyle.font400(AppColors.grey).copyWith(fontSize: 12.sp),
            ),
            if (book['last_played_at'] != null) ...[
              SizedBox(height: 4.h),
              Text(
                _formatDate(book['last_played_at']),
                style: AppStyle.font400(AppColors.grey).copyWith(fontSize: 11.sp),
              ),
            ],
          ],
        ),
        trailing: Icon(Icons.play_arrow_rounded, color: AppColors.primary),
        onTap: () {
          // Navigate to player
        },
      ),
    );
  }

  Widget _buildSmallStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.sp, color: AppColors.grey),
        SizedBox(width: 4.w),
        Text(
          text,
          style: AppStyle.font400(AppColors.grey).copyWith(fontSize: 11.sp),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32.w),
              decoration: BoxDecoration(
                color: AppColors.primary?.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.download_outlined,
                size: 80.sp,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 32.h),
            Text(
              'Yuklab olingan audio kitoblar yo\'q',
              style: AppStyle.font600(AppColors.black).copyWith(fontSize: 20.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Text(
              'Audio kitoblarni yuklab olib, istalgan vaqtda\noffline rejimda tinglang',
              style: AppStyle.font400(AppColors.grey).copyWith(fontSize: 14.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40.h),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.explore_rounded),
              label: Text('Kitoblarni ko\'rish'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';

    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        return 'Bugun';
      } else if (diff.inDays == 1) {
        return 'Kecha';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} kun oldin';
      } else {
        return '${date.day}.${date.month}.${date.year}';
      }
    } catch (e) {
      return '';
    }
  }
}
