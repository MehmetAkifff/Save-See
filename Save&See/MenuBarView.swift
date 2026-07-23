import SwiftUI
import AppKit

struct MenuBarView: View {
    @EnvironmentObject private var store: EntryStore
    @State private var showAdd = false
    @State private var newName = ""
    @State private var newValue = ""
    @State private var copiedID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            if showAdd { addForm; Divider() }
            entryList
            Divider()
            footer
        }
        .frame(width: 300)
    }

    private var toolbar: some View {
        HStack {
            Text("Save & See").font(.headline)
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
            TextField("Name", text: $newName)
                .textFieldStyle(.roundedBorder)
            TextField("Value", text: $newValue)
                .textFieldStyle(.roundedBorder)
            Button("Add") {
                store.addText(name: newName, value: newValue)
                newName = ""; newValue = ""
                withAnimation { showAdd = false }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .disabled(newName.trimmed.isEmpty || newValue.trimmed.isEmpty)
        }
        .padding(12)
    }

    @ViewBuilder
    private var entryList: some View {
        if store.entries.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "tray").font(.title2).foregroundStyle(.tertiary)
                Text("No entries yet").font(.subheadline).foregroundStyle(.secondary)
                Text("Tap + to add text, or Open App to add files")
                    .font(.caption).foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
        } else {
            List {
                ForEach(store.entries) { entry in
                    MenuBarEntryRow(entry: entry, copiedID: $copiedID)
                }
                .onDelete { store.remove(at: $0) }
            }
            .listStyle(.plain)
            .frame(maxHeight: 340)
        }
    }

    private var footer: some View {
        HStack {
            if !store.entries.isEmpty {
                Text("\(store.entries.count) item\(store.entries.count == 1 ? "" : "s")")
                    .font(.caption).foregroundStyle(.tertiary)
            }
            Spacer()
            Button("Open App") {
                (NSApp.delegate as? AppDelegate)?.openAppWindow()
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

struct MenuBarEntryRow: View {
    let entry: Entry
    @Binding var copiedID: UUID?
    @EnvironmentObject private var store: EntryStore

    private var copied: Bool { copiedID == entry.id }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: entry.systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.subheadline).fontWeight(.medium).lineLimit(1)
                subtitle
            }
            Spacer()
            actionIcon
        }
        .contentShape(Rectangle())
        .onTapGesture { handleTap() }
        .help(entry.kind.isText ? "Click to copy" : "Click to open")
    }

    @ViewBuilder
    private var subtitle: some View {
        switch entry.kind {
        case .text(let v):
            Text(v).font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
        case .file(let original, _):
            Text(original).font(.caption).foregroundStyle(.secondary).lineLimit(1)
        }
    }

    @ViewBuilder
    private var actionIcon: some View {
        if entry.kind.isText {
            Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                .foregroundStyle(copied ? AnyShapeStyle(.green) : AnyShapeStyle(.tertiary))
                .font(.footnote)
                .animation(.easeInOut(duration: 0.2), value: copied)
        } else {
            Image(systemName: "arrow.up.right.square")
                .foregroundStyle(AnyShapeStyle(.tertiary))
                .font(.footnote)
        }
    }

    private func handleTap() {
        switch entry.kind {
        case .text(let v):
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(v, forType: .string)
            copiedID = entry.id
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                if copiedID == entry.id { copiedID = nil }
            }
        case .file:
            if let url = store.fileURL(for: entry) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
