import SwiftUI
import Observation

@Observable
final class SnippetStore {
    var snippets: [Snippet] = []
    private let key = "snippets"

    init() { load() }

    func add(name: String, value: String) {
        snippets.append(Snippet(name: name.trimmingCharacters(in: .whitespaces),
                                value: value.trimmingCharacters(in: .whitespaces)))
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

@main
struct Save_SeeApp: App {
    @State private var store = SnippetStore()

    var body: some Scene {
        MenuBarExtra("Save & See", systemImage: "doc.on.clipboard") {
            ContentView()
                .environment(store)
        }
        .menuBarExtraStyle(.window)
    }
}
