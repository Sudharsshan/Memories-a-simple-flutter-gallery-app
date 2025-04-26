import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class PhotosScreen extends StatelessWidget {
  final AssetEntity photoUrl;
  final int index;

  const PhotosScreen({super.key, required this.photoUrl, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.all(2.0),
        child: AssetEntityImage(
            photoUrl,
            fit: BoxFit.cover,
            isOriginal: false,
          ),
      );
  }
}