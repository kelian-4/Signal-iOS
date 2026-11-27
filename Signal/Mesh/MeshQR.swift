import AVFoundation
import MeshCore
import PureLayout
import SignalServiceKit
import SignalUI
import UIKit

enum MeshOffline {
    static let message = "Ce réseau fonctionne uniquement par Bluetooth, sans serveur ni compte. Cette fonction n'est pas disponible."

    static func alert(from controller: UIViewController?) {
        guard let controller else { return }
        OWSActionSheets.showActionSheet(title: "Indisponible hors ligne", message: message, fromViewController: controller)
    }

    static func item(icon: ThemeIcon, text: String, from controller: UIViewController?) -> OWSTableItem {
        return .disclosureItem(
            icon: icon,
            withText: text,
            accessoryText: "Hors ligne",
            textColor: .Signal.tertiaryLabel,
            actionBlock: { [weak controller] in alert(from: controller) },
        )
    }
}

final class MeshQRContentController: OWSViewController, OWSNavigationChildController {
    private lazy var segments: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Mon code", "Scanner"])
        control.setWidth(100, forSegmentAt: 0)
        control.setWidth(100, forSegmentAt: 1)
        control.selectedSegmentIndex = 0
        control.addAction(UIAction { [weak self] _ in self?.configure() }, for: .valueChanged)
        return control
    }()

    private let presentController = MeshPresentQRViewController()
    private let scanController = MeshScanQRCodeViewController()
    private var active: (UIViewController & OWSNavigationChildController)?

    var childForOWSNavigationConfiguration: OWSNavigationChildController? { active }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }

    init(startOnScan: Bool = false) {
        super.init()
        if startOnScan { segments.selectedSegmentIndex = 1 }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(presentController)
        addChild(scanController)
        navigationItem.rightBarButtonItem = .doneButton(dismissingFrom: self)
        navigationItem.titleView = segments
        configure()
    }

    private func configure() {
        let next: UIViewController & OWSNavigationChildController = segments.selectedSegmentIndex == 0 ? presentController : scanController
        active = next
        view.removeAllSubviews()
        view.addSubview(next.view)
        next.view.autoPinEdgesToSuperviewEdges()
    }
}

final class MeshPresentQRViewController: OWSViewController, OWSNavigationChildController {
    var preferredNavigationBarStyle: OWSNavigationBarStyle { .blur }
    var navbarBackgroundColorOverride: UIColor? { OWSTableViewController2.tableBackgroundColor }

    private let qrCodeView = QRCodeView(qrCodeTintColor: .blue, contentInset: 16)
    private let nameLabel = UILabel()
    private let noteLabel = UILabel()
    private var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = OWSTableViewController2.tableBackgroundColor

        let card = UIView()
        card.backgroundColor = QRCodeColor.blue.background
        card.layer.cornerRadius = 24
        card.addSubview(qrCodeView)
        card.addSubview(nameLabel)
        qrCodeView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .dynamicTypeHeadlineClamped.semibold()
        nameLabel.textColor = QRCodeColor.blue.username
        nameLabel.textAlignment = .center
        NSLayoutConstraint.activate([
            qrCodeView.widthAnchor.constraint(equalToConstant: 214),
            qrCodeView.heightAnchor.constraint(equalTo: qrCodeView.widthAnchor),
            qrCodeView.topAnchor.constraint(equalTo: card.topAnchor, constant: 32),
            qrCodeView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 32),
            qrCodeView.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            nameLabel.topAnchor.constraint(equalTo: qrCodeView.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: qrCodeView.leadingAnchor),
            nameLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])

        noteLabel.font = .dynamicTypeCaption1
        noteLabel.textColor = .Signal.secondaryLabel
        noteLabel.numberOfLines = 0
        noteLabel.textAlignment = .center
        noteLabel.text = "Faites scanner ce code en personne. Il se renouvelle automatiquement et expire rapidement."

        let stack = UIStackView(arrangedSubviews: [card, noteLabel])
        stack.axis = .vertical
        stack.spacing = 24
        view.addSubview(stack)
        stack.autoPinWidthToSuperviewMargins()
        stack.autoVCenterInSuperview()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 45, repeats: true) { [weak self] _ in self?.refresh() }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timer?.invalidate()
        timer = nil
    }

    private func refresh() {
        let bridge = MeshBridge.shared
        nameLabel.text = bridge.service.displayName
        bridge.transport.queue.async {
            let text = bridge.service.messenger?.myQR()
            DispatchQueue.main.async {
                guard let text, let image = QRCodeGenerator().generateUnstyledQRCode(data: Data(text.utf8)) else {
                    self.qrCodeView.setError()
                    return
                }
                self.qrCodeView.setQRCode(image: image)
            }
        }
    }
}

