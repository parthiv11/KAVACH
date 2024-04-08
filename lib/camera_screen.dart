import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:photo_gallery/photo_gallery.dart';

import 'gallery_screen.dart';
import 'utils/utils.dart';
import 'utils/api_utils.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  CameraScreen({
    Key? key,
    required this.cameras,
  }) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late int selectedCamera = 0;
  late List<Medium> _images;
  late File thumbnail;

  @override
  void initState() {
    super.initState();
    generateAndSecureStoreKey();
    initializeCamera(selectedCamera);
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    final List<Album> albums = await PhotoGallery.listAlbums(
      mediumType: MediumType.image,
      newest: true,
    );
    if (albums.isNotEmpty) {
      final Album recentImagesAlbum = albums.first;
      final MediaPage mediaPage = await recentImagesAlbum.listMedia();
      setState(() async {
        _images = mediaPage.items;
        thumbnail = await _images.first.getFile();
      });
    }
  }

  void initializeCamera(int cameraIndex) async {
    _controller = CameraController(
      widget.cameras[cameraIndex],
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_controller);
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    if (widget.cameras.length > 1) {
                      setState(() {
                        selectedCamera = selectedCamera == 0 ? 1 : 0;
                        initializeCamera(selectedCamera);
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No secondary camera found'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.switch_camera_rounded,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await _initializeControllerFuture;
                    var xFile = await _controller.takePicture();
                    setState(() async {
                      await storeAndSaveHiddenImage(File(xFile.path));
                    });
                  },
                  child: Container(
                    height: 60,
                    width: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Gallery(images: _images),
                      ),
                    );
                  },
                  child: Container(
                    height: 60,
                    width: 60,
                    decoration: _images.isNotEmpty
                        ? BoxDecoration(
                      border: Border.all(color: Colors.white),
                      image: DecorationImage(
                        image: FileImage(thumbnail),
                        fit: BoxFit.cover,
                      ),
                    )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
