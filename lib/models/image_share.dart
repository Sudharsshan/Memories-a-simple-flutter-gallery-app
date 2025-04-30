import 'package:flutter/foundation.dart';
import 'package:memories/models/show_toast.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart'; // Import for sharing functionality

class ImageShare {

  final AssetEntity asset;
  ImageShare(this.asset);

  Future<void> shareImage(AssetEntity asset) async {
    if (kDebugMode) {
      print('Sharing image: ${asset.title}');
    }

    try {
      final file = await asset.file;
      if (file == null) {
        ShowToast(
          'Error: Could not access image file',
          false,
        ).flutterToastmsg();
        return;
      }
      final params = ShareParams(text: asset.title, files: [XFile(file.path)]);

      final result = await SharePlus.instance.share(params);

      if (result.status == ShareResultStatus.success) {
        ShowToast('Image shared successfully', false).flutterToastmsg();
      } else if (result.status == ShareResultStatus.dismissed) {
        ShowToast('Dismissed sharing image', false).flutterToastmsg();
      } else {
        ShowToast('Image not shared', false).flutterToastmsg();
      }
    } catch (e) {
      ShowToast('Error sharing: $e', false).flutterToastmsg();
      return;
    }
  }
}