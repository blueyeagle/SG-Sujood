import SwiftUI
import MessageUI

// Wraps MFMailComposeViewController so a submission can be sent as an email the user reviews
// and taps Send on. Falls back to a mailto: link when no Mail account is configured.
struct MailComposer: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let body: String
    var onFinish: () -> Void = {}

    static var canSend: Bool { MFMailComposeViewController.canSendMail() }

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(recipients)
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        return vc
    }

    func updateUIViewController(_ vc: MFMailComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onFinish: () -> Void
        init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true) { self.onFinish() }
        }
    }
}

enum MailFallback {
    /// Builds a mailto: URL for when the in-app composer isn't available.
    static func url(to recipient: String, subject: String, body: String) -> URL? {
        var comps = URLComponents()
        comps.scheme = "mailto"
        comps.path = recipient
        comps.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body),
        ]
        return comps.url
    }
}
