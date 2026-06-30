# TripPet 1.0.8 工作区本地改动汇总

## 基线

当前主工作区：`/Users/qianyu/Documents/Trip`。

当前本地分支：`1.0.8待长期测试版`，HEAD：`a560e67f`。

当前 1.0.8 相关本地分支：

- `1.0.8待长期测试版`
- `1.0.8成就系统`
- `codex/1.0.8-mailbox-butterfly-consolidation`

当前 worktree：

- `/Users/qianyu/Documents/Trip` -> `1.0.8待长期测试版`
- `/Users/qianyu/Documents/Trip/.worktrees/1.0.6文本库` -> `1.0.6文本库`
- `/Users/qianyu/Documents/Trip/.worktrees/trippet-1.0.5` -> `trippet-1.0.5`
- `/private/tmp/trip-origin-1.0.7-clean-2248`、`/private/tmp/TripPet-a560e67f-install` 为 detached 临时检查工作区。

本次文档更新日期：`2026-06-29`。

本文延续 2026-06-26 的本地收束记录，并新增 2026-06-28 项目改动汇总与 2026-06-29 长期测试包收束记录。本文只整理当前工作区状态，不提交、不 push。

## 2026-06-29 1.0.8 长期测试包收束记录

### 本次排除项

- 按要求排除「重做穷人乍富旅行勋章」任务。
- 按要求排除「补充 iCloud 存储逻辑」任务。
- 已确认该任务的候选素材主要位于 `TripPet/Resources/ArtSourceRaster/Achievements/candidates/`，不在 `TripPet.xcodeproj/project.pbxproj` 的 Copy Bundle Resources 中。
- 正式运行时仍使用 `achievement_medal_travel_tier_001`；app-facing PNG 与正式 source 哈希一致：
  - `ae6b7d3e2b134ccf26878814fc5c8010a8423a021d8a8e77e9d00c82f1bfabbf`
- 被排除的 absurd/simple v2 候选图哈希为：
  - `97df331fda40252b6b35e2cbeaceffbaf342ee6d1ee38b2f1951964119cd2640`
- 最终 zip 内容扫描没有命中 `TripPetTests`、`xctest`、`absurd`、`candidates`、`travel_absurd`。

### 本次纳入 1.0.8 长测包的新增改动

- 成就系统与成就页：新增成就模型、`AchievementEngine`、成就墙页面、底部「成就」tab、旅行/脚步/明信片三类勋章进度。
- 成就正式美术：新增 `Assets.xcassets/Achievements/` 正式勋章和背景资源；候选重做素材不进入包。
- 邮箱森林小屋：新增未读/空邮箱场景、邮箱热点、收藏入口、未读堆叠和详情已读结算逻辑。
- 邮箱蝴蝶动效：新增 `ButterflyMailboxAnimation` bundle 资源和 SwiftUI 逐帧播放逻辑。
- 小屋出发转场：修复出发视频白框、播放首帧等待、结束后底层页面抖动；增加视频预热和遮罩 ready 后再刷新小屋动物。
- 成就页 UI 收束：切动物时类别按钮保持固定；动物名字下方不再显示品种。
- 地球页优化：底部 tab 文案改为「地球」，首屏后只预热 map tab，降低首次进入加载等待。
- HealthKit 与步数文案：无数据不再误判失败，显示同步中或重试读取；设置页/onboarding 同步调整。
- 旅行分配与通知：活跃目的地间距策略、通知路由到邮箱、赠票写入 `Ticket.animalId`，支持成就归属。
- 资源清理：删除一批确认不再使用的旧 app-facing imageset；新增资源审计脚本和 review 记录。
- 版本收束：`MARKETING_VERSION` 和设置页版本文案更新为 `1.0.8`。

### 测试与打包

- 全量测试命令：
  - `xcodebuild test -project TripPet.xcodeproj -scheme TripPet -destination 'id=0F39C893-4E39-4C55-BEA7-9F0D221D664D' -derivedDataPath DerivedDataCodex`
- 结果：`TEST SUCCEEDED`。
- 测试结果：
  - `/Users/qianyu/Documents/Trip/DerivedDataCodex/Logs/Test/Test-TripPet-2026.06.29_08-49-33-+0800.xcresult`
- 打包构建命令：
  - `xcodebuild build -project TripPet.xcodeproj -scheme TripPet -configuration Debug -destination 'id=0F39C893-4E39-4C55-BEA7-9F0D221D664D' -derivedDataPath BuildArtifacts/DerivedData-1.0.8-longtest-package`
