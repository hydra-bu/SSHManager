import Foundation

struct ConnectionRecord: Identifiable, Codable {
    let id: UUID
    let hostAlias: String
    let hostname: String
    let timestamp: Date
    let success: Bool
    let latency: Double?

    init(hostAlias: String, hostname: String, success: Bool, latency: Double? = nil) {
        self.id = UUID()
        self.hostAlias = hostAlias
        self.hostname = hostname
        self.timestamp = Date()
        self.success = success
        self.latency = latency
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

class ConnectionHistory: ObservableObject {
    static let shared = ConnectionHistory()

    @Published var records: [ConnectionRecord] = []
    private let maxRecords = 100
    private let storageKey = "connectionHistory"

    private init() {
        load()
    }

    func record(host: SSHHost, success: Bool, latency: Double? = nil) {
        let record = ConnectionRecord(
            hostAlias: host.alias,
            hostname: host.getUserAtHost(),
            success: success,
            latency: latency
        )

        DispatchQueue.main.async {
            self.records.insert(record, at: 0)
            if self.records.count > self.maxRecords {
                self.records = Array(self.records.prefix(self.maxRecords))
            }
            self.save()
        }
    }

    var recentHosts: [String] {
        var seen = Set<String>()
        return records.compactMap { record in
            guard !seen.contains(record.hostAlias) else { return nil }
            seen.insert(record.hostAlias)
            return record.hostAlias
        }
    }

    var successfulConnections: [ConnectionRecord] {
        records.filter { $0.success }
    }

    var failedConnections: [ConnectionRecord] {
        records.filter { !$0.success }
    }

    func clear() {
        records.removeAll()
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ConnectionRecord].self, from: data) {
            records = decoded
        }
    }
}
