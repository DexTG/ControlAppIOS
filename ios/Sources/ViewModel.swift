import Foundation
import Combine

@MainActor
final class IFACViewModel: ObservableObject {
    @Published private(set) var all: [TC] = []         // built-in + user merged
    @Published private(set) var filtered: [TC] = []
    @Published private(set) var checked: [String: Bool] = [:]
    @Published var query: String = "" {
        didSet { applyFilter() }
    }
    @Published private(set) var overallProgress: Double = 0

    private var builtIn: [TC] = []
    private var user: [TC] = []

    init() {
        Task { await loadAll() }
    }

    func loadAll() async {
        do {
            builtIn = try await loadFromBundle()
        } catch {
            builtIn = []
        }
        user = UserStore.shared.loadUserTCs()
        checked = UserStore.shared.loadChecked()
        mergeAndRecalc()
    }

    func setQuery(_ q: String) {
        query = q
    }

    func toggle(_ tc: TC, _ item: String) {
        UserStore.shared.toggleChecked(code: tc.code, item: item)
        checked[prefKey(tc.code, item)] = !(checked[prefKey(tc.code, item)] ?? false)
        recalcProgress()
    }

    func addCustomTc(code: String?, name: String, items: [String], keywords: String) {
        let c: String = {
            if let code = code, !code.trimmingCharacters(in: .whitespaces).isEmpty { return code }
            let next = user.count + 1
            return String(format: "USER-%03d", next)
        }()
        let new = TC(code: c,
                     name: name.isEmpty ? "Custom Topic \(c)" : name,
                     items: items.isEmpty ? ["Example bullet 1", "Example bullet 2"] : items,
                     keywords: keywords)
        user.removeAll { $0.code == c }
        user.append(new)
        UserStore.shared.saveUserTCs(user)
        mergeAndRecalc()
    }

    private func mergeAndRecalc() {
        all = builtIn + user
        applyFilter()
        recalcProgress()
    }

    private func applyFilter() {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            filtered = all
            return
        }
        let q = query.lowercased()
        filtered = all.filter { tc in
            tc.code.lowercased().contains(q) ||
            tc.name.lowercased().contains(q) ||
            tc.keywords.lowercased().contains(q) ||
            tc.items.contains(where: { $0.lowercased().contains(q) })
        }
    }

    private func recalcProgress() {
        let total = all.reduce(0) { $0 + $1.items.count }
        let done = all.reduce(0) { sum, tc in
            sum + tc.items.filter { checked[prefKey(tc.code, $0)] == true }.count
        }
        overallProgress = total == 0 ? 0 : Double(done) / Double(total)
    }
}

// Load the bundled JSON
func loadFromBundle() async throws -> [TC] {
    guard let url = Bundle.main.url(forResource: "ifac_tcs", withExtension: "json") else {
        throw IFACError.assetNotFound
    }
    let data = try Data(contentsOf: url)
    let wrapper = try JSONDecoder().decode(TCWrapper.self, from: data)
    return wrapper.tcs
}
