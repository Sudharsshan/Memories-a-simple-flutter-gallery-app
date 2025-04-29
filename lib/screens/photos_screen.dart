import 'dart:io'; // Import for File
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:glossy/glossy.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:memories/models/cache_thumbnail.dart'; // Keep your custom cache
import 'package:path_provider/path_provider.dart'; // For getting cache directory
import 'package:flutter_cache_manager/flutter_cache_manager.dart'; //alternative

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => PhotosScreenState();
}

class PhotosScreenState extends State<PhotosScreen> {
  final scrollController = ScrollController();
  final ThumbnailCache thumbnailCache = ThumbnailCache();
  int page = 0;
  int pageCount = 80;
  bool isLoadingMore = false;
  List<AssetEntity> _allAssets = [];
  // Cache directory for storing thumbnails
  late String _cacheDir;
  bool _isCacheInitialized = false;
  final CacheManager _cacheManager = CacheManager(
    Config(
      'customCacheKey',
      maxNrOfCacheObjects: 200,
      stalePeriod: const Duration(days: 7),
    ),
  );

  @override
  void initState() {
    super.initState();
    _initCache().then((_) {
      _loadInitialMedia();
      _initializeScrollListener();
    });
  }

  Future<void> _initCache() async {
    final directory = await getApplicationCacheDirectory();
    _cacheDir = directory.path;
    _isCacheInitialized = true;
    if (kDebugMode) {
      print('Cache directory initialized: $_cacheDir');
    }
  }

  Future<void> _loadInitialMedia() async {
    if (kDebugMode) {
      print('Attempting to load initial media.');
    }
    final PermissionState permissionState =
        await PhotoManager.requestPermissionExtend();
    if (kDebugMode) {
      print('Permission state: $permissionState');
    }
    if (permissionState.isAuth) {
      final assets = await loadMedia(page: 0, pageCount: pageCount);
      _allAssets.addAll(assets);
      if (kDebugMode) {
        print('Loaded ${_allAssets.length} initial assets.');
      }
      _preloadThumbnails(assets);
      if (mounted) {
        setState(() {});
      }
    } else {
      if (kDebugMode) {
        print('Photos permission not granted.');
      }
      if (mounted) {
        setState(() {}); // Trigger a rebuild to show a message in the UI
      }
    }
  }

  void _initializeScrollListener() {
    scrollController.addListener(() {
      final maxScroll = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.position.pixels;

      if (maxScroll > 0 && currentScroll >= 0.7 * maxScroll && !isLoadingMore) {
        isLoadingMore = true;
        page++;
        if (mounted) {
          setState(() {}); //set state before loading
        }
        _loadMoreMedia();
      }
    });
  }

  Future<void> _loadMoreMedia() async {
    if (kDebugMode) {
      print('Attempting to load more media - Page: $page, Count: $pageCount');
    }
    final newAssets = await loadMedia(page: page, pageCount: pageCount);
    _allAssets.addAll(newAssets);
    if (kDebugMode) {
      print(
      'Loaded ${newAssets.length} more assets. Total: ${_allAssets.length}',
    );
    }
    _preloadThumbnails(newAssets);
    if (mounted) {
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  Future<void> _preloadThumbnails(List<AssetEntity> assets) async {
    if (!_isCacheInitialized) {
      if (kDebugMode) {
        print('Cache not initialized, skipping thumbnail preloading.');
      }
      return;
    }

    for (final asset in assets) {
      try {
        if (thumbnailCache.get(asset.id) == null) {
          if (kDebugMode) {
            print('Thumbnail not in cache for asset: ${asset.id}');
          }
          File? cachedFile =
              (await _cacheManager.getFileFromCache(asset.id)) as File?;

          if (cachedFile != null) {
            if (kDebugMode) {
              print('Thumbnail found in cache for asset: ${asset.id}');
            }
            final bytes = await cachedFile.readAsBytes();
            thumbnailCache.put(asset.id, bytes);
          } else {
            if (kDebugMode) {
              print('Generating thumbnail for asset: ${asset.id}');
            }
            final bytes = await asset.thumbnailData;
            if (bytes != null) {
              thumbnailCache.put(asset.id, bytes);
              await _cacheManager.putFile(
                asset.id,
                bytes,
                fileExtension: 'jpg', // Important:  Specify extension
              );
              if (kDebugMode) {
                print('Thumbnail saved to cache for asset: ${asset.id}');
              }
            } else {
              if (kDebugMode) {
                print('Failed to generate thumbnail data for asset: ${asset.id}');
              }
            }
          }
        } else {
          if (kDebugMode) {
            print('Thumbnail already in cache for asset: ${asset.id}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error preloading thumbnail for ${asset.id}: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    PhotoCachingManager().cancelCacheRequest();
    super.dispose();
  }

  Future<List<AssetEntity>> loadMedia({
    required int page,
    required int pageCount,
  }) async {
    if (kDebugMode) {
      print('loadMedia called - Page: $page, Count: $pageCount');
    }
    final assetList = await PhotoManager.getAssetListPaged(
      page: page,
      pageCount: pageCount,
    );
    if (kDebugMode) {
      print('getAssetListPaged returned ${assetList.length} assets.');
    }
    PhotoCachingManager().requestCacheAssets(
      assets: assetList,
      option: ThumbnailOption(
        size: ThumbnailSize.square(140),
        format: ThumbnailFormat.jpeg,
      ),
    );
    return assetList;
  }

  // Removed didChangeDependencies for now

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
          GlossyContainer(
            height: MediaQuery.sizeOf(context).height * 0.08,
            width: MediaQuery.sizeOf(context).width,
            strengthX: 15,
            strengthY: 10,
            child: appBar(),
          ),
        ],
      ),
    );
  }

  Widget mediaGridBuilder() {
    if (_allAssets.isEmpty) {
      if (isLoadingMore) {
        return const Center(child: CircularProgressIndicator());
      }
      return const Center(child: Text('No images found'));
    }
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
      itemCount: _allAssets.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.all(1.0),
          child: AssetEntityImage(
            _allAssets[index],
            fit: BoxFit.cover,
            isOriginal: false,
            thumbnailSize: const ThumbnailSize.square(140), // Preferred value.
            thumbnailFormat: ThumbnailFormat.png,
          ),
        );
      },
    );
  }

  Widget appBar() {
    return Container(
      color: const Color.fromARGB(100, 255, 255, 255),
      padding: const EdgeInsets.fromLTRB(20, 10, 5, 10),
      child: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Photos',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
