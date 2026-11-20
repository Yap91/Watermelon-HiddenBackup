import Foundation
import Photos

@MainActor
final class HomeScopeNormalizer {
    typealias Alert = LocalDataSourceError

    struct Hooks {
        var authorizationStatus: () -> PHAuthorizationStatus
        var existingUserAlbumIdentifiers: (Set<String>) -> Set<String>
        var validateHiddenSelection: () throws -> Void

        init(
            authorizationStatus: @escaping () -> PHAuthorizationStatus,
            existingUserAlbumIdentifiers: @escaping (Set<String>) -> Set<String>,
            validateHiddenSelection: @escaping () throws -> Void = {}
        ) {
            self.authorizationStatus = authorizationStatus
            self.existingUserAlbumIdentifiers = existingUserAlbumIdentifiers
            self.validateHiddenSelection = validateHiddenSelection
        }
    }

    private let hooks: Hooks
    private var lastAlertTime: CFAbsoluteTime = 0
    var albumNames: [String: String] = [:]
    var onAlert: ((LocalDataSourceError) -> Void)?

    init(hooks: Hooks) {
        self.hooks = hooks
    }

    func normalize(_ scope: HomeLocalLibraryScope) -> (scope: HomeLocalLibraryScope, alert: Alert?) {
        if scope == .hidden {
            do {
                try hooks.validateHiddenSelection()
                return (scope, nil)
            } catch let error as LocalDataSourceError {
                return (scope, error)
            } catch {
                return (scope, .sourceUnavailable)
            }
        }
        guard case .albums(let ids) = scope else { return (scope, nil) }
        let authorization = hooks.authorizationStatus()
        guard authorization == .authorized || authorization == .limited else { return (scope, nil) }
        do {
            try LocalDataSourceError.validateAlbums(
                ids, authorization: authorization,
                existing: { hooks.existingUserAlbumIdentifiers(ids) }, names: albumNames
            )
            return (scope, nil)
        } catch let error as LocalDataSourceError {
            return (scope, error)
        } catch {
            return (scope, .sourceUnavailable)
        }
    }

    func emitAlertIfNotDebounced(_ alert: Alert) {
        let now = CFAbsoluteTimeGetCurrent()
        guard now - lastAlertTime >= 2 else { return }
        lastAlertTime = now
        onAlert?(alert)
    }
}
