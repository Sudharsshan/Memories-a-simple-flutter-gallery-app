import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:memories/models/show_toast.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart'; // Import for sharing functionality

class BigPhotoScreen extends StatelessWidget {
  final AssetEntity asset;

  const BigPhotoScreen({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(asset.id),
        actions: [
          // Share button
          IconButton(onPressed: () {
            // Implement share functionality here
            shareImage(asset);
          }, icon: const Icon(Icons.share)),
        ],
      ),
      body: Center(
        child: FutureBuilder<Uint8List>(
          future: _getNonNullOriginBytes(asset),
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
      ),
    );
  }

  Future<Uint8List> _getNonNullOriginBytes(AssetEntity asset) async {
              final bytes = await asset.originBytes;
              if (bytes == null) {
                throw Exception('Image data is null');
              }
              return bytes;
            }

  Future<void> shareImage(AssetEntity asset) async{
    final params = ShareParams(
      text: asset.title,
      files: [XFile(asset.relativePath!)],
    );

    final result = await SharePlus.instance.share(params);
    
    if(result.status == ShareResultStatus.success){
      ShowToast('Image shared successfully', false).flutterToastmsg();
    } else if(result.status == ShareResultStatus.dismissed){
      ShowToast('Dismissed sharing image', false).flutterToastmsg();
    } else {
      ShowToast('Image not shared', false).flutterToastmsg();
    }
  }
}
