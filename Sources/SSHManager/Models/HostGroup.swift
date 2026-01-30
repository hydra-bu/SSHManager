import Foundation
import SwiftUI

class HostGroup: ObservableObject, Identifiable, Codable, Equatable {
    let id: UUID
    @Published var name: String
    @Published var icon: String
    @Published var color: String
    @Published var isExpanded: Bool
    @Published var sortOrder: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "folder",
        color: String = "blue",
        isExpanded: Bool = true,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.isExpanded = isExpanded
        self.sortOrder = sortOrder
    }
    
    var swiftUIColor: Color {
        switch color {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "gray": return .gray
        default: return .blue
        }
    }
    
    static let defaultGroups = [
        HostGroup(name: "生产环境", icon: "server.rack", color: "red", sortOrder: 0),
        HostGroup(name: "测试环境", icon: "testtube.2", color: "yellow", sortOrder: 1),
        HostGroup(name: "开发环境", icon: "hammer", color: "green", sortOrder: 2),
        HostGroup(name: "云服务器", icon: "cloud", color: "blue", sortOrder: 3)
    ]
    
    enum CodingKeys: String, CodingKey {
        case id, name, icon, color, isExpanded, sortOrder
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.icon = try container.decode(String.self, forKey: .icon)
        self.color = try container.decode(String.self, forKey: .color)
        self.isExpanded = try container.decode(Bool.self, forKey: .isExpanded)
        self.sortOrder = try container.decode(Int.self, forKey: .sortOrder)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(icon, forKey: .icon)
        try container.encode(color, forKey: .color)
        try container.encode(isExpanded, forKey: .isExpanded)
        try container.encode(sortOrder, forKey: .sortOrder)
    }
    
    static func == (lhs: HostGroup, rhs: HostGroup) -> Bool {
        lhs.id == rhs.id
    }
}

enum GroupColor: String, CaseIterable {
    case red, orange, yellow, green, blue, purple, pink, gray
    
    var displayName: String {
        switch self {
        case .red: return "红色"
        case .orange: return "橙色"
        case .yellow: return "黄色"
        case .green: return "绿色"
        case .blue: return "蓝色"
        case .purple: return "紫色"
        case .pink: return "粉色"
        case .gray: return "灰色"
        }
    }
}
