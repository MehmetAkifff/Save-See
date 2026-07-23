import SwiftUI
import AppKit

struct ContentView: View {
    @Environment(SnippetStore.self) private var store
    @State private var showAdd = false
    @State private var newName = ""
    @State private var newValue = ""
    @State private var copiedID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if showAdd { addForm; Divider() }
            snippetList
            Divider()
            footerBar
        }
        .frame(width: 300)
    }

    private var header: some View {
        HStack {
            Text("Save & See")
                .font(.headline)
            Spacer()
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    showAdd.toggle()
                    if showAdd { newName = ""; newValue = "" }
                }
            } label: {
                Image(systemName: showAdd ? "xmark.circle.fill" : "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(showAdd ? Color.secondary : Color.accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var addForm: some View {
        VStack(spacing: 8) {
            TextField("Name (e.g. API Key)", text: $newName)
                .textFieldStyle(.roundedBorder)
            TextField("Value", text: $newValue)
                .textFieldStyle(.roundedBorder)
            Button("Add Snippet") {
                store.add(name: newName, value: newValue)
                newName = ""; newValue = ""
                withAnimation { showAdd = false }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty ||
                      newValue.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(12)
    }

    private var snippetList: some View {
        Group {
            if store.snippets.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text("No snippets yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Tap + to add your first one")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                List {
                    ForEach(store.snippets) { snippet in
                        SnippetRow(snippet: snippet, copiedID: $copiedID)
                    }
                    .onDelete { store.remove(at: $0) }
                }
                .listStyle(.plain)
                .frame(maxHeight: 380)
            }
        }
    }

    private var footerBar: some View {
        HStack {
            Text(store.snippets.isEmpty ? "" :
                 "\(store.snippets.count) snippet\(store.snippets.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

struct SnippetRow: View {
    let snippet: Snippet
    @Binding var copiedID: UUID?

    private var copied: Bool { copiedID == snippet.id }

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(snippet.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(snippet.value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                .foregroundStyle(copied ? AnyShapeStyle(.green) : AnyShapeStyle(.tertiary))
                .font(.footnote)
                .animation(.easeInOut(duration: 0.2), value: copied)
        }
        .contentShape(Rectangle())
        .onTapGesture { copy() }
        .help("Click to copy")
    }

    private func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(snippet.value, forType: .string)
        copiedID = snippet.id
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            if copiedID == snippet.id { copiedID = nil }
        }
    }
}
