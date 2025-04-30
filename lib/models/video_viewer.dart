import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:media_kit/media_kit.dart';                      // Provides [Player], [Media], [Playlist] etc.
import 'package:media_kit_video/media_kit_video.dart';          // Provides [VideoController] & [Video] etc.

class VideoViewer extends StatefulWidget {
  final AssetEntity videoFile;

  const VideoViewer({super.key, required this.videoFile});

  @override
  VideoViewerState createState() => VideoViewerState();
}

class VideoViewerState extends State<VideoViewer> {
  late final Player player = Player();
  late final controller = VideoController(player);
  late final File? videoFileData;
  bool isVideoLoading = true;
  @override
  void initState() {
    super.initState();
    MediaKit.ensureInitialized();

    // load the video file
    loadvideo();

    // open the loaded video file in the player
    player.open(Media(videoFileData!.path));
  }

  @override
  void dispose(){
    player.dispose();
    super.dispose();
  }

  void loadvideo() async {
    try{
      videoFileData = await widget.videoFile.file;
    } catch(e){
      print('Cannot find the video file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return isVideoLoading
        ? Center(child: CircularProgressIndicator.adaptive())
        : Container(
          color: Colors.amber,
          child: GestureDetector(
            onTap:
                () {},
            child:
                isVideoLoading? const Center(child: CircularProgressIndicator.adaptive(),): Video(controller: controller),
          ),
        );
  }
}
