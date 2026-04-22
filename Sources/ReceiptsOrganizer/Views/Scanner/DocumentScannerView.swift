import SwiftUI
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {

    let onScanCompleted: ([UIImage]) -> Void
    let onCancelled: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onScanCompleted: onScanCompleted, onCancelled: onCancelled)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {

        let onScanCompleted: ([UIImage]) -> Void
        let onCancelled: () -> Void

        init(onScanCompleted: @escaping ([UIImage]) -> Void,
             onCancelled: @escaping () -> Void) {
            self.onScanCompleted = onScanCompleted
            self.onCancelled = onCancelled
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            var pages: [UIImage] = []
            for i in 0..<scan.pageCount {
                pages.append(scan.imageOfPage(at: i))
            }
            controller.dismiss(animated: true)
            onScanCompleted(pages)
        }

        func documentCameraViewControllerDidCancel(
            _ controller: VNDocumentCameraViewController
        ) {
            controller.dismiss(animated: true)
            onCancelled()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            controller.dismiss(animated: true)
            onCancelled()
        }
    }
}
