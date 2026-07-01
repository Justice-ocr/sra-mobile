<div align="center">

# 📱 SRA Mobile

**StarRailAssistant（SRA）WebUI 手机远程控制端**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)](https://www.android.com)
[![Version](https://img.shields.io/badge/version-1.0.0-00C8D7)](pubspec.yaml)
[![Upstream PR](https://img.shields.io/badge/upstream-PR%20%23209-8378FF)](https://github.com/Shasnow/StarRailAssistant/pull/209)
[![License](https://img.shields.io/badge/license-GPLv3-informational)](https://github.com/Shasnow/StarRailAssistant/blob/main/LICENSE)

随时随地远程控制崩坏：星穹铁道自动化助手 —— 启动任务、编辑配置、查看日志、接收带截图的完成通知。

</div>

---

通过 SRA 在 PC 上开启的 WebUI 远程服务，手机可以远程启动/停止任务、查看实时日志、编辑配置与全局设置、管理拓展功能，并在任务完成时收到带游戏截图的本地通知。UI 对照 SRA WebUI（PR #209）前端精确复刻，并针对移动端做了液态玻璃、动态波浪、深浅主题等适配。

> 💡 本项目是 SRA 的**第三方手机客户端**，不修改 SRA 本体即可使用（游戏截图通知功能需要配套的后端截图接口，详见下文）。

<!--
📸 界面截图（待补充真实机型截图后替换本注释块）：
<p align="center">
  <img src="docs/screenshots/tasks.png" width="220" alt="任务控制" />
  <img src="docs/screenshots/config.png" width="220" alt="配置编辑" />
  <img src="docs/screenshots/settings.png" width="220" alt="系统设置" />
  <img src="docs/screenshots/extensions.png" width="220" alt="拓展页" />
</p>
-->

## 目录

- [功能特性](#-功能特性)
- [技术栈](#️-技术栈)
- [项目结构](#-项目结构)
- [对接的 SRA WebUI 接口](#-对接的-sra-webui-接口)
- [构建与运行](#-构建与运行)
- [权限说明](#-权限说明)
- [许可](#-许可)

---

## ✨ 功能特性

### 🎮 任务控制
- 实时显示任务运行状态（运行中 / 已停止）、当前任务名与所用配置
- 一键启动任务（可选择配置）/ 停止任务
- 3 秒轮询自动刷新状态，PC 与手机双向同步（能感知 SRA.exe 本机启动的任务）

### 🗂️ 配置管理
- 配置列表查看、快速启动、进入编辑
- 配置编辑器对照 SRA `TaskEditor` 精确复刻，按分区组织，**直观表单而非裸 JSON**：
  - **启动游戏**：渠道（官服 / B服 / 国际服）、游戏路径、全局路径开关、自动登录、重新登录；账号密码独立处理（留空保留已存凭据）
  - **清体力**：任务清单增删（副本 / 关卡来自后端元数据，避免手填 ID 出错）、补充体力方式、支援角色、培养目标、多倍活动检测、各活动关卡选择
  - **领取奖励**：7 项奖励复选（漫游签证 / 派遣 / 邮件 / 每日实训 / 无名勋礼 / 巡星之礼 / 兑换码）+ 兑换码输入
  - **旷宇纷争**：差分宇宙、货币战争（类型 / 难度 / 攻略 / 刷开局条件）
  - **任务完成后**：登出 / 退出游戏 / 关闭程序复选 + 电源动作单选（无 / 关机 / 休眠，互斥）

### 📜 运行日志
- SSE 实时日志流，自动滚动到底部
- 可清空当前日志
- 入口进入「通知历史」页

### 🧩 拓展
对照 SRA 桌面端拓展页复刻的三张卡片：
- **自动对话**：启用 / 跳过剧情开关，应用到后端
- **猫猫糕友人帐**：一键打开 [catcake.hoshimi.io](https://catcake.hoshimi.io/) 查询猫猫糕 UID
- **抽卡资源预测**：版本参数、扫描开关、手动数量与覆写，可直接运行预测

### ⚙️ 系统设置
对照 SRA `SettingsPage` 复刻，分 3 个标签页：
- **启动与识图**：自动检测路径、启动参数、显示模式、窗口大小、OCR / 模板匹配置信度滑块、停止热键等
- **远程连接**：WebUI 访问令牌、服务状态、外部后端配置
- **通知**：12 个第三方通知渠道（Webhook / Bark / 钉钉 / Discord / 飞书 / OneBot / Server酱 / Telegram / 企业微信 / 息息推 / 邮件），敏感字段隐藏；SMTP 授权码独立处理（留空不修改）

### 🔔 App 本地通知（不依赖 SRA 本体）
- 任务由运行转为停止时，自动弹出系统通知
- 通知可附带**游戏实时截图**（需后端截图接口，见下）
- 「发送测试通知」按钮，使用内置 SRA 头像验证通知通道
- **通知历史**：独立页面，时间倒序；精简列表（不显示截图），点击查看详情大图；记录保留 7 天自动清理

### 🎨 界面与交互
- **深色 / 浅色主题**切换，登录页与控制台均可切换，状态持久化
- **动态波浪**：背景图与操作面板衔接处三层不同透明度的波浪动画，循环无缝
- **幕布面板**：操作台可上拉至全屏覆盖背景，波浪随覆盖进度平滑收起
- **悬浮液态玻璃导航**：底部导航毛玻璃材质，下滑自动隐藏、上滑出现，避免遮挡内容
- 顶部毛玻璃状态栏，在线状态呼吸灯

---

## 🛠️ 技术栈

- **Flutter** 3.x / Dart 3
- **状态管理**：[provider](https://pub.dev/packages/provider)
- **路由**：[go_router](https://pub.dev/packages/go_router)
- **网络**：[dio](https://pub.dev/packages/dio)（含 SSE 流式日志）
- **本地存储**：[shared_preferences](https://pub.dev/packages/shared_preferences)、[flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)
- **本地通知**：[flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)（支持大图 BigPicture）
- **其他**：[url_launcher](https://pub.dev/packages/url_launcher)、[path_provider](https://pub.dev/packages/path_provider)、[google_fonts](https://pub.dev/packages/google_fonts)

---

## 📁 项目结构

```
lib/
├── main.dart                          # 入口，初始化 Provider、主题、通知服务
├── config/
│   ├── routes.dart                    # go_router 路由
│   └── theme.dart                     # 深浅主题定义
├── models/
│   └── task_status.dart               # 任务状态模型
├── providers/
│   ├── auth_provider.dart             # 登录鉴权状态
│   ├── task_provider.dart             # 任务状态轮询、启停、完成通知触发
│   └── theme_provider.dart            # 主题切换与持久化
├── screens/
│   ├── login_screen.dart              # 登录页（服务器地址 + 令牌）
│   ├── home_screen.dart               # 主框架：背景、波浪、幕布面板、悬浮导航、任务/配置/日志页
│   ├── config_editor_page.dart        # 配置编辑器（5 分区）
│   ├── settings_page_view.dart        # 系统设置（3 标签页）
│   ├── extensions_page_view.dart      # 拓展页（自动对话 / 猫猫糕 / 抽卡预测）
│   └── notification_history_page.dart # 通知历史
├── services/
│   ├── api_service.dart               # SRA WebUI REST / SSE 接口封装
│   ├── storage_service.dart           # 安全存储封装
│   ├── app_notification_service.dart  # 本地通知发送（含大图）
│   └── notification_history.dart      # 通知历史存储（7 天保留）
└── widgets/
    └── form_fields.dart               # 通用表单组件（开关/下拉/数字/滑块/复选等）
```

---

## 🔌 对接的 SRA WebUI 接口

| 方法 | 路径 | 用途 |
|------|------|------|
| POST | `/api/Auth/verify` | 校验访问令牌 |
| GET  | `/api/Task/status` | 任务状态 |
| POST | `/api/Task/run` | 启动任务 |
| POST | `/api/Task/stop` | 停止任务 |
| GET  | `/api/Task/logs/stream` | SSE 实时日志 |
| GET  | `/api/Task/screenshot` | 游戏窗口截图（PNG，需后端支持，见下） |
| GET/PUT | `/api/Configs`、`/api/Configs/{name}` | 配置列表 / 读写 |
| GET/PUT | `/api/Settings` | 全局设置读写 |
| GET  | `/api/Metadata/trailblaze-power/tasks` | 锄大地副本 / 关卡定义 |
| POST | `/api/Extensions/auto-plot` | 自动对话设置 |
| POST | `/api/Extensions/warp-forecast/run` | 运行抽卡预测 |

鉴权方式：请求头 `X-Api-Key: <令牌>`。

> **关于游戏截图通知**：SRA WebUI 后端原本没有截图接口。本项目配套在 `SRAFrontend.Server` 增加了 `GET /Task/screenshot`（通过 Win32 PrintWindow 抓取游戏窗口），相关后端改动已提交至上游 [PR #209](https://github.com/Shasnow/StarRailAssistant/pull/209)。若使用的 SRA 后端不含该接口，截图通知会自动降级为纯文字通知，其余功能不受影响。

---

## 🚀 构建与运行

### 环境要求
- Flutter SDK 3.x（Dart 3）
- Android SDK（compileSdk 34，minSdk 21）
- 一台开启了 USB 调试的 Android 设备或模拟器

### 步骤
```bash
# 获取依赖
flutter pub get

# 连接设备后直接运行
flutter run

# 或构建 APK
flutter build apk --debug      # 调试包
flutter build apk --release    # 发布包
```

构建产物位于 `build/app/outputs/flutter-apk/`。

### 使用前准备
1. 在 PC 端 SRA 的「设置 → 高级 / 远程连接」中开启 **WebUI 远程服务**，记下端口（默认 5074）与访问令牌
2. 确保手机与 PC 在同一局域网（或可访问的网络）
3. 打开 App，在登录页填写服务器地址（如 `http://192.168.x.x:5074`）与访问令牌，连接即可

---

## 🔐 权限说明

- **网络**：访问 SRA WebUI 服务
- **通知（POST_NOTIFICATIONS）**：发送任务完成 / 测试通知（Android 13+ 首次使用会请求授权）

---

## 📄 许可

本项目为 StarRailAssistant 的第三方客户端，请遵循上游 [StarRailAssistant](https://github.com/Shasnow/StarRailAssistant) 的相关许可与使用条款。

---

<div align="center">

Made with 💙 for StarRailAssistant · 与 [SRA 主项目](https://github.com/Shasnow/StarRailAssistant) 配套使用

</div>
