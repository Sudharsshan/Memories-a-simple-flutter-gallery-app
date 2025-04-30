import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:memories/models/image_share.dart';
import 'package:memories/models/image_viewer.dart';
import 'package:memories/models/show_toast.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart'; // Import for sharing functionality

class BigPhotoScreen extends StatefulWidget {
  final AssetEntity assetData;

  const BigPhotoScreen({super.key, required this.assetData});

  @override
  // ignore: no_logic_in_create_state
  BigPhotoScreenState createState() => BigPhotoScreenState();
}

class BigPhotoScreenState extends State<BigPhotoScreen> {
  bool imageLiked = false;
  late Future<Uint8List?>? imageBytesFuture;

  @override
  void initState() {
    super.initState();
    imageBytesFuture = widget.assetData.originBytes;
  }

  @override
  Widget build(BuildContext context) {
    const Color iconColor = Color.fromRGBO(255, 64, 129, 1);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.assetData.id),
        actions: [
          // Share button
          IconButton(
            onPressed: () {
              // Implement share functionality here
              ImageShare(widget.assetData);
            },
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: GestureDetector(
        onVerticalDragDown: (details) {
          // Handle vertical drag down to close the image viewer
          Navigator.of(context).pop();
        },
        child: Hero(
          tag: widget.assetData.id,
          child: ImageViewer(imageDataFuture: imageBytesFuture),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon:
                imageLiked
                    ? const Icon(Icons.favorite, color: iconColor)
                    : const Icon(
                      Icons.favorite_border_outlined,
                      color: iconColor,
                    ),
            label: 'Like',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.info_outline_rounded, color: iconColor),
            label: 'Info',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.delete_outline, color: iconColor),
            label: 'Delete',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.edit_outlined, color: iconColor),
            label: 'Edit',
          ),
        ],
        onTap: (value) {
          switch (value) {
            case 0:
              // liked this pic
              setState(() {
                imageLiked = !imageLiked;
                if (kDebugMode) {
                  print(
                    'Image \'${widget.assetData.id}\' liked status: $imageLiked',
                  );
                }
              });
              break;
            case 1:
              // show info about this pic
              break;
            case 2:
              // delete this pic
              break;
            case 3:
              // edit this pic
              break;
            default:
              ShowToast('Invalid option', false).flutterToastmsg();
              break;
          }
        },
      ),
    );
  }
}
