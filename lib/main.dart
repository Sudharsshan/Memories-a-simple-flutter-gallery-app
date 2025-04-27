import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
//import 'package:memories/screens/settings_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:memories/screens/photos_screen.dart';
import 'package:memories/screens/folders_screen.dart';

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
  void initState(){
    super.initState();
  }

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: PageView(
        controller: pageController,
        
        onPageChanged: (index){
          setState(() {
            currentPage = index;
          });
        },
        children: [
          PhotosScreen(),

          FoldersScreen(),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.photo),
            label: 'Photos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Folders',
          ),
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
      )
    ),
    );
  }
}