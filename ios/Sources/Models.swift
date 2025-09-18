import Foundation

struct TC: Identifiable, Codable, Hashable {
    var id: String { code }
    let code: String
    let name: String
    var items: [String]
    var keywords: String = ""
}

struct TCWrapper: Codable {
    let tcs: [TC]
}

enum IFACError: Error {
    case assetNotFound
}