- 结果：`BUILD SUCCEEDED`。
- 最终 app：
  - Bundle id：`com.qianyu.TripPet`
  - Version：`1.0.8`
  - Build：`1`
  - App size：`228M`
- 最终模拟器 Debug 包：
  - `/Users/qianyu/Documents/Trip/BuildArtifacts/TripPet-1.0.8-longtest-20260629-0851-simulator-debug.app.zip`
  - Size：`214M`
  - SHA-256：`c6c461a70183333aec158e464c17c1290ca925b939a75a06244aa45ca2f62158`
- 模拟器清装验证：
  - 已卸载 `com.qianyu.TripPet` 和历史包名 `com.edy.bubugarden`，清理旧沙盒数据。
  - 已安装最终 `.app` 并成功启动，进程号 `15338`。
  - 首启截图：`/Users/qianyu/Documents/Trip/BuildArtifacts/TripPet-1.0.8-longtest-20260629-0851-launch.png`。
- 注意：
- 构建/测试期间 Xcode 多次输出真实设备锁屏导致的 `notification_proxy` warning；目标 destination 是模拟器，测试和构建均成功。
- 本次没有提交 commit，没有 push，没有上传，也没有创建 PR。

## 2026-06-29 晚间真机修复与工作区整理

### 本次明确不处理

- 「重做穷人乍富旅行勋章」：继续保持排除，不重做、不替换正式勋章资源。
- 「补充 iCloud 存储逻辑」：继续保持排除，不改持久化/同步架构。

### 首次赠票崩溃修复

证据：

- 真机：`qianyu`，iPhone 15 Pro Max，device id `BC67627A-9384-5020-AD2D-51F02D4E8C2C`。
- crash log：
  - `/Users/qianyu/Documents/Trip/BuildArtifacts/device-crash-logs/TripPet-2026-06-29-205959.ips`
  - `/Users/qianyu/Documents/Trip/BuildArtifacts/device-crash-logs/trippet-first-ticket-devicectl-launch.log`
- 崩溃原因：
  - `NSInvalidArgumentException`
  - `AVPlayer cannot service a preroll request until its status is AVPlayerStatusReadyToPlay.`
  - 调用栈指向 `DepartureTransitionPlaybackPreloader.preroll(_:)`。

处理：

- `TripPet/Features/Cabin/DepartureCardTransitionOverlay.swift`
  - `DepartureTransitionPlaybackPreloader.preroll(_:)` 调用前新增 `waitUntilPlayerReadyForPreroll`。
  - 只有 `AVPlayer.status == .readyToPlay` 时才请求 preroll；失败或超时则跳过 preroll，避免真机首赠票闪退。

验证：

- `CabinViewModelTests`：`TEST SUCCEEDED`。
- 真机 Debug build：`BUILD SUCCEEDED`。
- 已覆盖安装到 `com.qianyu.TripPet` 并由真机复现确认：首次赠票不再崩溃。

### 出发视频首秒卡顿与闪烁修复

证据：

- 用户真机反馈：崩溃修复后视频仍会卡约 1 秒，并出现一次闪烁。
- 本地 AVFoundation 资源检查：
  - `AVAssetImageGenerator.copyCGImage` 对出发 MP4 抽帧报 `Cannot Decode (-11821 / -12911)`。
  - `AVAssetExportSession` 临时导出同一 MP4 报 `-12122`。
- 结论：
  - 当前出发 MP4 对 AVFoundation 的首帧抽取/导出兼容性较差，不能继续依赖同步预览图来遮盖首帧。

处理：

- `TripPet/Features/Cabin/DepartureCardTransitionOverlay.swift`
  - 前台 `DepartureTransitionVideoView` 不再做可见 preroll 等待。
  - 不再生成或显示 `videoPreviewImage`，避免预览图失败/晚到时与视频层切换导致闪烁。
  - 视频在遮罩和卡片入场阶段即隐藏播放。
  - 新增 `minimumPlaybackTimeBeforeReveal`，等 `AVPlayerLayer.isReadyForDisplay` 且播放时间至少推进到约 `0.12s` 后，再淡入视频层。
  - 保留后台 preloader 的 asset warm 和安全 preroll，但其失败不会阻塞前台播放。

验证：

- `CabinViewModelTests`：`TEST SUCCEEDED`。
  - 最新结果：`/Users/qianyu/Documents/Trip/DerivedDataCodex/Logs/Test/Test-TripPet-2026.06.29_22-14-28-+0800.xcresult`
