# Classic Launchpad

一个恢复传统 macOS Launchpad 全屏应用浏览体验的原生应用。

## 功能

- 全屏显示 `/Applications`、`/System/Applications` 和用户应用目录中的 App
- 自动使用当前桌面壁纸并做模糊处理
- 多页网格、触控板两指左右扫、鼠标横向拖动、左右方向键翻页
- 跟手拖动、边缘阻尼和传统 Launchpad 风格的整页横向滑动动画
- 缓存式壁纸模糊、邻页按需渲染和应用图标预加载
- 内置设置：后台运行、四指手势接管和登录时自动启动
- 传统“拇指 + 三指”捏拢全局唤出、张开收起手势
- 按名称或 Bundle ID 搜索
- 单击图标启动应用，启动后自动收起
- 点击网格之外的空白背景收起，无额外关闭按钮
- `Esc` 收起，`⌘F` 搜索，`⌘R` 重新扫描，`⇧⌘L` 从菜单重新显示

## 构建

需要 macOS 15 或更高版本，以及 Swift 6 工具链。首次打开 App 后它会在后台保持运行，之后可随时使用四指捏合手势。

```bash
./scripts/package-app.sh
open "dist/Classic Launchpad.app"
```

打包脚本会构建 Release 版本、生成应用图标、创建 `.app` 并进行本地临时签名。

生成同时兼容 Apple Silicon 与 Intel 的分享 ZIP：

```bash
./scripts/package-app.sh --universal
```

手势监听使用 MIT 许可的 [OpenMultitouchSupport](https://github.com/Kyome22/OpenMultitouchSupport)，它通过 macOS 私有 MultitouchSupport 框架读取原始触点。因此本地版无需辅助功能权限，但不适用于 Mac App Store 分发。

## 开发

```bash
swift run ClassicLaunchpad
swift test
```