final class MeshScanQRCodeViewController: OWSViewController, OWSNavigationChildController {
    var preferredNavigationBarStyle: OWSNavigationBarStyle { .blur }
    var navbarBackgroundColorOverride: UIColor? { OWSTableViewController2.tableBackgroundColor }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }

    private lazy var scanViewController: QRCodeScanViewController = {
        let controller = QRCodeScanViewController(appearance: .framed, showUploadPhotoButton: false)
        controller.delegate = self
        return controller
    }()

    private let instructions = UILabel()
    private var handling = false

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(scanViewController)
        instructions.font = .dynamicTypeSubheadline
        instructions.numberOfLines = 0
        instructions.textAlignment = .center
        instructions.textColor = .white
        instructions.text = "Scannez le code d'un contact pour lui envoyer une demande, en personne."
        let wrapper = UIView()
        wrapper.layoutMargins = UIEdgeInsets(hMargin: 16, vMargin: 20)
        wrapper.addSubview(instructions)
        instructions.autoPinEdgesToSuperviewMargins()
        view.addSubview(scanViewController.view)
        view.addSubview(wrapper)
        scanViewController.view.autoPinEdgesToSuperviewEdges()
        wrapper.autoPinEdges(toSuperviewSafeAreaExcludingEdge: .bottom)
    }

    fileprivate func askFirstMessage(for text: String) {
        let sheet = UIAlertController(title: "Premier message (facultatif)", message: nil, preferredStyle: .alert)
        sheet.addTextField { $0.placeholder = "Bonjour…" }
        sheet.addAction(UIAlertAction(title: CommonStrings.cancelButton, style: .cancel) { _ in self.handling = false })
        sheet.addAction(UIAlertAction(title: "Envoyer la demande", style: .default) { _ in
            self.send(text, first: sheet.textFields?.first?.text ?? "")
        })
        present(sheet, animated: true)
    }

    private func send(_ text: String, first: String) {
        let bridge = MeshBridge.shared
        bridge.transport.queue.async {
            var failure: String?
            do {
                _ = try bridge.service.messenger?.addContact(fromQR: text, firstText: first)
            } catch MessengerError.invalidOrExpiredQR {
                failure = "Code invalide ou expiré."
            } catch MessengerError.ownKey {
                failure = "C'est votre propre code."
            } catch MessengerError.dailyLimitReached {
                failure = "Limite quotidienne de demandes atteinte."
            } catch {
                failure = "Échec : \(error)"
            }
            DispatchQueue.main.async {
                self.handling = false
                if let failure {
                    OWSActionSheets.showErrorAlert(message: failure, fromViewController: self)
                } else {
                    OWSActionSheets.showActionSheet(
                        title: "Demande envoyée",
                        message: "Elle sera remise dès que le contact sera à portée Bluetooth.",
                        buttonAction: { _ in self.dismiss(animated: true) },
                        fromViewController: self,
                    )
                }
            }
        }
    }
}

extension MeshScanQRCodeViewController: QRCodeScanDelegate {
    var shouldShowUploadPhotoButton: Bool { false }

    func didTapUploadPhotoButton(_ qrCodeScanViewController: QRCodeScanViewController) {}

    func qrCodeScanViewScanned(qrCodeData: Data?, qrCodeString: String?) -> QRCodeScanOutcome {
        guard !handling, let qrCodeString else { return .continueScanning }
        handling = true
        askFirstMessage(for: qrCodeString)
        return .continueScanning
    }

    func qrCodeScanViewDismiss(_ qrCodeScanViewController: QRCodeScanViewController) {
        dismiss(animated: true)
    }
}
