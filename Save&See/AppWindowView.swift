import SwiftUI
import AppKit

struct AppWindowView: View {
    @EnvironmentObject private var store: EntryStore
    @State private var selection: Entry.ID?
    @State private var showAddText = false
    @State private var searchText = ""

    private var filtered: [Entry] {
        guard !searchText.isEmpty else { return store.entries }
        return store.entries.filter { entry in
            if entry.name.localizedCaseInsensitiveContains(searchText) { return true }
            if let v = entry.kind.textValue, v.localizedCaseInsensitiveContains(searchText) { return true }
            return false
        }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(filtered) { entry in
                    AppEntryRow(entry: entry).tag(entry.id)
                }
                .onDelete { indices in
                    let ids = Set(indices.map { filtered[$0].id })
                    store.remove(at: IndexSet(store.entries.indices.filter { ids.contains(store.entries[$0].id) }))
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 240)
            .searchable(text: $searchText, prompt: "Search")
            .navigationTitle("Save & See")
            .toolbar {
                ToolbarItemGroup {
                    Button { showAddText = true } label: {
                        Label("Add Text", systemImage: "text.badge.plus")
                    }
                    Button(action: addFiles) {
                        Label("Add File", systemImage: "doc.badge.plus")
                    }
                }
            }
        } detail: {
            if let id = selection, let entry = store.entries.first(where: { $0.id == id }) {
                EntryDetailView(entry: entry).environmentObject(store)
            } else {
                ContentUnavailableView(
                    "No Selection",
                    systemImage: "doc.on.clipboard",
                    description: Text("Select an entry to view details")
                )
            }
        }
        .sheet(isPresented: $showAddText) {
            AddTextSheet().environmentObject(store)
        }
        .dropDestination(for: URL.self) { urls, _ in
            for url in urls where url.isFileURL {
                try? store.addFile(name: url.deletingPathExtension().lastPathComponent, sourceURL: url)
            }
            return !urls.isEmpty
        }
    }

    private func addFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            try? store.addFile(name: url.deletingPathExtension().lastPathComponent, sourceURL: url)
        }
    }
}

// MARK: - Sidebar Row

struct AppEntryRow: View {
    let entry: Entry

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name).lineLimit(1)
                subtitleText
            }
        } icon: {
            Image(systemName: entry.systemImage)
        }
    }

    @ViewBuilder
    private var subtitleText: some View {
        switch entry.kind {
        case .text(let v):
            Text(v).font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
        case .file(let original, _):
            Text(original).font(.caption).foregroundStyle(.secondary).lineLimit(1)
        }
    }
}

// MARK: - Detail View

struct EntryDetailView: View {
    let entry: Entry
    @EnvironmentObject private var store: EntryStore
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: entry.systemImage).font(.title2).foregroundStyle(.secondary)
                Text(entry.name).font(.title2).fontWeight(.semibold)
                Spacer()
            }
            .padding()
            Divider()

            switch entry.kind {
            case .text(let value): textDetail(value)
            case .file: fileDetail
            }
        }
    }

    @ViewBuilder
    private func textDetail(_ value: String) -> some View {
        VStack(spacing: 12) {
            ScrollView {
                Text(value)
                    .font(.body.monospaced())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding()
            }
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(value, forType: .string)
                copied = true
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    copied = false
                }
            } label: {
                Label(copied ? "Copied!" : "Copy to Clipboard",
                      systemImage: copied ? "checkmark" : "doc.on.doc")
            }
            .buttonStyle(.borderedProminent)
            .animation(.easeInOut(duration: 0.2), value: copied)
            .padding(.bottom)
        }
    }

    @ViewBuilder
    private var fileDetail: some View {
        if let url = store.fileURL(for: entry) {
            VStack(spacing: 16) {
                filePreview(url: url)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                HStack(spacing: 12) {
                    Button("Open") { NSWorkspace.shared.open(url) }
                        .buttonStyle(.borderedProminent)
                    Button("Show in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.bottom)
            }
            .padding(.top)
        }
    }

    @ViewBuilder
    private func filePreview(url: URL) -> some View {
        let ext = url.pathExtension.lowercased()
        let imageExts = ["jpg", "jpeg", "png", "gif", "webp", "heic", "tiff", "bmp"]
        if imageExts.contains(ext), let img = NSImage(contentsOf: url) {
            Image(nsImage: img)
                .resizable()
                .scaledToFit()
                .padding()
        } else {
            VStack(spacing: 12) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
                    .frame(width: 80, height: 80)
                Text(url.lastPathComponent)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Add Text Sheet

struct AddTextSheet: View {
    @EnvironmentObject private var store: EntryStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var value = ""
    @FocusState private var nameFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Text Snippet").font(.headline)

            TextField("Name (e.g. API Key)", text: $name)
                .textFieldStyle(.roundedBorder)
                .focused($nameFocused)

            TextField("Value", text: $value, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(4...8)
                .font(.body.monospaced())

            HStack {
                Button("Cancel") { dismiss() }.buttonStyle(.bordered)
                Spacer()
                Button("Add") {
                    store.addText(name: name, value: value)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmed.isEmpty || value.trimmed.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 400)
        .onAppear { nameFocused = true }
    }
}
