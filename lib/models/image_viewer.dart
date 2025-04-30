import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImageViewer extends StatelessWidget {
  final Future<Uint8List?>? imageDataFuture;

  const ImageViewer({super.key, required this.imageDataFuture});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<Uint8List?>(
        future: imageDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return const Text('Error loading image');
          } else if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(snapshot.data!);
          } else {
            return const Text('No image data available');
          }
        },
      ),
    );
  }
}
