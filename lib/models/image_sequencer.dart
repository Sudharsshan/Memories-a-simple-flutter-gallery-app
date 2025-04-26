import 'package:photo_manager/photo_manager.dart';

class ImageSequencer {
  Future<List<AssetEntity>> getImages() async{
  final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList();

  return await paths[0].getAssetListPaged(page: 0, size: 100);
  }
}