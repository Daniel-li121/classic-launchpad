# Classic Launchpad 使用手册

[English](User-Guide.md) | 简体中文

本手册适用于 Classic Launchpad 1.0.2，支持 macOS 15 或更高版本。

## 快速开始

1. 从“应用程序”文件夹打开 Classic Launchpad。
2. 使用拇指与另外三指向内捏合，随时重新显示 Classic Launchpad。
3. 使用双指左右轻扫进行翻页。
4. 点击 App 图标启动应用，Classic Launchpad 会自动收起。
5. 拇指与另外三指向外张开、按 `Esc`，或者点击空白区域即可收起。

## 核心功能

### 全屏浏览 App

Classic Launchpad 会扫描 `/Applications`、`/System/Applications` 和用户主目录中的“应用程序”文件夹。网格会根据当前屏幕自动使用 4–9 列和 3–5 行；一页放不下时会自动增加页面。

Helper、Shim、Updater、Agent、Daemon 和 XPC 服务等明确的技术组件会被隐藏，面向用户的系统启动器和菜单栏 App 仍会显示。

### 页面导航

- 在触控板上双指左右轻扫。
- 使用鼠标横向拖动整个页面。
- 按键盘左右方向键。
- 点击屏幕底部的页面圆点。

翻页采用可跟手操作的整页 Launchpad 风格动画。拖到第一页或最后一页之外时会出现边缘阻尼，不会越界翻页。

### 搜索

使用顶部搜索栏或按 `⌘F`。搜索既支持 App 显示名称，也支持 Bundle ID。清空搜索内容后会回到保存的分页布局。

### 排列 App

将一个图标拖到另一个图标上即可调整位置。需要移动到其他页面时，把图标拖到屏幕左侧或右侧边缘并停留大约半秒，页面会自动切换，然后可在目标页面放下图标。

图标顺序和所在页面会在下次启动时保留。把 App 从一页移到另一页后，不会自动把后一页的第一个 App 拉回来填补空位。搜索状态下不能排序，请先清空搜索栏。

## 触控板手势

| 手势 | 功能 |
| --- | --- |
| 拇指与另外三指向内捏合 | 显示 Classic Launchpad |
| 拇指与另外三指向外张开 | 收起 Classic Launchpad |
| 双指左右轻扫 | 在 Classic Launchpad 显示时翻页 |

只要 App 在后台运行，四指手势就可以使用。识别器会忽略用于切换空间的四指横向滑动。

## 设置说明

点击搜索栏旁边的齿轮按键，或按 `⌘,` 打开设置。

| 设置 | 默认值 | 行为 |
| --- | --- | --- |
| 后台运行 | 开启 | 收起界面后 App 继续在后台运行，并等待触控板手势。关闭后，收起界面会直接退出 App。 |
| 接管四指手势 | 开启 | 使用传统捏合手势打开 Classic Launchpad。关闭后无需退出 App，也会把手势交还给 macOS。 |
| 登录时自动启动 | 关闭 | 登录 macOS 后自动启动。macOS 可能要求在“登录项与扩展”中批准。 |

建议先把 App 移入“应用程序”文件夹，再开启登录时自动启动。

## 收起与退出的区别

这两个操作的含义不同：

- **收起：**点击 App、点击空白区域、按 `Esc` 或使用四指张开手势，只会隐藏界面。开启“后台运行”时，Classic Launchpad 仍在运行，并继续接收捏合手势。
- **退出：**按 `⌘Q`、选择“Classic Launchpad → 退出 Classic Launchpad”，或者从 Dock 退出。App 会停止所有触控板监听，并把手势交还给 macOS。

如果关闭了“后台运行”，任何收起操作都会同时退出 App。

## 容易忽略的功能与行为

### 退出后会恢复系统 Apps/Launchpad 手势

Classic Launchpad 接管四指手势时，系统自带的 Apps 界面（较早的 macOS 版本中称为 Launchpad）无法同时响应同一个手势。彻底退出 Classic Launchpad 后，App 会释放底层触控板监听，恢复 macOS 原有的手势响应。

在部分 macOS 版本中，Dock 可能保留旧的手势注册。为了确保系统 Apps 手势恢复，如果之前使用过底层手势监听，Classic Launchpad 会在退出时短暂重载 Dock。Dock 可能消失后立即重新出现，这是正常现象，不会关闭正在运行的 App 或窗口。

如果希望 Classic Launchpad 继续运行，也可以在设置中关闭“接管四指手势”，手势会直接交还给 macOS。

### App 列表会自动刷新

每次显示 Classic Launchpad 时，如果上次扫描已经超过 60 秒，就会自动重新扫描已安装 App。刚安装或删除 App 后，可以按 `⌘R` 立即扫描。

### 页面空位会被保留

分页归属与排序会分别保存。把图标移动到后一页时，原页面会有意保留空位，不会把其他图标自动向前拉。

### 搜索会临时改变分页

搜索结果会从第一页开始重新分页，但不会修改保存的图标顺序。清空搜索栏之前无法拖动排序。

### 壁纸背景会被缓存

为了保持翻页动画流畅，模糊壁纸只会在 Classic Launchpad 启动时渲染一次。如果 App 运行期间更换了桌面壁纸，请彻底退出并重新打开 Classic Launchpad，以更新背景。

## 键盘快捷键

| 快捷键 | 功能 |
| --- | --- |
| `Esc` | 收起 Classic Launchpad |
| `←` / `→` | 上一页或下一页 |
| `⌘F` | 显示 Classic Launchpad 并聚焦搜索栏 |
| `⌘R` | 重新扫描已安装 App |
| `⌘,` | 打开设置 |
| `⇧⌘L` | 使用 App 菜单命令显示 Launchpad |
| `⌘Q` | 彻底退出并恢复系统手势 |

## 常见问题

### 四指手势无法打开 Classic Launchpad

- 确认 Classic Launchpad 仍在运行。
- 打开设置并启用“接管四指手势”。
- 如果关闭了“后台运行”，收起界面后 App 已经退出；请重新打开后再尝试手势。
- 如果触控板刚刚断开或更换，请退出并重新打开 Classic Launchpad。

### 新安装的 App 没有出现

按 `⌘R` 重新扫描，并确认 App 位于 `/Applications`、`/System/Applications` 或用户主目录中的“应用程序”文件夹。

### 登录时自动启动需要批准

使用 Classic Launchpad 设置中显示的按键，打开“系统设置 → 通用 → 登录项与扩展”，然后批准 Classic Launchpad。

### 系统 Apps/Launchpad 手势没有响应

使用 `⌘Q` 彻底退出 Classic Launchpad，等待 Dock 重载后再尝试。开启后台运行时，仅收起界面并不等于退出 App。

## 反馈问题

请先搜索[现有 Issues](https://github.com/Daniel-li121/classic-launchpad/issues)，也可以[创建新 Issue](https://github.com/Daniel-li121/classic-launchpad/issues/new)。请提供 Classic Launchpad 版本、macOS 版本、Mac 型号或芯片、复现步骤、预期和实际结果，以及有帮助的截图或录屏。
