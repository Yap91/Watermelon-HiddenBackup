import UIKit

@MainActor
class AppNavigationController: UINavigationController {
#if compiler(>=6.3)
    @available(iOS 27.1, *)
    override var preferredVerticalBarBehavior: UIVerticalBarBehavior { .disabled }

    @available(iOS 27.1, *)
    override var childForPreferredVerticalBarBehavior: UIViewController? { nil }
#endif
}
