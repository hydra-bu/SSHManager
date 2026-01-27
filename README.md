# SSH Manager

一个用于图形化管理本地SSH配置的macOS应用，使用SwiftUI构建。

## 功能特性

- ✅ 图形化编辑 `~/.ssh/config` 文件
- ✅ 可视化创建和管理SSH连接配置
- ✅ 连接测试功能（测试SSH连接是否可用）
- ✅ 与系统SSH客户端集成
- ✅ 拖拽密钥文件
- ✅ 实时配置预览
- ✅ 终端命令预览
- ✅ GitHub Actions CI/CD 构建
- ✅ 自动发布 DMG 安装包

## 项目结构

```
SSHManager/
├── Models/
│   └── SSHHost.swift          # SSH配置模型
├── Services/
│   ├── SSHConfigManager.swift # 配置文件管理
│   └── SSHConnector.swift     # SSH连接管理
├── Views/
│   ├── ContentView.swift      # 主界面
│   ├── HostEditorView.swift   # 主机编辑器
│   └── HostDetailView.swift   # 主机详情视图
├── Utils/
│   └── SSHConfigParser.swift  # 配置解析器
└── Assets.xcassets/           # 资源文件
```

## 无需Xcode构建

本项目配置了 GitHub Actions CI/CD，无需安装庞大的 Xcode 即可构建应用：

1. 将代码推送到 GitHub 仓库
2. CI 自动构建应用并生成 DMG 安装包
3. 在 GitHub Releases 中下载构建好的应用

GitHub Actions 会自动:
- 构建 macOS 应用
- 运行代码校验
- 生成 SSHManager.dmg 安装包
- 在打标签时自动发布 Release

## 手动构建（可选）

如果你有 Xcode，也可以在本地构建：

1. 使用 Xcode 打开 `SSHManager.xcodeproj`
2. 确保 macOS 部署目标设置为 12.0 或更高版本
3. 点击 "Build and Run" 按钮

或使用命令行：
```bash
cd SSHManager
xcodebuild -project SSHManager.xcodeproj -scheme SSHManager -destination 'platform=macOS' clean build
```

## 系统要求

- macOS 12.0 或更高版本
- Xcode 13.0 或更高版本（如需本地构建）

## 核心实现

- **SSH配置管理**: 直接读写 `~/.ssh/config` 文件
- **SSH连接**: 调用系统SSH客户端 (`/usr/bin/ssh`)
- **UI框架**: SwiftUI
- **架构模式**: MVVM
- **CI/CD**: GitHub Actions for macOS

## 使用说明

1. 启动应用后，可以从左侧列表查看已有的SSH配置
2. 点击"添加"按钮创建新的SSH连接配置
3. 填写主机信息（别名、主机名、用户名、端口等）
4. 选择身份文件（密钥文件）
5. 点击"测试连接"验证配置是否正确
6. 选择主机后点击"连接"按钮在终端中打开SSH连接

## 代码说明

### SSHHost 模型
定义SSH连接的基本属性：
- `alias`: 配置别名
- `hostname`: 主机地址
- `user`: 用户名
- `port`: 端口
- `identityFile`: 密钥文件路径
- `options`: 其他SSH选项

### SSHConfigManager
负责解析和生成SSH配置文件，实现配置的读写操作。

### SSHConnector
调用系统SSH命令进行连接测试和实际连接。

## CI/CD 配置

项目包含三个 GitHub Actions 工作流：

- `build.yml` - 每次 push 到 main 分支时自动构建
- `test.yml` - 代码校验和编译测试
- `release.yml` - 打标签时自动发布

## 未来扩展

- [ ] 批量导入其他SSH工具配置
- [ ] 钥匙串集成存储密码
- [ ] 自动更新功能
- [ ] SFTP文件浏览
- [ ] 连接历史记录

## 许可证

MIT