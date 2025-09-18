import Foundation
import CryptoKit

// Per-item checkbox state in UserDefaults using key "hash(code::item)"
func prefKey(_ code: String, _ text: String) -> String {
    let str = "\(code)::\(text)"
    let digest = SHA256.hash(data: Data(str.utf8))
    return digest.compactMap { String(format: "%02x", $0) }.prefix(24).joined()
}

final class UserStore {
    static let shared = UserStore()
    private init() {}
    private let defaults = UserDefaults.standard

    private let userTCsKey = "user_tcs_json"

    func loadChecked() -> [String: Bool] {
        var out: [String: Bool] = [:]
        for (k, v) in defaults.dictionaryRepresentation() where v is Bool {
            out[k] = v as? Bool ?? false
        }
        return out
    }

    func toggleChecked(code: String, item: String) {
        let key = prefKey(code, item)
        let current = defaults.bool(forKey: key)
        defaults.set(!current, forKey: key)
    }

    func loadUserTCs() -> [TC] {
        guard let data = defaults.data(forKey: userTCsKey) else { return [] }
        do { return try JSONDecoder().decode(TCWrapper.self, from: data).tcs }
        catch { return [] }
    }

    func saveUserTCs(_ list: [TC]) {
        let wrapper = TCWrapper(tcs: list)
        if let data = try? JSONEncoder().encode(wrapper) {
            defaults.set(data, forKey: userTCsKey)
        }
    }
}
