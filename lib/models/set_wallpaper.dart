import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:memories/models/show_toast.dart';

class SetWallpaper {
  final String imagePath;

  SetWallpaper({required this.imagePath});
  
  static const platform = MethodChannel('com.example/wallpaper');
  String wallpaperStatus = 'Not set';

  Future<String> setWallpaper() async {
    String status;
    try {
      final bool result = await platform.invokeMethod('setWallpaper', {
        'path': imagePath,
      });
      status =
          result ? 'Wallpaper set successfully!' : 'Failed to set wallpaper';
          if(kDebugMode) print('Wallpaper set status: $status');
      if(result) ShowToast('Wallpaper set successfully', true);
    } on PlatformException catch (e) {
      status = "Error setting wallpaper: '${e.message}'.";
    }

    return status;
  }
}
