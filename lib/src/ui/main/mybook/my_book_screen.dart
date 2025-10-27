import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sahhof/src/model/pdf/pdf_file.dart';
import 'package:sahhof/src/theme/app_colors.dart';
import 'package:sahhof/src/bloc/pdf/pdf_bloc.dart';
import 'package:sahhof/src/ui/main/detail/read/read_screen.dart';

class MyBooksPage extends StatefulWidget {
  @override
  _MyBooksPageState createState() => _MyBooksPageState();
}

class _MyBooksPageState extends State<MyBooksPage> {
  @override
  void initState() {
    super.initState();
    pdfBloc.getPdfFiles(); // 📥 Barcha yuklangan PDF’larni olish
  }

  @override
  void dispose() {
    pdfBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Title
            Text(
              'Mening kitoblarim',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // 🔹 Search Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Kitoblar yoki mualliflarni qidiring...',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 🔹 Books List from Stream
            Expanded(
              child: StreamBuilder<List<PdfFile>>(
                stream: pdfBloc.pdfStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text("Xatolik: ${snapshot.error}"));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("Hozircha yuklangan kitoblar yo‘q"));
                  }

                  final pdfs = snapshot.data!;

                  return ListView.separated(
                    itemCount: pdfs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final book = pdfs[index];
                      return _buildBookItem(
                        book.coverImage,
                        book.title,
                        book.path,
                        book.author,
                        book.downloadDate,
                        (book.size / 1024 / 1024).toStringAsFixed(1) + " MB",
                            () {
                          // PDF faylni ochish (agar kerak bo‘lsa)
                          File file = File(book.path);
                          if (file.existsSync()) {
                            // PDF ko‘ruvchi sahifaga o‘tish yoki ochish
                          }
                        },
                            () async {
                          await pdfBloc.deletePdf(book.id);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookItem(
      String imagePath,
      String title,path,
      String author,
      String downloadDate,
      String size,
      VoidCallback onOpen,
      VoidCallback onDelete,
      ) {
    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (builder){
          return ReadScreen(bookTitle: title, pdfPath: path);
        }));
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 🔸 Book Cover
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: imagePath.startsWith('http')
                      ? NetworkImage(imagePath)
                      : FileImage(File(imagePath)) as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 🔸 Book Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(author,
                      style:
                      TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text(
                    "Yuklangan: $downloadDate",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Text(size,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                      const Spacer(),

                      // 🔹 Ochish tugmasi
                      IconButton(
                        icon: const Icon(Icons.open_in_new,
                            color: Colors.blue, size: 20),
                        onPressed: onOpen,
                      ),

                      // 🔹 O‘chirish tugmasi
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.redAccent, size: 20),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
