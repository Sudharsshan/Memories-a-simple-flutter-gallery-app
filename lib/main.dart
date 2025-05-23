import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:memories/models/show_toast.dart';
import 'package:memories/screens/photos_screen.dart';
import 'package:memories/screens/folders_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:media_kit/media_kit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  //Necessary Initialization for package:media_kit
  MediaKit.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  Memories createState() => Memories();
}

class Memories extends State<MyApp> {
  PageController pageController = PageController(
    initialPage: 0,
    keepPage: true,
    viewportFraction: 1.0,
  );
  int currentPage = 0;

  @override
  void initState() {
    super.initState();

    // Set UI to higher FPS if possible
    setOptimalDisplayMode;
    
    // Request permission to access media
    requestPermission();
  }

  void requestPermission() async {
    // Obtain the current running android version
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    final AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
    final int androidVersion = androidInfo.version.sdkInt;

    bool permissionGranted = false;

    if(Platform.isAndroid){
      if (androidVersion >= 33){
        // Android 13 and above
        final mediaPermissionStatus = await Permission.photos.request();
        final videoPermissionStatus = await Permission.videos.request();
        permissionGranted = mediaPermissionStatus.isGranted && videoPermissionStatus.isGranted;
      } else if (androidVersion >= 29){
        // Android 10 and above (12)
        final storageStatus = await Permission.storage.request();
        permissionGranted = storageStatus.isGranted;
      } else {
        // Android 9 and below (8)
        final storageStatus = await Permission.storage.request();
        final writeStatus = await Permission.manageExternalStorage.request();
        permissionGranted = storageStatus.isGranted && writeStatus.isGranted;
      }

      if(permissionGranted){
        // Permission granted, proceed with accessing media
        flutterToastmsg('Permission granted to access media');
        if (kDebugMode) {
          print('Permission granted');
        }
      } else {
        // Permission denied, Show a snackBar to allow permission
        flutterToastmsg('Please allow permission to access media if denied...');
        // Navigate the user to settings screen to allow permission
        if(await Permission.storage.isPermanentlyDenied || await Permission.photos.isPermanentlyDenied || await Permission.videos.isPermanentlyDenied){
          // Open app settings to allow permission
          await openAppSettings();
        } 
      }
    }
  }

  Future<void> setOptimalDisplayMode() async {
    final List<DisplayMode> supported = await FlutterDisplayMode.supported;
    final DisplayMode active = await FlutterDisplayMode.active;

    final List<DisplayMode> sameResolution = supported.where(
            (DisplayMode m) => m.width == active.width
                && m.height == active.height).toList()..sort(
            (DisplayMode a, DisplayMode b) =>
                b.refreshRate.compareTo(a.refreshRate));

    final DisplayMode mostOptimalMode = sameResolution.isNotEmpty
        ? sameResolution.first
        : active;

    /// This setting is per session.
    /// Please ensure this was placed with `initState` of your root widget.
    await FlutterDisplayMode.setPreferredMode(mostOptimalMode);
  }

  void flutterToastmsg(String message){
    ShowToast(message, true).flutterToastmsg();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color.fromRGBO(255, 64, 129, 1);
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: true).copyWith(
        scrollbarTheme: ScrollbarThemeData().copyWith(
          thumbColor: WidgetStatePropertyAll(themeColor),
        )
      ),
      darkTheme: ThemeData.from(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeColor,
          brightness: Brightness.dark,
          primary: themeColor,
          secondary: themeColor,
          // ignore: deprecated_member_use
          background: const Color.fromARGB(255, 0, 0, 0),
          surface: const Color.fromARGB(255, 0, 0, 0),
        ),
      ).copyWith(
        primaryColor: Color.fromARGB(255, 0, 0, 0),
        scrollbarTheme: ScrollbarThemeData().copyWith(
          thumbColor: WidgetStatePropertyAll(themeColor),
        )
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: PageView(
            controller: pageController,

            onPageChanged: (index) {
              setState(() {
                currentPage = index;
              });
            },
            children: [const PhotosScreen(), const FoldersScreen()],
          ),
        ),

        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.photo), label: 'Photos'),
            BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Folders'),
          ],
          currentIndex: currentPage,
          selectedItemColor: themeColor,
          onTap: (index) {
            setState(() {
              // Handle bottom navigation bar item tap
              currentPage = index;
              pageController.jumpToPage(index);
            });
          },
        ),
      ),
    );
  }
}
