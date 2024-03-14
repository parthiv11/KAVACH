// import 'dart:io';
// import 'dart:typed_data';
import 'package:photo_gallery/photo_gallery.dart';
import 'package:flutter/material.dart';

class Gallery extends StatefulWidget {
  const Gallery({super.key});

  @override
  State<Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> {

  @override
  void initState() {
    testAlbum();
    super.initState();
  }
  void testAlbum() async {
    final List<Album> imageAlbums = await PhotoGallery.listAlbums();
    final MediaPage imagePage = await imageAlbums[0].listMedia();
    final List<int> data = await imageAlbums[0].getThumbnail();


    print(data);
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Gallery'),
    ),
    body: const Center(
      child:  Text('Gallery'),
    ),
  );
}
}
  