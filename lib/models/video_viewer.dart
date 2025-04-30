import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:media_kit/media_kit.dart'; // Provides [Player], [Media], [Playlist] etc.
import 'package:media_kit_video/media_kit_video.dart'; // Provides [VideovideoController] & [Video] etc.

class VideoViewer extends StatefulWidget {
  final AssetEntity videoFile;

  const VideoViewer({super.key, required this.videoFile});

  @override
  VideoViewerState createState() => VideoViewerState();
}

class VideoViewerState extends State<VideoViewer> {
  late final Player player = Player();
  late final videoController = VideoController(player);
  late File? videoFileData;
  bool isVideoLoading = true;
  @override
  void initState() {
    super.initState();
    MediaKit.ensureInitialized();

    // load the video file
    loadvideo();

    // open the loaded video file in the player
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

void loadvideo() async {
    File? file;
    try {
      file = await widget.videoFile.file; // Use .file instead of .originFile
      if (file == null) {
        print('Error: Could not get the video file.');
        setState(() {
          isVideoLoading = false;
        });
        return;
      }
      videoFileData = file;
      print('Loaded file data: ${videoFileData?.path}'); // Log the path
    } catch (e) {
      print('Cannot access the video file: $e');
      setState(() {
        isVideoLoading = false;
      });
      return;
    }

    try {
      final playable = videoFileData!.path;
      player.open(Media(playable), play: true);
      setState(() {
        isVideoLoading = false;
      });
      print('Loaded video successfully from path: ${videoFileData!.path}');

      // trying to play after a short delay
      Future.delayed(const Duration(milliseconds: 500), (){
        if(player.state.playing){
          player.play();
          print('Attempting to play video after a short delay');
        }
      });
    } catch (e) {
      print('Unable to open media: $e');
      setState(() {
        isVideoLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isVideoLoading
        ? Center(child: CircularProgressIndicator.adaptive())
        : Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          height: MediaQuery.sizeOf(context).height,
          width: MediaQuery.sizeOf(context).width,
          child: GestureDetector(
            onTap: () {
              videoController.player.playOrPause();
            },
            child:
                isVideoLoading
                    ? const Center(child: CircularProgressIndicator.adaptive())
                    : Video(controller: videoController),
          ),
        );
  }
}
