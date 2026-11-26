import AVFoundation
import CoreImage.CIFilterBuiltins
import MeshBLE
import MeshCore
import SignalServiceKit
import UIKit

final class MeshViewController: UITableViewController, UIDocumentPickerDelegate {
    private enum Section: Int, CaseIterable {
        case me, requests, alerts, contacts, network, data
    }

    private var requests: [MeshCore.Contact] = []
    private var alerts: [MeshCore.Contact] = []
    private var contacts: [MeshCore.Contact] = []
    private var status = BLEStatus()
    private var importing = false

    init() {
        super.init(style: .insetGrouped)
        title = "Réseau mesh"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "qrcode.viewfinder"), style: .plain, target: self, action: #selector(scanTapped))
        MeshBridge.shared.addStatusHandler { [weak self] status in
            DispatchQueue.main.async {
                self?.status = status
                self?.tableView.reloadData()
            }
        }
        MeshBridge.shared.onChange = { [weak self] in
            DispatchQueue.main.async { self?.reload() }
        }
        reload()
    }

    private func reload() {
        let all = MeshBridge.shared.service.messenger?.contacts.all() ?? []
        requests = all.filter { $0.status == .pendingIncoming && !$0.blocked }
        alerts = all.filter { $0.hasKeyChangeAlert }
        contacts = all.filter { $0.status == .accepted }
        tableView.reloadData()
    }

    private func alert(_ title: String, _ message: String? = nil) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .me: return "Mon identité"
        case .requests: return requests.isEmpty ? nil : "Demandes de contact"
        case .alerts: return alerts.isEmpty ? nil : "Clé modifiée"
        case .contacts: return "Contacts"
        case .network: return "Bluetooth"
        case .data: return "Données"
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .me: return 3
        case .requests: return requests.count
        case .alerts: return alerts.count
        case .contacts: return max(contacts.count, 1)
        case .network: return 2 + status.peers.count
        case .data: return 4
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
        switch Section(rawValue: indexPath.section)! {
        case .me:
            let rows = [
                (MeshBridge.shared.service.displayName, "Nom affiché"),
                ("Mon QR", "À faire scanner en personne"),
                ("Phrase de récupération", "24 mots"),
            ]
            cell.textLabel?.text = rows[indexPath.row].0
            cell.detailTextLabel?.text = rows[indexPath.row].1
            cell.accessoryType = indexPath.row == 0 ? .none : .disclosureIndicator
        case .requests:
            let c = requests[indexPath.row]
            cell.textLabel?.text = c.displayName
            cell.detailTextLabel?.text = c.requestText?.isEmpty == false ? c.requestText : "Souhaite vous contacter"
            cell.accessoryType = .disclosureIndicator
        case .alerts:
            let c = alerts[indexPath.row]
            cell.textLabel?.text = c.displayName
            cell.detailTextLabel?.text = "La clé de ce contact a changé"
            cell.detailTextLabel?.textColor = .systemRed
            cell.accessoryType = .disclosureIndicator
        case .contacts:
            if contacts.isEmpty {
                cell.textLabel?.text = "Aucun contact"
                cell.textLabel?.textColor = .secondaryLabel
            } else {
                let c = contacts[indexPath.row]
                cell.textLabel?.text = c.displayName + (c.trust == .verified ? "  ✓" : "")
                cell.detailTextLabel?.text = c.trust == .verified ? "Vérifié" : "Non vérifié"
                cell.accessoryType = .disclosureIndicator
            }
        case .network:
            if indexPath.row == 0 {
                cell.textLabel?.text = "Liens actifs : \(status.readyLinks)"
                cell.detailTextLabel?.text = "Central \(status.centralState) · Périphérique \(status.peripheralState)"
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "Scan \(status.scanning ? "actif" : "arrêté") · Annonce \(status.advertising ? "active" : "arrêtée")"
                cell.detailTextLabel?.text = "Serveur \(status.serverReady ? "prêt" : "non prêt")"
            } else {
                cell.textLabel?.text = "Pair \(indexPath.row - 1)"
                cell.detailTextLabel?.text = "\(status.peers[indexPath.row - 2])"
            }
        case .data:
            let rows = ["Exporter la sauvegarde mesh", "Importer une sauvegarde mesh", "Partager le journal de terrain", "Effacer le journal de terrain"]
            cell.textLabel?.text = rows[indexPath.row]
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let bridge = MeshBridge.shared
        switch Section(rawValue: indexPath.section)! {
        case .me:
            if indexPath.row == 1 { showMyQR() }
            if indexPath.row == 2 { confirmShowPhrase() }
        case .requests:
            handleRequest(requests[indexPath.row])
        case .alerts:
            handleKeyChange(alerts[indexPath.row])
        case .contacts:
            guard !contacts.isEmpty else { return }
            openConversation(contacts[indexPath.row])
        case .network:
            break
        case .data:
            switch indexPath.row {
            case 0: exportBackup()
            case 1: importBackup()
            case 2: share(bridge.journal.fileURL)
            default:
                bridge.journal.clear()
                alert("Journal effacé")
            }
        }
    }

    private func openConversation(_ contact: MeshCore.Contact) {
        guard let aci = MeshBridge.shared.aci(forContact: contact.id) else {
            alert("Échange de clés en cours", "Réessayez quand les deux téléphones sont à portée.")
            return
        }
        let thread = MeshSignalContacts.thread(for: aci)
        SignalApp.shared.presentConversationForThread(threadUniqueId: thread.uniqueId, action: .none, animated: true)
    }

    private func showMyQR() {
        guard let text = MeshBridge.shared.service.messenger?.myQR() else { return }
        let vc = MeshQRViewController(text: text)
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    private func confirmShowPhrase() {
        let a = UIAlertController(
            title: "Afficher la phrase ?", message: "Assurez-vous que personne ne regarde votre écran.", preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "Annuler", style: .cancel))
        a.addAction(UIAlertAction(title: "Afficher", style: .destructive) { _ in
            guard let words = MeshBridge.shared.service.recoveryWords() else { return }
            self.present(MeshRecoveryWordsViewController(words: words, onDone: nil), animated: true)
        })
        present(a, animated: true)
    }

    private func handleRequest(_ contact: MeshCore.Contact) {
        let a = UIAlertController(title: contact.displayName, message: contact.requestText, preferredStyle: .actionSheet)
        a.addAction(UIAlertAction(title: "Accepter", style: .default) { _ in
            let bridge = MeshBridge.shared
            bridge.transport.queue.async {
                do {
                    try bridge.service.messenger?.acceptRequest(contactId: contact.id)
                    DispatchQueue.main.async { self.reload() }
                } catch {
                    DispatchQueue.main.async { self.alert("Impossible d'accepter", "\(error)") }
                }
            }
        })
        a.addAction(UIAlertAction(title: "Refuser", style: .destructive) { _ in
            MeshBridge.shared.transport.queue.async {
                MeshBridge.shared.service.messenger?.rejectRequest(contactId: contact.id, block: false)
                DispatchQueue.main.async { self.reload() }
            }
        })
        a.addAction(UIAlertAction(title: "Bloquer", style: .destructive) { _ in
            MeshBridge.shared.transport.queue.async {
                MeshBridge.shared.service.messenger?.rejectRequest(contactId: contact.id, block: true)
                DispatchQueue.main.async { self.reload() }
            }
        })
        a.addAction(UIAlertAction(title: "Annuler", style: .cancel))
        present(a, animated: true)
    }

    private func handleKeyChange(_ contact: MeshCore.Contact) {
        let a = UIAlertController(
            title: contact.displayName,
            message: "La clé de ce contact a changé. Vérifiez en personne avant d'accepter.",
            preferredStyle: .actionSheet)
        a.addAction(UIAlertAction(title: "Accepter la nouvelle clé", style: .destructive) { _ in
            MeshBridge.shared.transport.queue.async {
                MeshBridge.shared.service.messenger?.resolveKeyChange(contactId: contact.id, accept: true)
                DispatchQueue.main.async { self.reload() }
            }
        })
        a.addAction(UIAlertAction(title: "Garder l'ancienne clé", style: .default) { _ in
            MeshBridge.shared.transport.queue.async {
                MeshBridge.shared.service.messenger?.resolveKeyChange(contactId: contact.id, accept: false)
                DispatchQueue.main.async { self.reload() }
            }
        })
        a.addAction(UIAlertAction(title: "Annuler", style: .cancel))
        present(a, animated: true)
    }

    @objc private func scanTapped() {
        let vc = MeshScanViewController { [weak self] text in
            self?.addContact(fromQR: text)
        }
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    private func addContact(fromQR text: String) {
        let a = UIAlertController(title: "Premier message (facultatif)", message: nil, preferredStyle: .alert)
        a.addTextField { $0.placeholder = "Bonjour…" }
        a.addAction(UIAlertAction(title: "Envoyer la demande", style: .default) { _ in
            let first = a.textFields?.first?.text ?? ""
            let bridge = MeshBridge.shared
            bridge.transport.queue.async {
                do {
                    _ = try bridge.service.messenger?.addContact(fromQR: text, firstText: first)
                    DispatchQueue.main.async {
                        self.reload()
                        self.alert("Demande envoyée", "Elle sera remise dès que le contact sera à portée.")
                    }
                } catch MessengerError.invalidOrExpiredQR {
                    DispatchQueue.main.async { self.alert("QR invalide ou expiré") }
                } catch MessengerError.ownKey {
                    DispatchQueue.main.async { self.alert("C'est votre propre QR") }
                } catch MessengerError.dailyLimitReached {
                    DispatchQueue.main.async { self.alert("Limite quotidienne atteinte") }
                } catch {
                    DispatchQueue.main.async { self.alert("Échec", "\(error)") }
                }
            }
        })
        a.addAction(UIAlertAction(title: "Annuler", style: .cancel))
        present(a, animated: true)
    }

    private func exportBackup() {
        do {
            let data = try MeshBridge.shared.service.exportBackup()
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("sauvegarde-mesh.meshbackup")
            try data.write(to: url, options: .atomic)
            share(url)
        } catch {
            alert("Export impossible", "\(error)")
        }
    }

    private func importBackup() {
        importing = true
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data])
        picker.delegate = self
        present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard importing, let url = urls.first else { return }
        importing = false
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            try MeshBridge.shared.service.importBackup(data)
            reload()
            alert("Sauvegarde importée")
        } catch {
            alert("Import impossible", "Fichier invalide ou phrase différente.")
        }
    }

    private func share(_ url: URL) {
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        vc.popoverPresentationController?.sourceView = view
        present(vc, animated: true)
    }
}

