import SwiftUI
import AppKit
import Observation

@Observable
@MainActor
final class SnippetStore {
    var snippets: [Snippet] = []
    private let key = "snippets"

    init() { load() }

    func add(name: String, value: String) {
        snippets.append(Snippet(
            name: name.trimmingCharacters(in: .whitespaces),
            value: value.trimmingCharacters(in: .whitespaces)
        ))
        save()
    }

    func remove(at offsets: IndexSet) {
        snippets.remove(atOffsets: offsets)
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(snippets) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let items = try? JSONDecoder().decode([Snippet].self, from: data)
        else { return }
        snippets = items
    }
}

struct Snippet: Codable, Identifiable {
    var id = UUID()
    var name: String
    var value: String
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    let store = SnippetStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let hc = NSHostingController(rootView: ContentView().environment(store))
        popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = hc

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(
            systemSymbolName: "doc.on.clipboard",
            accessibilityDescription: "Save & See"
        )
        statusItem.button?.action = #selector(toggle)
        statusItem.button?.target = self
    }

    @objc func toggle() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

@main
struct Save_SeeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}
