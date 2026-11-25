import SwiftUI
import UIKit
import UniformTypeIdentifiers
import MeshCore
import MeshBLE

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct SettingsView: View {
    @EnvironmentObject var model: AppModel
    @State private var newName = ""
    @State private var share: ShareItem?
    @State private var importing = false
    @State private var confirmWipe = false

    var body: some View {
        Form {
            Section(header: Text("Profil")) {
                HStack {
                    TextField("Nom affiché", text: $newName)
                    Button("Enregistrer") { model.rename(newName) }
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            Section(header: Text("Identité et sauvegarde")) {
                Button("Afficher ma phrase de récupération") { model.showWords() }
                Button("Exporter une sauvegarde chiffrée") {
                    model.exportBackup { url in if let url = url { share = ShareItem(url: url) } }
                }
                Button("Importer une sauvegarde") { importing = true }
            }
            Section(header: Text("Bluetooth"), footer: Text("Pour recevoir en arrière-plan : gardez le Bluetooth activé et ne forcez pas la fermeture de l'app.")) {
                row("Central", model.status.centralState)
                row("Périphérique", model.status.peripheralState)
                row("Scan", model.status.scanning ? "actif" : "inactif")
                row("Annonce", model.status.advertising ? "active" : "inactive")
                row("Liens actifs", "\(model.status.readyLinks)")
                ForEach(model.status.peers, id: \.id) { p in
                    row(p.id, "\(p.state) \(p.rssi.map { "\($0) dBm" } ?? "")")
                }
            }
            Section(header: Text("Diagnostic terrain")) {
                Button("Partager le journal") { share = ShareItem(url: model.journal.fileURL) }
                Button("Effacer le journal") { model.journal.clear() }
            }
            Section {
                Button("Effacer toutes les données", role: .destructive) { confirmWipe = true }
            }
        }
        .navigationTitle("Réglages")
        .onAppear { newName = model.displayName }
        .sheet(item: $share) { item in ShareSheet(items: [item.url]) }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.data]) { result in
            if case .success(let url) = result { model.importBackup(from: url) }
        }
        .alert(isPresented: $confirmWipe) {
            Alert(title: Text("Effacer toutes les données ?"),
                  message: Text("L'identité, les contacts et les messages seront supprimés de cet appareil. Sans la phrase de récupération, ils ne pourront pas être retrouvés."),
                  primaryButton: .destructive(Text("Effacer")) { model.wipe() },
                  secondaryButton: .cancel())
        }
    }

    private func row(_ a: String, _ b: String) -> some View {
        HStack { Text(a); Spacer(); Text(b).foregroundColor(.secondary) }
    }
}
