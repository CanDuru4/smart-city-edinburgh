import UIKit
import FirebaseCore

/// Reports optional account availability without requiring Firebase for map browsing.
/// Example: guard `Backend.isConfigured` before requesting `Auth.auth()`.
enum Backend {
    static var isConfigured: Bool { FirebaseApp.app() != nil }
}

extension UIViewController {
    /// Presents one message on a visible screen without stacking modal alerts.
    /// - Parameters:
    ///   - title: A short, localized explanation.
    ///   - message: Optional detail or recovery instructions.
    /// - Returns: Nothing. Does not throw; invisible screens do not present alerts.
    /// - Example: `showMessage(title: String(localized: "dataError"))`.
    func showMessage(title: String, message: String = "") {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.viewIfLoaded?.window != nil, self.presentedViewController == nil else { return }
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: String(localized: "okButton"), style: .default))
            self.present(alert, animated: true)
        }
    }
}
