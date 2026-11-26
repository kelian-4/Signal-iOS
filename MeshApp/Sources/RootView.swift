import SwiftUI
import MeshCore

struct RootView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        Group {
            if model.hasIdentity {
                MainTabs()
            } else {
                OnboardingView()
            }
        }
        .sheet(isPresented: Binding(get: { model.recoveryWords != nil }, set: { if !$0 { model.recoveryWords = nil } })) {
            RecoveryWordsView(words: model.recoveryWords ?? [])
        }
        .alert(item: Binding(get: { model.alert.map { AlertText(text: $0) } }, set: { _ in model.alert = nil })) { a in
            Alert(title: Text(a.text))
        }
    }
}

struct AlertText: Identifiable {
    let text: String
    var id: String { return text }
}

struct MainTabs: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        TabView {
            NavigationView { ContactsView() }
                .tabItem { Label("Discussions", systemImage: "bubble.left.and.bubble.right") }
            NavigationView { MyCodeView() }
                .tabItem { Label("Mon code", systemImage: "qrcode") }
            NavigationView { SettingsView() }
                .tabItem { Label("Réglages", systemImage: "gearshape") }
        }
    }
}

struct OnboardingView: View {
    @EnvironmentObject var model: AppModel
    @State private var name = ""
    @State private var phrase = ""
    @State private var restoring = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Votre nom affiché")) {
                    TextField("Nom", text: $name)
                        .autocapitalization(.words)
                }
                if restoring {
                    Section(header: Text("Phrase de récupération (24 mots)")) {
                        TextEditor(text: $phrase)
                            .frame(minHeight: 120)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    Section {
                        Button("Restaurer mon identité") { model.restoreIdentity(phrase: phrase, name: name) }
                            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || phrase.isEmpty)
                        Button("Créer une nouvelle identité") { restoring = false }
                    }
                } else {
                    Section(footer: Text("Aucun numéro de téléphone, aucun compte, aucun serveur. Votre identité reste sur cet appareil.")) {
                        Button("Créer mon identité") { model.createIdentity(name: name) }
                            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        Button("J'ai déjà une phrase de récupération") { restoring = true }
                    }
                }
            }
            .navigationTitle("Messagerie")
        }
    }
}

struct RecoveryWordsView: View {
    let words: [String]
    @Environment(\.presentationMode) var presentation

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Notez ces 24 mots dans l'ordre, sur papier. Ils sont le seul moyen de retrouver votre identité si vous perdez ce téléphone. Ne les photographiez pas et ne les partagez avec personne.")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
                        ForEach(Array(words.enumerated()), id: \.offset) { i, w in
                            Text("\(i + 1). \(w)").font(.system(.body, design: .monospaced))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Phrase de récupération")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Terminé") { presentation.wrappedValue.dismiss() }
                }
            }
        }
    }
}

struct ContactsView: View {
    @EnvironmentObject var model: AppModel
    @State private var scanning = false

    var body: some View {
        List {
            ForEach(model.rows) { row in
                NavigationLink(destination: ChatView(contactId: row.id)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(row.name).font(.headline)
                                if row.trust == .verified { Image(systemName: "checkmark.seal.fill").foregroundColor(.green) }
                                if row.keyChange { Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red) }
                            }
                            Text(subtitle(row)).font(.subheadline).foregroundColor(.secondary).lineLimit(1)
                        }
                    }
                }
            }
        }
        .navigationTitle("Discussions")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { scanning = true } label: { Image(systemName: "qrcode.viewfinder") }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                BluetoothBadge()
            }
        }
        .sheet(isPresented: $scanning) { ScanContactView(isPresented: $scanning) }
        .overlay(Group {
            if model.rows.isEmpty {
                Text("Aucun contact. Scannez le code d'une personne en face de vous.")
                    .multilineTextAlignment(.center).foregroundColor(.secondary).padding()
            }
        })
    }

    private func subtitle(_ row: ContactRow) -> String {
        if row.blocked { return "Bloqué" }
        switch row.status {
        case .pendingIncoming: return "Demande reçue"
        case .pendingOutgoing: return "Demande envoyée"
        case .accepted: return row.preview
        }
    }
}

struct BluetoothBadge: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        let links: Int = model.status.readyLinks
        let iconName: String = links > 0 ? "dot.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash"
        let isOn: Bool = model.status.centralState == "on"
        return HStack(spacing: 4) {
            Image(systemName: iconName)
            Text("\(links)")
        }
        .font(.footnote)
        .foregroundColor(isOn ? Color.primary : Color.red)
    }
}

struct ScanContactView: View {
    @EnvironmentObject var model: AppModel
    @Binding var isPresented: Bool
    @State private var scanned: String?
    @State private var firstText = ""

    var body: some View {
        NavigationView {
            Group {
                if let code = scanned {
                    Form {
                        Section(footer: Text("Un seul message d'accueil, sans lien. Il sera livré avec la demande.")) {
                            TextField("Message d'accueil (facultatif)", text: $firstText)
                        }
                        Section {
                            Button("Envoyer la demande") {
                                model.addContact(qr: code, firstText: firstText)
                                isPresented = false
                            }
                        }
                    }
                } else {
                    QRScannerView { scanned = $0 }.edgesIgnoringSafeArea(.all)
                }
            }
            .navigationTitle("Scanner un contact")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Fermer") { isPresented = false } }
            }
        }
    }
}

struct MyCodeView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(spacing: 16) {
            Text(model.displayName).font(.title2).bold()
            if let image = QRImage.make(model.qrText) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 320)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
            }
            Text("Ce code est signé et valable 10 minutes. Faites-le scanner par la personne en face de vous : c'est la seule façon d'obtenir le badge « vérifié ».")
                .font(.footnote).foregroundColor(.secondary).multilineTextAlignment(.center)
            Button("Actualiser le code") { model.run { model.refresh() } }
            Spacer()
        }
        .padding()
        .navigationTitle("Mon code")
        .onAppear { model.run { model.refresh() } }
    }
}