- 真机 Debug build：`BUILD SUCCEEDED`。
  - DerivedData：`/Users/qianyu/Documents/Trip/BuildArtifacts/DerivedData-1.0.8-longtest-device`
- 真机安装：
  - `com.qianyu.TripPet`
  - 安装时间：2026-06-29 22:18 左右。
- 真机人工验收：
  - 用户确认：“没问题，这个版本顺畅了”。

### 工作区整理

- `.gitignore`
  - 新增 `DerivedDataCodex/`，避免本地测试缓存污染 `git status`。
- 已清理本地 `DerivedDataCodex/` 后重新运行测试；该目录由 Xcode 重建，但现在被 git 忽略。
- 当前没有提交 commit，没有 push，没有上传，也没有创建 PR。

## 2026-06-30 地图倒计时与 App Icon 接入打包

### 本次继续不处理

- 「重做穷人乍富旅行勋章」：继续保持排除，不重做、不替换正式勋章资源。
- 「补充 iCloud 存储逻辑」：继续保持排除，不改持久化/同步架构。

### 本次新增纳入

- 地图旅行倒计时：
  - `TripPet/Features/Map/WorldMapView.swift`
  - 目的地动物头像可点击，弹出回家倒计时 sheet。
  - 保留本地已有地图行为：`isActive`、小屋居中、`rendersContinuously = false`、非激活禁用交互、无飞机标记、路线弱化样式。
  - 倒计时格式覆盖「即将到达 / 分钟 / 小时分钟 / 天小时」。
- App Icon 接入：
  - `TripPet/Resources/ArtSourceRaster/AppIcon/`
    - `bulv_house_app_icon_1024.png`
    - `bulv_house_app_icon_1024.imagegen.json`
    - `ig_0e40b5552836fbb5016a4222bf96a08191bfcac7b2a7deed28.raw.png`
    - `ig_0e40b5552836fbb5016a4222bf96a08191bfcac7b2a7deed28.imagegen.json`
  - `TripPet/Resources/Assets.xcassets/AppIcon.appiconset/`
    - 生成 iPhone/App Store 所需 app-facing PNG 尺寸。
  - `TripPet.xcodeproj/project.pbxproj`
    - App target Debug/Release 设置 `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`。

### 验证与打包

- 聚焦测试：
  - `xcodebuild test -project TripPet.xcodeproj -scheme TripPet -destination 'platform=iOS Simulator,id=0F39C893-4E39-4C55-BEA7-9F0D221D664D' -derivedDataPath DerivedDataCodex -only-testing:TripPetTests/RootTabViewTests`
  - 结果：`TEST SUCCEEDED`，37 个 `RootTabViewTests` 通过。
  - 测试结果：`/Users/qianyu/Documents/Trip/DerivedDataCodex/Logs/Test/Test-TripPet-2026.06.29_22-40-48-+0800.xcresult`
- App Icon 文件校验：
  - 最终源图：`1024x1024`，无 alpha。
  - raw 图：`1254x1254`，无 alpha。
  - raw sha256：`fe4f26dc0d1d11d0b04a55cea3e32c2ceb2870026e24fce93eaef4079d4e268d`。
  - 构建产物 `Info.plist` 包含 `CFBundleIconName = AppIcon`。
  - 构建产物包含 `AppIcon60x60@2x.png` 和 `Assets.car`。
- 本次打包构建命令：
  - `xcodebuild build -project TripPet.xcodeproj -scheme TripPet -configuration Debug -destination 'id=0F39C893-4E39-4C55-BEA7-9F0D221D664D' -derivedDataPath BuildArtifacts/DerivedData-1.0.8-map-countdown-appicon-package`
  - 结果：`BUILD SUCCEEDED`。
- 最终 app：
  - Bundle id：`com.qianyu.TripPet`
  - Version：`1.0.8`
  - Build：`1`
  - App size：`230M`
- 最终模拟器 Debug 包：
  - `/Users/qianyu/Documents/Trip/BuildArtifacts/TripPet-1.0.8-map-countdown-appicon-20260630-0743-simulator-debug.app.zip`
  - Size：`215M`
  - SHA-256：`44ae99bfa219a71a7339c5d92a3d37e21f86e464e43f5594cd37f1f4f563417d`
