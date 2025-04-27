import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:scroll_to_hide/scroll_to_hide.dart';

// class PhotosScreen extends StatelessWidget {
//   final AssetEntity photoUrl;
//   final int index;

//   const PhotosScreen({super.key, required this.photoUrl, required this.index});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//         margin: EdgeInsets.all(1.0),
//         child: AssetEntityImage(
//             photoUrl,
//             fit: BoxFit.cover,
//             isOriginal: false,
//             thumbnailSize: const ThumbnailSize.square(200), // Preferred value.
//             thumbnailFormat: ThumbnailFormat.jpeg, // Defaults to `jpeg`.
//           ),
//       );
//   }
// }

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => PhotosScreenState();
}

class PhotosScreenState extends State<PhotosScreen> {
  final scrollController = ScrollController();
  int page = 0, pageCount = 80;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        setState(() {
          // increase the page count by 80 when the user scrolls to the bottom
          pageCount += 80;

          // jump to the bottom of the list
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        });
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Future<List<AssetEntity>> loadMedia() async {
    return await PhotoManager.getAssetListPaged(
      page: page,
      pageCount: pageCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Images in grid view
          Scrollbar(
            controller: scrollController,
            thumbVisibility: true,
            thickness: 8,
            interactive: true,
            radius: const Radius.circular(10),
            child: mediaGridBuilder(),
          ),

          // App bar
          ScrollToHide(
            scrollController: scrollController,
            hideDirection: Axis.vertical,
            height: 50, // The initial height of the widget.
            child: appBar(),
          ),
        ],
      ),
    );
  }

  Widget mediaGridBuilder() {
    return FutureBuilder(
      future: loadMedia(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading images'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No images found'));
        } else {
          final List<AssetEntity> images = snapshot.data!;
          return GridView.builder(
            addAutomaticKeepAlives: true,
            padding: EdgeInsets.fromLTRB(
              0,
              MediaQuery.sizeOf(context).height * 0.08,
              8,
              0,
            ),
            key: const PageStorageKey<String>('gridView'),
            physics: const BouncingScrollPhysics(),
            controller: scrollController,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.0,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.all(1.0),
                child: AssetEntityImage(
                  images[index],
                  fit: BoxFit.cover,
                  isOriginal: false,
                  thumbnailSize: const ThumbnailSize.square(
                    200,
                  ), // Preferred value.
                  thumbnailFormat: ThumbnailFormat.jpeg, // Defaults to `jpeg`.
                ),
              );
            },
          );
        }
      },
    );
  }

  Widget appBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
      ),
      height: MediaQuery.sizeOf(context).height * 0.08,
      width: MediaQuery.sizeOf(context).width,
      padding: const EdgeInsets.fromLTRB(20, 10, 5, 10),
      child: Center(
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Photos', style: TextStyle(color: Colors.white, fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