final class MeshQRViewController: UIViewController {
    private let text: String

    init(text: String) {
        self.text = text
        super.init(nibName: nil, bundle: nil)
        title = "Mon QR"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .done, primaryAction: UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        })
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        var image: UIImage?
        if let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)),
           let cg = CIContext().createCGImage(output, from: output.extent) {
            image = UIImage(cgImage: cg)
        }
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.layer.magnificationFilter = .nearest
        imageView.backgroundColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let note = UILabel()
        note.text = "Ce QR expire rapidement. Faites-le scanner en personne, puis comparez les codes de sécurité."
        note.numberOfLines = 0
        note.textAlignment = .center
        note.textColor = .secondaryLabel
        note.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        view.addSubview(note)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            note.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 24),
            note.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            note.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
        ])
    }
}

final class MeshScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    private let session = AVCaptureSession()
    private let onScan: (String) -> Void
    private var done = false

    init(onScan: @escaping (String) -> Void) {
        self.onScan = onScan
        super.init(nibName: nil, bundle: nil)
        title = "Scanner un QR"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        })
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async { granted ? self.configure() : self.denied() }
        }
    }

    private func denied() {
        let label = UILabel()
        label.text = "Accès à la caméra refusé. Activez-le dans Réglages."
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
        ])
    }

    private func configure() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return denied() }
        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return denied() }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.frame = view.bounds
        layer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(layer, at: 0)
        DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.stopRunning()
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput objects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard !done, let code = objects.compactMap({ $0 as? AVMetadataMachineReadableCodeObject }).first,
              let text = code.stringValue else { return }
        done = true
        session.stopRunning()
        dismiss(animated: true) { self.onScan(text) }
    }
}