- 模拟器安装启动验证：
  - 已安装本次构建产物到 `0F39C893-4E39-4C55-BEA7-9F0D221D664D`。
  - 已成功启动 `com.qianyu.TripPet`，进程号 `28116`。
  - 启动截图：`/Users/qianyu/Documents/Trip/BuildArtifacts/TripPet-1.0.8-map-countdown-appicon-20260630-0743-launch.png`。
- 当前没有提交 commit，没有 push，没有上传，也没有创建 PR。

## 2026-06-28 今日项目改动汇总

### 工作区状态

- `git log --since='2026-06-28 00:00'`：当前主工作区没有今天的本地 commit；今日汇总按未提交工作区状态整理。
- tracked diff：`126 files changed, 1985 insertions(+), 998 deletions(-)`。
- `git status --untracked-files=all` 展开后约 5323 行，其中 `DerivedDataCodex/` 是主要噪声；排除 `DerivedDataCodex/`、Xcode UI 状态和 `BuildArtifacts/` 后，仍约 1073 条本地文件状态。
- `TripPet_1.0.8_Local_Consolidation_Summary.md` 本身仍是本地未跟踪文档。
- 本轮只更新本文档；源码、资源、测试文件均未在本轮被修改。

### 已接入：成就系统骨架与成就页

代码与模型：

- `TripPet/Domain/Models/Achievement.swift`
  - 新增 `AchievementCategory`：旅行、脚步、明信片。
  - 新增 `AchievementTier`、`AchievementMedalProgress`、`AchievementAnimalProgress`、`AchievementSummary`。
  - 勋章状态分为 `collected`、`inProgress`、`locked`。

- `TripPet/Domain/Services/AchievementEngine.swift`
  - 旅行勋章 6 档：`1 / 10 / 20 / 30 / 50 / 100`。
  - 脚步勋章 14 档：`3000` 到 `1,000,000`。
  - 明信片勋章 9 档：`1` 到 `1000`。
  - 旅行与明信片采用分段进度，脚步采用累计进度。
  - 脚步成就按 `Ticket.animalId` 归属；旧票据没有 `animalId` 时，通过与出发时间匹配的 `Trip` 回推动物。
  - 明信片成就通过 `Postcard.tripId` 关联 `Trip.animalId`。

- `TripPet/Features/Achievements/TravelAchievementWallView.swift`
  - 新增 App 内成就墙页面。
  - 支持动物左右翻页、旅行/脚步/明信片分段切换、两列勋章网格。
  - 使用 `achievement_wall_album_background` 背景和每只动物的 home art。
  - 左右箭头沿用 `map_scroll_arrow_left/right`。

- `TripPet/App/RootTabView.swift`
  - 底部 tab 顺序改为：`小屋 / 成就 / 邮箱 / 地球`。
  - 新增 `.achievements` tab，并接入 `AchievementWallView()`。
  - tab bar 最大宽度从 `252` 调整到 `328` 以容纳四个 tab。

- `TripPet/App/PostcardNotificationService.swift`
  - `AppTab` 新增 `.achievements`。
  - 通知响应改为 `await MainActor.run`，便于测试确认路由请求在返回前已写入。

数据持久化：

- `TripPet/Domain/Models/Ticket.swift`
  - `Ticket` 新增 `animalId: String?`。
- `TripPet/Data/Persistence/UserStatePersistence.swift`
  - `PersistedTicket` 同步保存/恢复 `animalId`。
- `TripPet/Data/Repositories/AppRepository.swift`
  - 赠票时把当前出发动物写入 `Ticket.animalId`，供脚步成就按动物归属。

### 已接入：成就美术资源

资源规模：

- `TripPet/Resources/Assets.xcassets/Achievements/`
  - 30 个 app-facing imageset：29 个勋章 + 1 个背景。
- `TripPet/Resources/ArtSourceRaster/Achievements/`
  - 30 个 `.source.png`。
  - `raw/` 下 30 个 `.raw.png`、30 个 `.imagegen.json`、26 个 `.alpha.png`。
  - 当前目录大小约 `137M`；app-facing achievement assets 约 `25M`。

资源规则：

- `TripPet/Resources/ArtSourceRaster/Achievements/README.md` 记录：勋章必须是生成式 raster art，有 raw PNG provenance；app-facing PNG 是透明 `768x768`，不烘焙文字、数字、阈值或中文 copy。
- `AchievementEngine` 中每个 tier 都绑定正式 `achievement_medal_*` asset name。
- 这些资源已经放入 `Assets.xcassets` 并由 `TravelAchievementWallView` 使用。

待验收边界：

