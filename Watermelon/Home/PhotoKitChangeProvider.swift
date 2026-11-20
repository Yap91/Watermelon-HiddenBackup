import Foundation
@preconcurrency import Photos

func libraryAssetMediaKind(for asset: PHAsset) -> AlbumMediaKind {
    if PhotoLibraryService.isLivePhoto(asset) {
        return .livePhoto
    }
    if asset.mediaType == .video {
        return .video
    }
    return .photo
}

func snapshot(_ asset: PHAsset) -> LibraryAssetSnapshot {
    LibraryAssetSnapshot(
        localIdentifier: asset.localIdentifier,
        creationDate: asset.creationDate,
        modificationDate: asset.modificationDate,
        mediaKind: libraryAssetMediaKind(for: asset)
    )
}

func snapshots(
    of fetchResult: PHFetchResult<PHAsset>,
    requiringHiddenAssets: Bool = false
) -> [LibraryAssetSnapshot] {
    var built: [LibraryAssetSnapshot] = []
    built.reserveCapacity(fetchResult.count)
    for index in 0 ..< fetchResult.count {
        let asset = fetchResult.object(at: index)
        guard !requiringHiddenAssets || HiddenAssetSelectionPolicy.accepts(asset) else { continue }
        built.append(snapshot(asset))
    }
    return built
}
