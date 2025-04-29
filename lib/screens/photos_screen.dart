import 'dart:io'; // Import for File
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:glossy/glossy.dart';
import 'package:memories/models/custom_app_bar.dart';
import 'package:memories/models/media_list_builder.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:memories/models/cache_thumbnail.dart'; // Keep your custom cache
import 'package:path_provider/path_provider.dart'; // For getting cache directory
import 'package:flutter_cache_manager/flutter_cache_manager.dart'; //alternative
import 'package:intl/intl.dart'; // For date formatting

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  final scrollController = ScrollController();
  final ThumbnailCache thumbnailCache = ThumbnailCache();
  int page = 0;
  int pageCount = 80;
  bool isLoadingMore = false;
  Map<String, List<AssetEntity>> _groupedAssets = {};
  List<String> _dateKeys = []; // To maintain the order of dates
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
    final PermissionState permissionState = await PhotoManager.requestPermissionExtend();
    if (kDebugMode) {
      print('Permission state: $permissionState');
    }
    if (permissionState.isAuth) {
      final assets = await loadMedia(page: 0, pageCount: pageCount);
      _groupAssetsByDate(assets);
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
    _groupAssetsByDate(newAssets, append: true);
    _preloadThumbnails(newAssets);
    if (mounted) {
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  void _groupAssetsByDate(List<AssetEntity> assets, {bool append = false}) {
    final newGroups = <String, List<AssetEntity>>{};
    for (final asset in assets) {
      final dateTime = asset.createDateTime;
      final formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);
      if (!newGroups.containsKey(formattedDate)) {
        newGroups[formattedDate] = [];
      }
      newGroups[formattedDate]!.add(asset);
    }

    if (!append) {
      _groupedAssets = newGroups;
      _dateKeys = _groupedAssets.keys.toList()..sort((a, b) => b.compareTo(a)); // Sort dates in descending order
    } else {
      newGroups.forEach((date, assets) {
        if (_groupedAssets.containsKey(date)) {
          _groupedAssets[date]!.addAll(assets);
        } else {
          _groupedAssets[date] = assets;
          _dateKeys.add(date);
          _dateKeys.sort((a, b) => b.compareTo(a)); // Maintain descending order
        }
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
          File? cachedFile = (await _cacheManager.getFileFromCache(asset.id)) as File?;

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

  Future<List<AssetEntity>> loadMedia({required int page, required int pageCount}) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Grouped images in a ListView
          Scrollbar(
            controller: scrollController,
            thumbVisibility: true,
            trackVisibility: false,
            thickness: 8,
            interactive: true,
            radius: const Radius.circular(10),
            child: MediaListBuilder(groupedAssets: _groupedAssets, isLoadingMore: isLoadingMore, scrollController: scrollController, dateKeys: _dateKeys),
          ),
          // App bar
          GlossyContainer(
            height: MediaQuery.sizeOf(context).height * 0.08,
            width: MediaQuery.sizeOf(context).width,
            strengthX: 15,
            strengthY: 10,
            border: Border.all(
              color: Brightness.light == Theme.of(context).brightness ? const Color.fromARGB(100, 255, 255, 255) : const Color.fromARGB(99, 0, 0, 0),
              width: 1.0,
            ),
            child: const CustomAppBar(),
          ),
        ],
      ),
    );
  }

  
}