- 本轮只是整理记录，没有重新生成或替换美术。
- 提交前仍建议按 art guardrail 做 raw/source/xcassets/bundle/runtime screenshot 四段确认，尤其是成就页背景和 29 枚勋章在真机/模拟器 UI 中的尺寸、透明边缘与锁定态可读性。

### 已接入：邮箱蝴蝶动效

代码：

- `TripPet/Features/Mailbox/MailboxView.swift`
  - 新增 `MailboxPerchedButterfly`、`MailboxButterflyFrameAnimation`、`MailboxButterflyAnimationCatalog`。
  - 通过 `TimelineView(.animation(minimumInterval: 1.0 / 8))` 播放逐帧 PNG。
  - `reduceMotion` 时固定使用第一帧。
  - 根据未读/空邮箱背景的设计尺寸和归一化 perch point 计算蝴蝶停靠位置。
  - 蝴蝶只做视觉装饰，`allowsHitTesting(false)`，邮箱点击区域仍由 hotspot 按钮负责。

资源：

- `TripPet/Resources/ButterflyMailboxAnimation/`
  - `frames/` 下 48 帧 `butterfly_mailbox_0001.png` 到 `butterfly_mailbox_0048.png`。
  - `manifest.json` 记录：8fps、184x240、透明背景、首帧 sha256 `b70f5a929b6579c6cb5e28ac8ceedb660e7d6b5dc2b2d83bfb920d8bb56d40d6`。
- `TripPet.xcodeproj/project.pbxproj`
  - 新增 `ButterflyMailboxAnimation in Resources`，确保逐帧资源进入 bundle。
- `TripPet/Resources/ArtSourceRaster/Decorations/butterfly_mailbox_cutout_sources/`
  - 保留 48 帧 cutout source 和 manifest。
- `TripPet/Resources/ArtSourceRaster/Decorations/butterfly_animation_processed/`
  - 仍有 291 个处理产物，属于素材处理历史，不是当前 App 逐帧播放目录。

本地视觉证据：

- `BuildArtifacts/mailbox_butterfly_color_fixed.png`
- `BuildArtifacts/mailbox_butterfly_initial.png`
- `BuildArtifacts/mailbox_butterfly_after.png`
- `BuildArtifacts/mailbox_butterfly_after_2.png`
- `BuildArtifacts/mailbox_butterfly_opaque_check_0.png`
- `BuildArtifacts/mailbox_butterfly_opaque_repositioned.png`
- `BuildArtifacts/mailbox_butterfly_perch_debug.png`
- `BuildArtifacts/mailbox_butterfly_smaller_repositioned.png`
- `BuildArtifacts/mailbox_butterfly_on_top_red_circle.png`
- `BuildArtifacts/mailbox_perch_debug_iphone17pro.png`
- `BuildArtifacts/mailbox_perch_debug_iphone17e.png`
- `BuildArtifacts/mailbox_perch_debug_iphone17e_after_click.png`

这些是本地 QA 截图/对照图，不是正式资源目录。

### 已调整：小屋出发转场与刷新时序

- `TripPet/Features/Cabin/CabinView.swift`
  - 新增 `CabinSceneAnimalDisplayPolicy` 与 `heldCabinAnimalsDuringDeparture`。
  - 用户确认赠票时先暂存当前小屋动物列表；转场遮盖 ready 后再释放刷新，避免动物在遮罩出现前从小屋里瞬间消失。
  - 确认出发前调用 `DepartureTransitionPlaybackPreloader.shared.preloadVideo(for:)`。
  - 赠票确认卡去掉目的地小字，只保留动物名和头像，卡片高度从 `100` 调整到 `86`。

- `TripPet/Features/Cabin/DepartureCardTransitionOverlay.swift`
  - 遮罩 opacity 从 `0.52` 调整到 `0.42`，视觉更轻。
  - 新增 `onCoverReady` 回调，用于释放小屋刷新 hold。
  - 新增 `DepartureTransitionPlaybackPreloader`，提前 warm `AVURLAsset`、生成 preview image。
  - `DepartureTransitionVideoView` 支持 prepared asset、preroll、播放失败 fallback。
  - `DepartureTransitionCatalog.expectedVideos` 暴露给测试验证资源存在、可播放、尺寸和帧率。

- `TripPet/Features/Cabin/CabinSceneView.swift`
  - 微调 `xiaolu_guinea_pig` 与 `bear_visitor` 的脚点位置，减轻中层动物落点偏低的问题。

### 已调整：Apple 健康步数读取与文案

