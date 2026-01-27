# 构建说明

## GitHub Actions 自动构建

本项目配置了 GitHub Actions 工作流，可以自动构建和发布 macOS 应用。

### 工作流文件

- `.github/workflows/build.yml` - 主构建流程，触发于 push 和 pull request
- `.github/workflows/test.yml` - 测试流程，运行代码校验和编译测试
- `.github/workflows/release.yml` - 发布流程，当打标签时触发

### 构建命令说明

```bash
# 构建项目
xcodebuild -project SSHManager.xcodeproj \
  -scheme SSHManager \
  -destination 'platform=macOS' \
  clean build \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

# 归档项目
xcodebuild -project SSHManager.xcodeproj \
  -scheme SSHManager \
  -destination 'platform=macOS' \
  -archivePath "SSHManager.xcarchive" \
  archive \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

# 导出应用
xcodebuild -exportArchive \
  -archivePath "SSHManager.xcarchive" \
  -exportPath "." \
  -exportFormat APP \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO

# 创建DMG安装包
hdiutil create -volname "SSHManager" -srcfolder "SSHManager.app" -ov -format UDZO "SSHManager.dmg"
```

### 本地构建（可选）

如果你有 Xcode，也可以在本地构建：

1. 安装 Xcode 命令行工具
2. 运行：
```bash
cd SSHManager
xcodebuild -project SSHManager.xcodeproj -scheme SSHManager -destination 'platform=macOS' clean build
```

### 自动发布

当在 GitHub 上创建标签时（例如 `v1.0.0`），会自动触发发布流程，并创建 GitHub Release，包含：
- SSHManager.app - 应用程序包
- SSHManager.dmg - DMG 安装包

### CI/CD 流程

1. 代码推送到 main 分支时，自动运行测试和构建
2. 构建成功后生成 SSHManager.app 和 SSHManager.dmg
3. 构建产物作为 GitHub Actions artifacts 保存 30 天
4. 创建带有 `v` 前缀的标签时触发发布流程
5. 自动创建 GitHub Release 并附上构建产物

### 注意事项

- 项目使用了无代码签名构建，适合内部使用
- 如需发布到 Mac App Store，需要配置代码签名
- CI 构建环境是 macOS 14，使用 Xcode 15.2