import UIKit
import SwiftUI

final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let hostingController = UIHostingController(
            rootView: DropZoneShareView(
                onSave: { [weak self] in self?.save() },
                onCancel: { [weak self] in self?.cancel() }
            )
        )

        addChild(hostingController)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }

    private func save() {
        let items = (extensionContext?.inputItems as? [NSExtensionItem]) ?? []
        Task {
            await ShareExtensionProcessor.process(items)
            await MainActor.run {
                self.extensionContext?.completeRequest(returningItems: nil)
            }
        }
    }

    private func cancel() {
        extensionContext?.cancelRequest(withError: NSError(domain: "HearthDropZone", code: 0))
    }
}