- `TripPet/Domain/Services/HealthKitStepCountProvider.swift`
  - `statisticsStepCount` 与 `sampleStepCount` 不再把所有无数据场景都当成错误。
  - 新增 `HealthKitStepQueryResult.steps(Int) / .noData`。
  - strict statistics、overlap statistics、sample fallback 依次尝试；全部无数据时解析为 `0`。
  - 新增 `normalizedStepCount(_:)`：向下取整且不小于 0。
  - HealthKit `errorNoData` 映射为 `.noData`，其他错误仍视为读取失败。

- `TripPet/Features/Cabin/CabinViewModel.swift`
  - 新增 `shouldShowStepReadRetryCard`。
  - 新增 `StepCounterPresentation`：`.counter(Int)`、`.message(String)`、`.hidden`。
  - Health 已连接但暂未同步到步数时显示 `等待Apple健康同步数据`，不再展示 `0 步`。
  - 连续读取失败后显示“重试读取今日步数”，不再误导为重新连接 Health。

- `TripPet/Features/Cabin/CabinView.swift`
  - 主卡片根据 `StepCounterPresentation` 显示步数计数器、同步中信息或隐藏。
  - 主按钮文案根据重试读步/重新连接/赠票状态切换。

- `TripPet/Features/Onboarding/OnboardingViews.swift`
  - onboarding 中只有 `steps > 0` 才作为可展示步数。
  - 授权但没有正数步数时显示同步中，并允许进入小屋。

- `TripPet/Features/Settings/SettingsView.swift`
  - 设置页同样只展示正数步数；无错误时显示同步中，有错误时显示请求失败。

- `TripPet/DesignSystem/AppCopy.swift`
  - 新增 `stepSyncPending`、`healthSyncPending`、`retryStepReadButton`。
  - `stepReadFailed` 改为强调“Health 已连接，但暂时没有读到今天的脚步”。

### 已调整：旅行分配、地图与通知

- `TripPet/Data/Repositories/AppRepository.swift`
  - 新增目的地间距策略：活跃旅行目的地之间至少约 `12` 度角距离。
  - 等待愿望目的地若与其他活跃旅行重叠或过近，会在出发前重分配。
  - 若没有满足间距的候选目的地，则回退到离当前活跃目的地最远的可用目的地。

- `TripPet/Features/Map/WorldMapView.swift`
  - 地球默认中心改为小屋坐标：latitude `-20`、longitude `-150`。
  - 进入地球页时重置到小屋居中。
  - 动物目的地 marker 尺寸、描边和阴影做了轻量化调整。
  - 底部 tab 文案从“地图”改为“地球”。

- `TripPet/Resources/ArtSourceRaster/UI/raw/map_travel_count_sign.*`
  - `map_travel_count_sign` 有 raw PNG 与 imagegen provenance。
- `TripPet/Resources/Assets.xcassets/UI/map_travel_count_sign.imageset/map_travel_count_sign@3x.png`
  - app-facing 标牌资源已更新。

### 已整理：旧 app-facing 美术资产清理

工具与记录：

- `Tools/audit_unused_art_assets.py`
  - 新增保守型 asset 审计脚本：扫描 runtime 文本、manifest asset 字段、已知动态命名模式和 bundle 资源引用。
- `UnusedArtAssetsReview/`
  - 包含候选 CSV、quarantine manifest、restore report 和 README。
  - README 记录 2026-06-27 审阅结果：恢复 5 项，保留删除 28 项。

当前 git diff 中实际删除的 app-facing imageset 为 52 个：

- Animals：16 个
- Cabin：8 个
- Destinations：4 个
- Onboarding：13 个
- Postcards：10 个
- UI：1 个

注意：

- 当前删除集比 `UnusedArtAssetsReview/README.md` 中 2026-06-27 的“保留删除 28 项”更大；后续提交前需要确认 Animals/Cabin 这批删除是否都经过最终 UI 回归。
- `DerivedDataCodex/`、Xcode `UserInterfaceState.xcuserstate`、`.DS_Store`、`BuildArtifacts/` 不应作为正式项目改动提交。

### 测试与验证状态

已新增/更新的测试覆盖：

- `TripPetTests/AchievementEngineTests.swift`
  - 覆盖旅行、脚步、明信片三类成就进度。
  - 覆盖分段/累计进度、动物间隔离、旧票据动物归属回推、tier asset name。
- `TripPetTests/AppRepositoryTripTests.swift`
  - 覆盖 `Ticket.animalId` 写入。
  - 覆盖目的地过近时重分配、无足够间距时回退到最远目的地。
