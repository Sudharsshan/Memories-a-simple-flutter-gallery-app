import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:memories/models/image_share.dart';
import 'package:memories/models/image_viewer.dart';
import 'package:memories/models/show_toast.dart';
import 'package:memories/models/video_viewer.dart';
import 'package:photo_manager/photo_manager.dart';

class BigPhotoScreen extends StatefulWidget {
  final AssetEntity assetData;

  const BigPhotoScreen({super.key, required this.assetData});

  @override
  // ignore: no_logic_in_create_state
  BigPhotoScreenState createState() => BigPhotoScreenState();
}

class BigPhotoScreenState extends State<BigPhotoScreen>
    with SingleTickerProviderStateMixin {
  bool imageLiked = false;
  late Future<Uint8List?>? imageBytesFuture;

  late AnimationController animationController;
  late Animation<double> scaleAnimation;
  double dragDistance = 0.0;
  final double closeDownThreshold = 100.0,
      infoUpThreshold = 60.0; // Change this value after testing
  bool isDraggingUp = false, isDraggingDown = false;
  bool isVideo = false, isVideoLoading = true;
  late File videoFileData;
  OverlayEntry? overlayEntry;
  final LayerLink layerLink = LayerLink();
  bool isMenuOpen = false;

  @override
  void initState() {
    super.initState();

    // Check if the asset is a video
    isVideo = widget.assetData.type == AssetType.video;
    imageBytesFuture =
        isVideo
            ? null
            : widget
                .assetData
                .originBytes; // do not load data if it's an image to avoid exception error

    // initiate the animation controller
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // initiate the scale animation controller
    scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  void handleVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      dragDistance -=
          details.primaryDelta!; // since it's dragging down it's -ve

      if (dragDistance > 0) {
        // Dragging upwards: show info screen
        isDraggingDown = false;
        isDraggingUp = true;

        animationController.value = (dragDistance.abs() / infoUpThreshold)
            .clamp(0.0, 1.0);
      } else if (dragDistance < 0) {
        // Dragging down: exit the big photo mode
        isDraggingDown = true;
        isDraggingUp = false;
        animationController.value = (dragDistance.abs() / closeDownThreshold)
            .clamp(0.0, 1.0);
      } else {
        isDraggingDown = false;
        isDraggingUp = false;
        animationController.value = 0.0;
      }
    });
  }

  void handleVerticalDragEnd(DragEndDetails details) async {
    if (isDraggingDown &&
        (dragDistance.abs() > closeDownThreshold ||
            details.velocity.pixelsPerSecond.dy > 300)) {
      // Dragged down: exit the big photo mode
      Navigator.of(context).pop();
    } else if (isDraggingUp &&
        (dragDistance.abs() > infoUpThreshold ||
            details.velocity.pixelsPerSecond.dy < -300)) {
      // Dragged up: show file info
      showFileInfoScreen();
      animationController.reverse();
    } else {
      // not enough drag, revert animation
      animationController.reverse();
    }
    setState(() {
      dragDistance = 0.0;
      isDraggingDown = false;
      isDraggingUp = false;
    });
  }

  void showFileInfoScreen() async {
    final DateTime date = widget.assetData.createDateTime;
    final String? mimeType = widget.assetData.mimeType;
    final Size resolution = widget.assetData.size;
    final assetFile = await widget.assetData.file;
    final byteSize = formatFileSize(
      (assetFile?.length() == null) ? 0 : assetFile!.lengthSync(),
    );

    if (mounted) {
      showModalBottomSheet(
        useSafeArea: true,
        enableDrag: true,
        context: context,
        builder: (BuildContext context) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'File Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Divider(),
                const SizedBox(height: 10),
                Text('Date created: ${date.toLocal()}'),
                if (mimeType != null) Text('File Type: $mimeType'),
                Text(
                  'File resolution: ${resolution.height} x ${resolution.width}',
                ),
                Text('File Size: $byteSize'),
                Text('Asset ID: ${widget.assetData.id}'),

                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < pow(1024, 3)) {
      return '${(bytes / pow(1024, 2)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / pow(1024, 3)).toStringAsFixed(2)} GB';
    }
  }

  void showCustommenu() {
    overlayEntry = createOverlayEntry();
    Overlay.of(context).insert(overlayEntry!);
  }

  void hideCustomMenu() {
    overlayEntry?.remove();
    overlayEntry = null;
  }

  OverlayEntry createOverlayEntry() {
    return OverlayEntry(
      builder:
          (context) => Positioned(
            width: 150.0,
            child: CompositedTransformFollower(
              link: layerLink,
              showWhenUnlinked: false,
              offset: const Offset(-80.0, 40.0),
              child: Material(
                elevation: 4.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        hideCustomMenu();
                        ShowToast(
                          'Setting as wallpaper',
                          false,
                        ).flutterToastmsg();
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Set as wallpaper'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
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
              if (kDebugMode) print('User requested to share');
              ImageShare().shareImage(widget.assetData);
            },
            icon: const Icon(Icons.share),
          ),

          // More options button
          PopupMenuButton<String>(
            elevation: 16,
            onSelected: choiceAction,
            itemBuilder: (BuildContext context) {
              return [
                // Set as wallpaper button
                PopupMenuItem<String>(
                  value: 'Set as wallpaper',
                  child: Text('Set as wallpaper'),
                ),
              ];
            },
          ),
        ],
      ),
      body: GestureDetector(
        onVerticalDragUpdate: handleVerticalDragUpdate,
        onVerticalDragEnd: handleVerticalDragEnd,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: Hero(
            tag: widget.assetData.id,
            child:
                (!isVideo)
                    ? ImageViewer(imageDataFuture: imageBytesFuture)
                    : VideoViewer(videoFile: widget.assetData),
          ),
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
              if (kDebugMode) print('User requests file info');
              showFileInfoScreen();
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

  void choiceAction(String menuItem){
    if(kDebugMode) print('User selected : $menuItem');
    // Handle the necessary actions
  }
}
