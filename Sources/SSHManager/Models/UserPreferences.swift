import Foundation

enum TerminalType: String, Codable, CaseIterable {
    case terminal = "Terminal"
    case iTerm2 = "iTerm2"

    var displayName: String {
        switch self {
        case .terminal: return "Terminal.app"
        case .iTerm2: return "iTerm2"
        }
    }
}

class UserPreferences: ObservableObject {
    static let shared = UserPreferences()

    private let defaults = UserDefaults.standard

    @Published var preferredTerminal: TerminalType {
        didSet {
            defaults.set(preferredTerminal.rawValue, forKey: Keys.preferredTerminal)
        }
    }

    @Published var testTimeout: Int {
        didSet {
            defaults.set(testTimeout, forKey: Keys.testTimeout)
        }
    }

    @Published var defaultPort: Int {
        didSet {
            defaults.set(defaultPort, forKey: Keys.defaultPort)
        }
    }

    @Published var enableCompression: Bool {
        didSet {
            defaults.set(enableCompression, forKey: Keys.enableCompression)
        }
    }

    private init() {
        let terminalRaw = defaults.string(forKey: Keys.preferredTerminal) ?? TerminalType.terminal.rawValue
        self.preferredTerminal = TerminalType(rawValue: terminalRaw) ?? .terminal
        self.testTimeout = defaults.integer(forKey: Keys.testTimeout) == 0 ? 10 : defaults.integer(forKey: Keys.testTimeout)
        self.defaultPort = defaults.integer(forKey: Keys.defaultPort) == 0 ? 22 : defaults.integer(forKey: Keys.defaultPort)
        self.enableCompression = defaults.bool(forKey: Keys.enableCompression)
    }

    private enum Keys {
        static let preferredTerminal = "preferredTerminal"
        static let testTimeout = "testTimeout"
        static let defaultPort = "defaultPort"
        static let enableCompression = "enableCompression"
    }
}