- `TripPetTests/CabinViewModelTests.swift`
  - 覆盖出发动画视频资源存在/可播放、尺寸和帧率上限。
  - 覆盖小屋动物在出发遮罩前保持显示。
  - 覆盖 Health no-data、读取失败重试、0 步同步文案、step counter 展示状态。
- `TripPetTests/RootTabViewTests.swift`
  - 覆盖四 tab 顺序。
  - 覆盖邮箱未读堆叠和详情关闭后的已读结算。
  - 覆盖通知路由、地球默认朝向。

本轮文档更新未重新运行 `xcodebuild test`；只做了 `git status`、`git diff`、资源数量和关键文件读取核对。提交或提测前建议至少跑：

- `xcodebuild test -project TripPet.xcodeproj -scheme TripPet -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' -only-testing:TripPetTests/AchievementEngineTests`
- `xcodebuild test -project TripPet.xcodeproj -scheme TripPet -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' -only-testing:TripPetTests/CabinViewModelTests`
- `xcodebuild test -project TripPet.xcodeproj -scheme TripPet -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' -only-testing:TripPetTests/RootTabViewTests`
- 成就页、邮箱页、地球页各跑一次模拟器截图验收。

### 下一步收束建议

- 先排除/清理不应提交的本地噪声：`DerivedDataCodex/`、Xcode UI state、`.DS_Store`、临时 `BuildArtifacts/`。
- 成就页美术与邮箱蝴蝶需要最终运行态截图确认，尤其是 transparent edge、锁定态可读性、不同设备上的定位。
- 52 个删除的旧 imageset 建议按页面回归清单复核一次，避免动态 asset name 漏判。
- 当前没有 commit，没有 push，没有上传，也没有创建 PR。

## 已收束：邮箱森林小屋体验

### 代码

- `TripPet/Features/Mailbox/MailboxView.swift`
  - 邮箱页从列表式信封视图改为全屏森林小屋场景。
  - 根据未读状态切换背景图：
    - `mailbox_forest_cabin_unread`
    - `mailbox_forest_cabin_empty`
  - 新增邮箱热点按钮、未读送达光效、明信片堆叠弹层。
  - 新增已读明信片收藏 sheet。
  - 详情页关闭后再结算已读状态，避免只点开邮箱场景就误标已读。

- `TripPet/Features/Mailbox/MailboxViewModel.swift`
  - 新增未读堆叠状态、当前索引、详情来源、待标记已读 postcard id。
  - 区分 unread stack 和 history 来源。
  - 只在 unread stack 的详情页 dismiss 后标记已读，并从堆叠中移除该明信片。

- `TripPetTests/RootTabViewTests.swift`
  - 新增 5 个 `MailboxViewModel` 行为测试：
    - 打开未读堆叠不标记已读。
    - 打开未读详情时仍不立即标记已读。
    - 未读详情关闭后标记已读。
    - 多张未读中读完一张后堆叠继续保留。
    - 收藏/历史详情关闭不影响未读明信片。

### 美术资源

- 源文件：
  - `TripPet/Resources/ArtSourceRaster/Mailbox/mailbox_forest_cabin_unread.png`
  - `TripPet/Resources/ArtSourceRaster/Mailbox/mailbox_forest_cabin_empty.png`
- 原始 imagegen handoff：
  - `TripPet/Resources/ArtSourceRaster/Mailbox/raw/mailbox_forest_cabin_unread.raw.png`
  - `TripPet/Resources/ArtSourceRaster/Mailbox/raw/mailbox_forest_cabin_unread.imagegen.json`
  - `TripPet/Resources/ArtSourceRaster/Mailbox/raw/mailbox_forest_cabin_empty.raw.png`
  - `TripPet/Resources/ArtSourceRaster/Mailbox/raw/mailbox_forest_cabin_empty.imagegen.json`
- App-facing asset catalog：
  - `TripPet/Resources/Assets.xcassets/Envelopes/mailbox_forest_cabin_unread.imageset/`
  - `TripPet/Resources/Assets.xcassets/Envelopes/mailbox_forest_cabin_empty.imageset/`

文件哈希确认 raw/source/xcassets 三处一致：

- `mailbox_forest_cabin_unread`: `0f974b2e14a46001e1fafbe53c5b6322c1fa816b60f19a9aaec13222491e7523`
- `mailbox_forest_cabin_empty`: `a44b70df046b547984b570e6089de28a1af5e3a230e5ae2bb3223fee5d0d159f`

