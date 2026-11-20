import UIKit
import MoreKit

@MainActor
extension UIViewController {
    func presentWatermelonPaywall(highlighting feature: WatermelonProFeature? = nil) {
        _ = feature
    }

    @discardableResult
    func presentProUpgradeIfNeeded(for error: Error) -> Bool {
        _ = error
        return false
    }
}
