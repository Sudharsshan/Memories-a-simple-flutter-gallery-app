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
  // List<AssetEntity> Media = [];
  final scrollController = ScrollController(
    keepScrollOffset: true,
  ); // Create a scroll controller
  int page = 0, pageCount = 80; // Set the page and page count

  @override
  void initState() {
    super.initState();
    // request read/write permission on first boot and avoid on subsequent if accepted
    requestPermission();

    // Initialise the scroll controller
    scrollController.addListener(loadMore); // Add listener to scroll controller
    getFinalCount();
  }

  void getFinalCount() async {
    pageCount =
        await PhotoManager.getAssetCount(); // Get the total number of assets
  }

  @override
  void dispose() {
    scrollController.removeListener(
      loadMore,
    ); // Remove listener from scroll controller
    scrollController.dispose(); // Dispose of the scroll controller
    super.dispose();
  }

  void loadMore() {
    if (scrollController.offset >= scrollController.position.maxScrollExtent) {
      setState(() {
        if (kDebugMode) {
          print('Loading more images and videos...');
        }
        // load more images and videos
        pageCount += 80; // Increase the page count by 80
        scrollController.jumpTo(
          scrollController.position.maxScrollExtent,
        ); // Jump to the end of the list
        fetchImagesAndVideos();
      });
    }
  }

  void requestPermission() async {
    // request permission to access all media
    await Permission.photos.request();

    // check if the permission is denied
    final mediaPermissionStatus = await Permission.photos.status;
    if (mediaPermissionStatus.isDenied) {
      if (mediaPermissionStatus.isDenied) {
        await openAppSettings();
      }
    } else if (mediaPermissionStatus.isPermanentlyDenied) {
      // Here open app settings for user to manually enable permission in case
      // where permission was permanently denied
      await openAppSettings();
    } else {
      if (kDebugMode) {
        print('Read/write permission obtained');
      }
    }
  }

  Future<List<AssetEntity>> fetchImagesAndVideos() async {
    final List<AssetEntity> entities = await PhotoManager.getAssetListPaged(
      page: page,
      pageCount: pageCount,
    );
    return entities;
  }

  @override
  Widget build(BuildContext context) {
    PageController pageController = PageController(initialPage: 0);

    // Sequence the image paths

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Builder(
            builder:
                (context) => Stack(
                  // App bar
                  children: [
                    PageView(
                      controller: pageController,
                      children: [
                        // Images and videos screen
                        FutureBuilder(
                          future: fetchImagesAndVideos(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            } else {
                              return GridView.builder(
                                key: const PageStorageKey<String>('gridView'),
                                physics: const BouncingScrollPhysics(),
                                addAutomaticKeepAlives: true,
                                controller: scrollController,
                                itemCount: snapshot.data!.length,
                                cacheExtent: 1000,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 4,
                                    ),
                                itemBuilder: (context, index) {
                                  return PhotosScreen(
                                    photoUrl: snapshot.data![index],
                                    index: index,
                                  );
                                },
                              );
                            }
                          },
                        ),

                        // Folders screen
                        const FoldersScreen(),
                      ],
                    ),

                    Container(
                      decoration: BoxDecoration(
                        backgroundBlendMode: BlendMode.darken,
                        color: Colors.black.withOpacity(0.5),
                      ),
                      height: MediaQuery.of(context).size.height * 0.1,
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.fromLTRB(20, 10, 5, 10),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Photos',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom navigation bar
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        color: Colors.white,
                        height: MediaQuery.sizeOf(context).height * 0.08,
                        width: MediaQuery.sizeOf(context).width,
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                        child: BottomNavigationBar(
                          currentIndex: page,
                          selectedItemColor: Colors.amber,
                          unselectedItemColor: Colors.black,
                          onTap: (index) {
                            setState(() {
                              page = index;
                              pageController.jumpToPage(
                                index,
                              ); // Jump to the selected page
                            });
                          },
                          items: const [
                            BottomNavigationBarItem(
                              icon: Icon(Icons.photo, color: Colors.black),
                              label: 'Photos',
                              backgroundColor: Colors.white,
                              activeIcon: Icon(Icons.photo),
                            ),

                            BottomNavigationBarItem(
                              icon: Icon(Icons.folder, color: Colors.black),
                              label: 'Folders',
                              backgroundColor: Colors.white,
                              activeIcon: Icon(Icons.photo),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}