### 邮箱视觉证据

- `tmp/mailbox-art-verification/mailbox_scene_runtime.png`
- `tmp/mailbox-art-verification/mailbox_scene_after_frame_fix.png`
- `tmp/mailbox-art-verification/mailbox_header_raised.png`

这些文件是本地视觉验收证据，未整理进正式资源目录。

## 已收束：蝴蝶装饰素材包

### 文件

- 处理脚本：
  - `Tools/extract_chroma_key_animation.py`
- 静态参考图与提示词：
  - `TripPet/Resources/ArtSourceRaster/Decorations/butterfly_travel_pet_style.png`
  - `TripPet/Resources/ArtSourceRaster/Decorations/butterfly_travel_pet_style.preview.png`
  - `TripPet/Resources/ArtSourceRaster/Decorations/butterfly_travel_pet_style.imagegen.json`
  - `TripPet/Resources/ArtSourceRaster/Decorations/butterfly_video_generation_prompt.md`
- 动画处理产物：
  - `TripPet/Resources/ArtSourceRaster/Decorations/butterfly_animation_processed/`

### 当前状态

- `butterfly_animation_processed` 当前包含 291 个文件。
- 整个 `Decorations` 目录当前约 587 个文件、415 MB。
- 这些蝴蝶素材目前未被 Swift 代码引用，也未放入 `Assets.xcassets` 或 Copy Bundle Resources。
- 因此它们当前状态是「素材包已生成/处理，待后续集成」，不是「已进入 App 可见 UI」。

## 仓库规则与本地工具

- `AGENTS.md`
  - 指向 `.codex/skills/project-guardrails/SKILL.md`。
- `.codex/skills/project-guardrails/`
  - 本仓库强制 guardrail。
- `.codex/skills/art-asset-integration-guard/`
  - TripPet 可见美术资源生成、接入、验收 guardrail。

这些文件是本地协作规则与验收工具，不属于具体功能 UI。

## 暂不触碰：勋章/成就任务边界

以下文件看起来属于仍在执行中的「规范勋章美术并修复箭头」或其上下文，按要求本次未做改动：

- `TripPet_1.0.8_Achievement_Wall_Task_Context_Summary.md`
- `TripPet_1.0.8_Achievements_Context_Summary.md`
- `TripPet_1.0.8_Full_Context_And_New_Plan.md`
- `TripPet_1.0.8_Medal_Formal_Art_Context_Summary.md`
- `achievement-wireframe.html`
- `TripPet/Resources/ArtSourceRaster/GeneratedRaw/ig_01030765327c34db016a3e41edea508191b5c1962d2376cadb.*`
- `TripPet/Resources/ArtSourceRaster/GeneratedRaw/ig_01030765327c34db016a3e427ae4a88191a3d35a3716b8bbe8.*`

## 验证记录

- `python3 .codex/skills/art-asset-integration-guard/scripts/verify_asset_files.py --project-root . --require-provenance --no-require-alpha --asset mailbox_forest_cabin_unread --asset mailbox_forest_cabin_empty`
  - 结果：通过。
  - 说明：邮箱背景是全屏背景图，不要求 alpha。

- `shasum -a 256` 对邮箱 raw/source/xcassets 文件做一致性确认。
  - 结果：同一邮箱状态的三处 PNG 哈希一致。

- `xcodebuild -list -project TripPet.xcodeproj`
  - 结果：成功，scheme 为 `TripPet`。

- `xcodebuild test -project TripPet.xcodeproj -scheme TripPet -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' -only-testing:TripPetTests/RootTabViewTests`
  - 结果：`TEST SUCCEEDED`。
  - 产物：`/Users/edy/Library/Developer/Xcode/DerivedData/TripPet-dopfwupqejeuqhheojdqwgobzhox/Logs/Test/Test-TripPet-2026.06.26_18-21-45-+0800.xcresult`

- `swift test`
  - 结果：不适用于本仓库根目录。
  - 原因：仓库根目录没有 `Package.swift`，本项目使用 `TripPet.xcodeproj`。

## 当前工作区状态说明

- 本次没有提交 commit。
- 本次没有 push、上传、创建 PR。
- 当前仍有未暂存/未提交改动，主要分为：
  - 邮箱森林小屋体验代码与正式资源。
  - 蝴蝶装饰素材包和处理脚本。
  - guardrail/AGENTS 本地协作规则。
  - 勋章/成就任务相关上下文与 raw 资源，保持原样。
