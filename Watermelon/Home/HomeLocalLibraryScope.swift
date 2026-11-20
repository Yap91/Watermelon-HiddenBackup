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
