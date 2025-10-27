import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sahhof/src/model/audio/audio_model.dart';

import '../../../bloc/book/bookmark/audio_bookmark.dart';

class DownloadedBooksScreen extends StatefulWidget {
  const DownloadedBooksScreen({Key? key}) : super(key: key);

  @override
  State<DownloadedBooksScreen> createState() => _DownloadedBooksScreenState();
}

class _DownloadedBooksScreenState extends State<DownloadedBooksScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load downloaded books
    downloadedBooksBloc.getAllDownloadedBooks();

    // Load total size
    downloadedBooksBloc.getTotalDownloadedSize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchBooks(String query) {
    if (query.isEmpty) {
      downloadedBooksBloc.getAllDownloadedBooks();
    } else {
      downloadedBooksBloc.searchDownloadedBooks(query);
    }
  }

  void _deleteBook(BuildContext context, DownloadedBookModel book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('O\'chirish'),
        content: Text('${book.title} kitobini o\'chirmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Yo\'q'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await downloadedBooksBloc.deleteDownloadedBook(book.bookId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Kitob o\'chirildi')),
                );
              }
            },
            child: Text('Ha', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Yuklab olinganlar'),
        elevation: 0,
        actions: [
          // Total size indicator
          StreamBuilder<int>(
            stream: downloadedBooksBloc.getTotalSizeStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return SizedBox();

              final totalSize = snapshot.data!;
              final formattedSize = _formatSize(totalSize);

              return Center(
                child: Padding(
                  padding: EdgeInsets.only(right: 16.w),
                  child: Row(
                    children: [
                      Icon(Icons.storage, size: 20.sp),
                      SizedBox(width: 4.w),
                      Text(
                        formattedSize,
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _searchController,
              onChanged: _searchBooks,
              decoration: InputDecoration(
                hintText: 'Qidirish...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear),
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
              ),
            ),
          ),

          // Books list
          Expanded(
            child: StreamBuilder<List<DownloadedBookModel>>(
              stream: downloadedBooksBloc.getDownloadedBooksStream,
              builder: (context, snapshot) {
                // Loading
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                // Error
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
                        SizedBox(height: 16.h),
                        Text('Xatolik yuz berdi'),
                        SizedBox(height: 8.h),
                        ElevatedButton(
                          onPressed: () => downloadedBooksBloc.getAllDownloadedBooks(),
                          child: Text('Qayta urinish'),
                        ),
                      ],
                    ),
                  );
                }

                final books = snapshot.data!;

                // Empty state
                if (books.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.download_outlined,
                          size: 80.sp,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Yuklab olingan kitoblar yo\'q',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Kitoblarni yuklab olib, offline tinglang',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Books list
                return RefreshIndicator(
                  onRefresh: () => downloadedBooksBloc.getAllDownloadedBooks(),
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];
                      return _buildBookItem(book);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookItem(DownloadedBookModel book) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to audio player
          // Navigator.push(...);
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              // Cover image
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: CachedNetworkImage(
                  imageUrl: book.coverImage,
                  width: 80.w,
                  height: 100.h,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: Icon(Icons.book, size: 40.sp),
                  ),
                ),
              ),

              SizedBox(width: 12.w),

              // Book info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      book.title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),

                    // Author
                    Text(
                      book.authorName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),

                    // Stats
                    Row(
                      children: [
                        Icon(Icons.storage, size: 16.sp, color: Colors.grey),
                        SizedBox(width: 4.w),
                        Text(
                          book.formattedSize,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Icon(Icons.access_time, size: 16.sp, color: Colors.grey),
                        SizedBox(width: 4.w),
                        Text(
                          book.formattedDuration,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                    // Progress indicator if played before
                    if (book.lastPlayedPosition > 0) ...[
                      SizedBox(height: 8.h),
                      LinearProgressIndicator(
                        value: book.lastPlayedPosition / book.audioDuration,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        minHeight: 3.h,
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(width: 8.w),

              // Delete button
              IconButton(
                onPressed: () => _deleteBook(context, book),
                icon: Icon(Icons.delete_outline, color: Colors.red),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}