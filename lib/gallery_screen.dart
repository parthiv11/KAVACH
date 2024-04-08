import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kavach/verify.dart';
import 'package:photo_gallery/photo_gallery.dart';
import 'utils/utils.dart';
import 'utils/api_utils.dart';

class Gallery extends StatefulWidget {
  final List<Medium> images;

  const Gallery({Key? key, required this.images}) : super(key: key);

  @override
  State<Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Images'),
      ),
      body: widget.images.isEmpty
          ? const Center(child: Text('No recent images'))
          : GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4.0,
          mainAxisSpacing: 4.0,
        ),
        itemCount: widget.images.length,
        itemBuilder: (BuildContext context, int index) {
          return _buildImageItem(widget.images[index]);
        },
      ),
    );
  }

  Widget _buildImageItem(Medium image) {
    return GestureDetector(
      onTap: () async {
        File file = await image.getFile();
        bool truth = await extractAndVerify(file);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImage(
              imageFile: file,
              truth: truth,
            ),
          ),
        );
      },
      child: FutureBuilder<File>(
        future: image.getFile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData) {
            return Text('No data');
          } else {
            return Image.file(
              snapshot.data!,
              fit: BoxFit.cover,
            );
          }
        },
      ),
    );
  }
}
