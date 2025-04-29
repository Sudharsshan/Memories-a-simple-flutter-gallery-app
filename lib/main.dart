import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:memories/screens/photos_screen.dart';
import 'package:memories/screens/folders_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() {
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

    // Request permission to access media
    requestPermission();
  }

  void requestPermission() async {
    // Request permission to access all media
    await Permission.photos.request();
    await Permission.videos.request();
    await Permission.storage.request();

    final mediaPermissionStatus = await Permission.photos.status;
    final videoPermissionStatus = await Permission.videos.status;
    final storagePermissionStatus = await Permission.storage.status;
    // compare API level to avoid unnecessary permission request
    if (mediaPermissionStatus.isGranted &&
        videoPermissionStatus.isGranted &&
        storagePermissionStatus.isGranted) {
      // Permission granted, proceed with accessing media

      flutterToastmsg('Permission granted to access media');
      if (kDebugMode) {
        print('Permission granted');
      }
    } else {
      // Permission denied

      // Show a snackBar to allow permission
      flutterToastmsg('Please allow permission to access media');
      // Navigate the user to settings screen to allow permission
      await openAppSettings();
      if (kDebugMode) {
        print('Permission denied');
      }
    }
  }

  void flutterToastmsg(String message){
    Fluttertoast.showToast(
        msg: 'Please allow permission to access media',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
          selectedItemColor: Colors.pinkAccent,
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
