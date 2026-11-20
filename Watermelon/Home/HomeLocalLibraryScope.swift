import Foundation

enum HomeLocalLibraryScope: Hashable, Sendable {
    case device(PhotoLibraryMediaFilter)
    case hidden
    case albums(Set<String>)

    var deviceMediaFilter: PhotoLibraryMediaFilter? {
        guard case .device(let filter) = self else { return nil }
        return filter
    }

    var isEntireLibrary: Bool { self == .device(.all) }

    var isSpecificAlbums: Bool {
        if case .albums = self { return true }
        return false
    }

    var selectedAlbumIdentifiers: Set<String> {
        switch self {
        case .device, .hidden:
            return []
        case .albums(let ids):
            return ids
        }
    }

    var photoLibraryQuery: PhotoLibraryQuery {
        switch self {
        case .device(let filter):
            return .library(filter)
        case .hidden:
            return .hidden
        case .albums(let ids):
            return .albums(ids)
        }
    }
}

struct HomeMediaBrowserScopeConfiguration: Equatable, Sendable {
    let localQuery: PhotoLibraryQuery
    let includesRemoteContent: Bool
    let hiddenOnly: Bool

    init(scope: HomeLocalLibraryScope) {
        localQuery = scope.photoLibraryQuery
        hiddenOnly = scope == .hidden
        // A remote index is not scoped to the device's hidden smart album. Mixing it into this
        // browser could surface ordinary remote photos while the UI still says Hidden Photos Only.
        includesRemoteContent = !hiddenOnly
    }
}
