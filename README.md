# SSH Manager

macOS原生SSH配置管理应用，提供图形化界面来管理`~/.ssh/config`文件。

## 🚀 核心功能

- **图形化SSH配置管理**：无需手动编辑`~/.ssh/config`文件
- **向导式主机创建**：表单式输入，避免格式错误
- **实时配置预览**：显示生成的SSH配置内容
- **连接测试**：验证SSH配置是否正确
- **系统SSH集成**：直接调用系统SSH客户端，无需重复实现协议
- **Keychain集成**：安全存储密码（可选）

## 🎯 极致用户体验设计

解决SSH配置管理的四大痛点：
- **认知负担**：用户无需记住字段名、格式、路径
- **输入繁琐**：智能表单减少重复输入
- **错误易发**：实时验证防止格式错误
- **缺乏反馈**：连接测试提供即时反馈

## 🛠️ 技术栈

- **平台**：macOS 13.0+
- **语言**：Swift 5.7
- **框架**：SwiftUI
- **构建**：Xcode 15.2
- **CI/CD**：GitHub Actions

## 📦 安装

1. 从[Releases](https://github.com/hydra-bu/SSHManager/releases)下载最新版本
2. 双击`SSHManager.dmg`文件
3. 将`SSHManager.app`拖拽到`Applications`文件夹
4. 首次运行时可能需要在系统偏好设置中允许运行

## 🔧 开发

### 本地开发
```bash
# 克隆仓库
git clone https://github.com/hydra-bu/SSHManager.git
cd SSHManager

# 使用Xcode打开项目
open SSHManager.xcodeproj
```

### CI/CD构建
所有提交都会自动触发GitHub Actions构建，生成可分发的`.app`和`.dmg`文件。

## 📁 项目结构

```
SSHManager/
├── Sources/SSHManager/
│   ├── Models/           # 数据模型
│   ├── Services/         # 业务逻辑
│   ├── Views/            # 用户界面
│   ├── Utils/            # 工具类
│   └── Assets.xcassets/  # 应用图标
├── .github/workflows/    # GitHub Actions工作流
└── SSHManager.xcodeproj/ # Xcode项目文件
```

## 📝 当前进度

✅ **MVP功能完成**：
- [x] SSH配置模型 (SSHHost)
- [x] 配置文件管理 (SSHConfigManager)
- [x] 系统SSH连接 (SSHConnector)
- [x] 主界面布局 (ContentView)
- [x] 配置编辑器 (HostEditorView)
- [x] 配置详情预览 (HostDetailView)
- [x] 专业应用图标
- [x] 标准DMG安装包
- [x] GitHub Actions CI/CD自动化构建

## 🚧 后续功能规划

- [ ] Keychain密码存储集成
- [ ] 批量导入/导出功能
- [ ] 自动更新支持 (Sparkle)
- [ ] iCloud同步配置
- [ ] 文件拖拽支持
- [ ] 更多SSH选项支持

## 📄 许可证

Copyright © 2026 hydra-bu. All rights reserved.