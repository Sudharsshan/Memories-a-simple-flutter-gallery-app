import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class CachedThumbnail extends StatefulWidget {
  final AssetEntity asset;
  final ThumbnailCache cache;

  const CachedThumbnail({
    super.key,
    required this.asset,
    required this.cache,
  });

  @override
  State<CachedThumbnail> createState() => _CachedThumbnailState();
}

class _CachedThumbnailState extends State<CachedThumbnail> 
    with AutomaticKeepAliveClientMixin {
  Uint8List? _thumbnailData;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final cached = widget.cache.get(widget.asset.id);
    if (cached != null) {
      if (mounted) setState(() => _thumbnailData = cached);
      return;
    }

    final bytes = await widget.asset.thumbnailData;
    if (bytes != null && mounted) {
      widget.cache.put(widget.asset.id, bytes);
      setState(() => _thumbnailData = bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      margin: const EdgeInsets.all(1.0),
      child: _thumbnailData != null
          ? Image.memory(
              _thumbnailData!,
              fit: BoxFit.cover,
              cacheHeight: 200,
              cacheWidth: 200,
            )
          : const ColoredBox(color: Colors.grey, child: Icon(Icons.dangerous),),
    );
  }
}

/// Simple in-memory cache for thumbnails
class ThumbnailCache {
  // Singleton pattern
  static final ThumbnailCache _instance = ThumbnailCache._internal();
  factory ThumbnailCache() => _instance;
  ThumbnailCache._internal();

  final Map<String, Uint8List> _cache = {};

  Uint8List? get(String id) => _cache[id];
  void put(String id, Uint8List bytes) => _cache[id] = bytes;
  void clear() => _cache.clear();
}