import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memories/screens/big_photo_screen.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class MediaListBuilder extends StatelessWidget {
  final Map<String, List<AssetEntity>> groupedAssets;
  final bool isLoadingMore;
  final ScrollController scrollController;
  final List<String> dateKeys;
  final VoidCallback onDeletion;

  const MediaListBuilder({
    super.key,
    required this.groupedAssets,
    required this.isLoadingMore,
    required this.scrollController,
    required this.dateKeys,
    required this.onDeletion,
  });

  @override
  Widget build(BuildContext context) {
    if (groupedAssets.isEmpty && !isLoadingMore) {
      return const Center(child: Text('No images found'));
    }
    if (isLoadingMore && groupedAssets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      itemCount:
          dateKeys.length +
          (isLoadingMore ? 1 : 0), // Add 1 for the loading indicator
      itemBuilder: (context, index) {
        if (index < dateKeys.length) {
          final date = dateKeys[index];
          final assetsForDate = groupedAssets[date]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add padding at the top for the first item to avoid overlapping with the app bar
              if (index == 0)
                SizedBox(
                  height:
                      MediaQuery.of(context).padding.top +
                      MediaQuery.sizeOf(context).height * 0.08,
                ),

              // Date header
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  _formatDate(date), // Format the date for display
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              // GridView for assets
              GridView.builder(
                padding: const EdgeInsets.only(
                  left: 8.0,
                  right: 8.0,
                  bottom: 8.0,
                ),
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(), // To disable GridView's scrolling
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.0,
                ),
                itemCount: assetsForDate.length,
                itemBuilder: (context, assetIndex) {
                  final asset = assetsForDate[assetIndex];
                  return GestureDetector(
                    onTap: () {
                      // Navigate the user to the photo screen
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  BigPhotoScreen(assetEntity: asset, onDeletion: onDeletion,),
                          transitionsBuilder: (
                            context,
                            animation,
                            secondaryAnimation,
                            child,
                          ) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                    child: Hero(
                      tag: asset.id,
                      child: Container(
                        margin: const EdgeInsets.all(1.0),
                        child: AssetEntityImage(
                          asset,
                          fit: BoxFit.cover,
                          isOriginal: false,
                          thumbnailSize: const ThumbnailSize.square(140),
                          thumbnailFormat: ThumbnailFormat.png,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        } else if (isLoadingMore) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return null; // Should not happen
      },
    );
  }

  String _formatDate(String dateStr) {
    // to show today and yesterday if the dates match
    final parsedDate = DateTime.parse(dateStr);
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (parsedDate.year == now.year &&
        parsedDate.month == now.month &&
        parsedDate.day == now.day) {
      return 'Today';
    } else if (parsedDate.year == yesterday.year &&
        parsedDate.month == yesterday.month &&
        parsedDate.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, y').format(parsedDate);
    }
  }


}
