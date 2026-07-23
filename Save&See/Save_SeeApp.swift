import SwiftUI
import AppKit

// MARK: - Model

struct Entry: Identifiable, Codable {
    var id = UUID()
    var name: String
    var kind: Kind
    var createdAt = Date()

    enum Kind: Codable {
        case text(String)
        case file(original: String, stored: String)
    }

    var systemImage: String {
        switch kind {
        case .text: return "doc.on.clipboard"
        case .file(let original, _):
            switch URL(fileURLWithPath: original).pathExtension.lowercased() {
            case "jpg", "jpeg", "png", "gif", "webp", "heic", "tiff", "bmp", "svg": return "photo"
            case "pdf": return "doc.richtext"
            case "mp4", "mov", "avi", "mkv", "m4v": return "film"
            case "mp3", "m4a", "wav", "aac", "flac": return "music.note"
            case "zip", "gz", "tar", "rar", "7z": return "doc.zipper"
            case "txt", "md", "rtf": return "doc.text"
            default: return "doc"
            }
        }
    }
}

extension Entry.Kind {
    var isText: Bool { if case .text = self { return true }; return false }
    var textValue: String? { if case .text(let v) = self { return v }; return nil }
    var originalFileName: String? { if case .file(let o, _) = self { return o }; return nil }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

// MARK: - Store

final class EntryStore: ObservableObject {
    @Published var entries: [Entry] = []
    private let filesDir: URL
    private let metaFile: URL

    init() {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Save-See", isDirectory: true)
        filesDir = base.appendingPathComponent("files", isDirectory: true)
        metaFile = base.appendingPathComponent("entries.json")
        try? FileManager.default.createDirectory(at: filesDir, withIntermediateDirectories: true)
        load()
    }

    func addText(name: String, value: String) {
        entries.insert(Entry(name: name.trimmed, kind: .text(value.trimmed)), at: 0)
        save()
    }

    func addFile(name: String, sourceURL: URL) throws {
        let ext = sourceURL.pathExtension
        let stored = UUID().uuidString + (ext.isEmpty ? "" : "." + ext)
        try FileManager.default.copyItem(at: sourceURL, to: filesDir.appendingPathComponent(stored))
        entries.insert(Entry(name: name, kind: .file(original: sourceURL.lastPathComponent, stored: stored)), at: 0)
        save()
    }

    func remove(at offsets: IndexSet) {
        for i in offsets {
            if case .file(_, let stored) = entries[i].kind {
                try? FileManager.default.removeItem(at: filesDir.appendingPathComponent(stored))
            }
        }
        entries.remove(atOffsets: offsets)
        save()
    }

    func fileURL(for entry: Entry) -> URL? {
        guard case .file(_, let stored) = entry.kind else { return nil }
        return filesDir.appendingPathComponent(stored)
    }

    private func save() {
        try? JSONEncoder().encode(entries).write(to: metaFile)
    }

    private func load() {
        guard let data = try? Data(contentsOf: metaFile),
              let items = try? JSONDecoder().decode([Entry].self, from: data)
        else { return }
        entries = items
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: Any?
    private var appWindow: NSWindow?
    let store = EntryStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let hc = NSHostingController(rootView: MenuBarView().environmentObject(store))
        hc.preferredContentSize = NSSize(width: 300, height: 420)

        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 420)
        popover.behavior = .applicationDefined
        popover.animates = true
        popover.contentViewController = hc

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard",
                                   accessibilityDescription: "Save & See")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                guard let self, self.popover.isShown else { return }
                self.popover.performClose(nil)
            }
        }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    func openAppWindow() {
        popover.performClose(nil)
        if appWindow == nil {
            let hc = NSHostingController(rootView: AppWindowView().environmentObject(store))
            let win = NSWindow(contentViewController: hc)
            win.title = "Save & See"
            win.styleMask = [.titled, .closable, .resizable, .miniaturizable]
            win.setContentSize(NSSize(width: 720, height: 500))
            win.minSize = NSSize(width: 560, height: 380)
            win.center()
            win.delegate = self
            appWindow = win
        }
        NSApp.setActivationPolicy(.regular)
        appWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        appWindow = nil
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}

// MARK: - Entry Point

@main
struct Save_SeeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}
