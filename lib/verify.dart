import 'package:flutter/material.dart';
import 'package:kavach/camera_screen.dart';
import 'utils/utils.dart';
import 'utils/api_utils.dart';
import 'package:camera/camera.dart';
import 'dart:io';


class FullScreenImage extends StatelessWidget {
  final File imageFile;
  final bool truth;

  const FullScreenImage({super.key,
    required this.imageFile,
    required this.truth,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<bool>(
        future: verifyImage(imageFile),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.data == true) {
            return Image.file(imageFile, fit: BoxFit.contain);
          } else {
            return const Center(child: Text('Image verification failed!!!',style: TextStyle(backgroundColor: Colors.green),));
          }
        },
      ),
    );
  }
}