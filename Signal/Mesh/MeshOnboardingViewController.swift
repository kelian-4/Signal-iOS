import MeshCore
import SignalServiceKit
import UIKit

final class MeshOnboardingViewController: UIViewController {
    private let nameField = UITextField()
    private let phraseView = UITextView()
    private let modeControl = UISegmentedControl(items: ["Créer", "Restaurer"])
    private let actionButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let title = UILabel()
        title.text = "Messagerie"
        title.font = .systemFont(ofSize: 32, weight: .bold)

        let intro = UILabel()
        intro.text = "Aucun numéro de téléphone, aucun compte, aucun serveur. Votre identité est créée sur cet appareil et vos messages passent par Bluetooth."
        intro.font = .preferredFont(forTextStyle: .subheadline)
        intro.textColor = .secondaryLabel
        intro.numberOfLines = 0

        nameField.placeholder = "Votre nom affiché"
        nameField.borderStyle = .roundedRect
        nameField.autocapitalizationType = .words
        nameField.autocorrectionType = .no

        modeControl.selectedSegmentIndex = 0
        modeControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)

        phraseView.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
        phraseView.layer.borderColor = UIColor.separator.cgColor
        phraseView.layer.borderWidth = 1
        phraseView.layer.cornerRadius = 8
        phraseView.autocapitalizationType = .none
        phraseView.autocorrectionType = .no
        phraseView.isHidden = true
        phraseView.heightAnchor.constraint(equalToConstant: 120).isActive = true

        actionButton.setTitle("Créer mon identité", for: .normal)
        actionButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)

        statusLabel.numberOfLines = 0
        statusLabel.textColor = .systemRed
        statusLabel.font = .preferredFont(forTextStyle: .footnote)

        let stack = UIStackView(arrangedSubviews: [title, intro, nameField, modeControl, phraseView, actionButton, spinner, statusLabel])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        view.addGestureRecognizer(UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:))))
    }

    private var restoring: Bool { return modeControl.selectedSegmentIndex == 1 }

    @objc private func modeChanged() {
        phraseView.isHidden = !restoring
        actionButton.setTitle(restoring ? "Restaurer mon identité" : "Créer mon identité", for: .normal)
    }

    private func fail(_ text: String) {
        spinner.stopAnimating()
        actionButton.isEnabled = true
        statusLabel.text = text
    }

    @objc private func actionTapped() {
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            statusLabel.text = "Entrez un nom."
            return
        }
        statusLabel.text = nil
        actionButton.isEnabled = false
        spinner.startAnimating()
        view.endEditing(true)
        let phrase = phraseView.text ?? ""
        let isRestoring = restoring
        let bridge = MeshBridge.shared
        bridge.transport.queue.async {
            do {
                var words: [String]?
                if bridge.service.hasIdentity {
                } else if isRestoring {
                    try bridge.service.restoreIdentity(words: Bip39.normalize(phrase), displayName: name)
                } else {
                    words = try bridge.service.createIdentity(displayName: name)
                }
                bridge.attachMessenger()
                guard let entropy = bridge.service.recoveryEntropy else {
                    DispatchQueue.main.async { self.fail("Identité introuvable.") }
                    return
                }
                DispatchQueue.main.async { self.finish(words: words, entropy: entropy) }
            } catch {
                DispatchQueue.main.async {
                    self.fail(isRestoring ? "Phrase de récupération invalide." : "Impossible de créer l'identité.")
                }
            }
        }
    }

    private func finish(words: [String]?, entropy: Data) {
        let register = {
            Task { @MainActor in
                do {
                    try await MeshLocalRegistration.register(entropy: entropy)
                    SignalApp.shared.showHomeTabBarController()
                } catch {
                    self.fail("Enregistrement local impossible : \(error)")
                }
            }
        }
        if let words {
            let vc = MeshRecoveryWordsViewController(words: words, onDone: register)
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        } else {
            register()
        }
    }
}

final class MeshRecoveryWordsViewController: UIViewController {
    private let words: [String]
    private let onDone: (() -> Void)?

    init(words: [String], onDone: (() -> Void)?) {
        self.words = words
        self.onDone = onDone
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let title = UILabel()
        title.text = "Phrase de récupération"
        title.font = .systemFont(ofSize: 24, weight: .bold)

        let info = UILabel()
        info.text = "Notez ces 24 mots dans l'ordre, sur papier. C'est le seul moyen de retrouver votre identité si vous perdez ce téléphone. Ne les photographiez pas et ne les partagez avec personne."
        info.numberOfLines = 0
        info.font = .preferredFont(forTextStyle: .subheadline)

        let list = UILabel()
        list.numberOfLines = 0
        list.font = .monospacedSystemFont(ofSize: 16, weight: .regular)
        var lines: [String] = []
        for row in 0..<12 {
            let left = "\(row + 1). \(words[row])"
            let right = "\(row + 13). \(words[row + 12])"
            lines.append(left.padding(toLength: 18, withPad: " ", startingAt: 0) + right)
        }
        list.text = lines.joined(separator: "\n")

        let done = UIButton(type: .system)
        done.setTitle("J'ai noté ma phrase", for: .normal)
        done.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        done.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [title, info, list, done])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -20),
        ])
    }

    @objc private func doneTapped() {
        dismiss(animated: true) { self.onDone?() }
    }
}
