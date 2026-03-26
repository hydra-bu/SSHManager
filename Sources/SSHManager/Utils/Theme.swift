import SwiftUI

struct Theme {
    // MARK: - 主色调
    static let primary = Color(nsColor: .controlAccentColor)  // 系统强调色
    static let success = Color(nsColor: .systemGreen)
    static let warning = Color(nsColor: .systemOrange)
    static let danger = Color(nsColor: .systemRed)
    static let info = Color(nsColor: .systemBlue)
    
    // MARK: - 背景色 (自适应浅色/深色模式)
    static let backgroundPrimary = Color(nsColor: .windowBackgroundColor)
    static let backgroundSecondary = Color(nsColor: .controlBackgroundColor)
    static let backgroundTertiary = Color(nsColor: .underPageBackgroundColor)
    
    // MARK: - 文字色
    static let textPrimary = Color(nsColor: .labelColor)
    static let textSecondary = Color(nsColor: .secondaryLabelColor)
    static let textTertiary = Color(nsColor: .tertiaryLabelColor)
    
    // MARK: - 交互状态
    static let selectedBackground = Color(nsColor: .selectedContentBackgroundColor)
    static let hoverBackground = Color(nsColor: .highlightColor).opacity(0.1)
    
    // MARK: - 分隔线
    static let divider = Color(nsColor: .separatorColor)
    
    // MARK: - 语义化颜色
    static func statusColor(for isSuccess: Bool) -> Color {
        isSuccess ? success : danger
    }
    
    static func connectionStatusColor(isOnline: Bool) -> Color {
        isOnline ? success : textTertiary
    }
}