import SwiftUI
import MeshCore

struct ChatView: View {
    @EnvironmentObject var model: AppModel
    let contactId: String
    @State private var bubbles: [Bubble] = []
    @State private var draft = ""
    @State private var showCode = false
    @State private var showVerify = false

    private var row: ContactRow? { return model.rows.first { $0.id == contactId } }

    var body: some View {
        VStack(spacing: 0) {
            if let r = row {
                if r.keyChange { keyChangeBanner(r) }
                if r.status == .pendingIncoming { requestBanner(r) }
                if r.status == .pendingOutgoing { info("Demande envoyée, en attente d'acceptation.") }
                if r.status == .accepted && r.trust == .unverified {
                    info("Contact non vérifié. Scannez son code en personne pour le vérifier.")
                }
            }
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(bubbles) { b in
                            BubbleView(bubble: b).id(b.id)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .onChange(of: bubbles) { list in
                    if let last = list.last { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            if row?.status == .accepted && row?.blocked == false {
                HStack {
                    TextField("Message", text: $draft)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button {
                        let t = draft
                        draft = ""
                        model.send(t, to: contactId)
                    } label: { Image(systemName: "paperplane.fill") }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
        }
        .navigationBarTitle(Text(row?.name ?? ""), displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Code de sécurité") { showCode = true }
                    Button("Vérifier en personne") { showVerify = true }
                    if row?.blocked == true {
                        Button("Débloquer") { model.setBlocked(contactId, false) }
                    } else {
                        Button("Bloquer") { model.setBlocked(contactId, true) }
                    }
                    Button("Signaler (local)") { model.report(contactId) }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showCode) { SecurityCodeView(contactId: contactId, name: row?.name ?? "") }
        .sheet(isPresented: $showVerify) { ScanContactView(isPresented: $showVerify) }
        .onAppear(perform: reload)
        .onChange(of: model.revision) { _ in reload() }
    }

    private func reload() {
        model.fetchBubbles(for: contactId) { bubbles = $0 }
    }

    private func info(_ text: String) -> some View {
        Text(text).font(.footnote).padding(8).frame(maxWidth: .infinity).background(Color.yellow.opacity(0.2))
    }

    private func keyChangeBanner(_ r: ContactRow) -> some View {
        VStack(spacing: 8) {
            Text("La clé de sécurité de \(r.name) a changé. Le badge « vérifié » a été retiré. Vérifiez cette personne en personne avant de lui faire confiance.")
                .font(.footnote)
            HStack {
                Button("Accepter la nouvelle clé") { model.resolveKeyChange(contactId, accept: true) }
                Button("Refuser") { model.resolveKeyChange(contactId, accept: false) }
            }
        }
        .padding(8).frame(maxWidth: .infinity).background(Color.red.opacity(0.15))
    }

    private func requestBanner(_ r: ContactRow) -> some View {
        VStack(spacing: 8) {
            Text("\(r.name) souhaite vous écrire.").font(.footnote).bold()
            if let t = r.requestText, !t.isEmpty { Text(t).font(.footnote) }
            HStack {
                Button("Accepter") { model.accept(contactId) }
                Button("Refuser") { model.reject(contactId, block: false) }
                Button("Bloquer") { model.reject(contactId, block: true) }
            }
        }
        .padding(8).frame(maxWidth: .infinity).background(Color.blue.opacity(0.12))
    }
}

struct BubbleView: View {
    let bubble: Bubble

    var body: some View {
        HStack {
            if bubble.outgoing { Spacer(minLength: 40) }
            VStack(alignment: bubble.outgoing ? .trailing : .leading, spacing: 2) {
                Text(bubble.text)
                    .padding(10)
                    .background(bubble.outgoing ? Color.blue : Color.gray.opacity(0.25))
                    .foregroundColor(bubble.outgoing ? .white : .primary)
                    .cornerRadius(14)
                if bubble.outgoing {
                    Text(label).font(.caption2).foregroundColor(.secondary)
                }
            }
            if !bubble.outgoing { Spacer(minLength: 40) }
        }
    }

    private var label: String {
        switch bubble.state {
        case .waitingSession: return "En attente de la session"
        case .queued: return "En attente d'un appareil proche"
        case .sent: return "Transmis"
        case .delivered: return "Distribué"
        case .received: return ""
        case .failed: return "Échec"
        }
    }
}

struct SecurityCodeView: View {
    @EnvironmentObject var model: AppModel
    let contactId: String
    let name: String
    @State private var code = ""
    @Environment(\.presentationMode) var presentation

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Comparez ce code avec celui affiché sur le téléphone de \(name). S'il est identique des deux côtés, personne ne s'interpose.")
                    .multilineTextAlignment(.center)
                Text(code)
                    .font(.system(.title3, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            }
            .padding()
            .navigationTitle("Code de sécurité")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Fermer") { presentation.wrappedValue.dismiss() } }
            }
        }
        .onAppear { model.securityCode(for: contactId) { code = $0 ?? "" } }
    }
}
