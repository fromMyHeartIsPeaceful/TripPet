# 步旅小屋 MVP 页面与验收清单

更新时间：2026-06-07

## 任务29：真机 HealthKit 验证矩阵

当前代码基础：
- `TripPet/TripPet.entitlements` 已启用 `com.apple.developer.healthkit`。
- `TripPet.xcodeproj/project.pbxproj` 已配置 `NSHealthShareUsageDescription`。
- App 只请求读取 `.stepCount`，不写入健康数据。

2026-06-07 真机连接尝试：
- `devicectl list devices` 可看到真机 `qianyu`，设备 ID `BC67627A-9384-5020-AD2D-51F02D4E8C2C`，型号 `iPhone 15 Pro Max`，状态 `connected`。
- 第二次使用 Team ID `ZNY52MWKJN` + `-allowProvisioningUpdates` 构建成功。
- Xcode 自动生成/使用 `iOS Team Provisioning Profile: com.qianyu.TripPet`，UUID `34a5e200-dc04-4f42-ab6a-c93ba77ec6af`。
- 签名 entitlements 包含 `application-identifier = ZNY52MWKJN.com.qianyu.TripPet` 和 `com.apple.developer.healthkit = true`。
- `devicectl device install app` 已安装成功，Bundle ID 为 `com.qianyu.TripPet`。
- 18:44、18:47、18:59 和 19:16 安装成功；最新包已包含 HealthKit 只读权限判断修复、不足步数实际读数提示、小屋赠送按钮反馈修复，以及 BuBuGarden 风格的刷新链路。
- 18:59 `devicectl device process launch` 已启动成功；19:16 最新安装后远程启动被 iOS 判定 `Locked` 拒绝，需要手动打开 App。
- 已修正 HealthKit 读权限判断：App 只读 `.stepCount` 时，`HKHealthStore.authorizationStatus(for:)` 不能作为读取权限成功的唯一依据；授权请求成功后进入 `readPermissionRequested` 状态，并直接尝试读取今日步数。
- 已修正点击“赠送今日脚步，让它出发”看似无反应的问题：`readPermissionRequested` 状态刷新不再覆盖刚读到的步数/错误/旅途中提示。
- 已吸收 BuBuGarden Health 逻辑：授权成功后立即读今日步数；App 启动、回前台、小屋出现、设置页打开会刷新；HealthKit observer 会在步数样本变化后触发刷新；Provider 使用明确错误和 `max(0, Int(steps.rounded(.down)))`。
- HealthKit 授权弹窗、授权后今日步数读取仍需用户在真机上点击确认并观察 UI。

真机验证记录：

| 状态 | 验证路径 | 期望结果 | 当前记录 |
| --- | --- | --- | --- |
| notDetermined | 全新安装后进入 `HealthConnectView` | 点击连接时出现 Health 权限弹窗 | 待人工验证 |
| readPermissionRequested / sharingAuthorized | 在弹窗中允许步数读取，或重新点击连接/更新权限 | `HealthConnectView` 进入小屋；连接成功后立即显示今日读取步数；赠送流程能读取今日步数，低于门槛时显示实际读取步数 | 19:16 最新包已安装，待人工验证 |
| sharingDenied | 在弹窗中拒绝，或系统设置关闭步数读取 | 引导页/小屋/设置页显示未开启提示；仍可“稍后再说”进入小屋 | 待人工验证 |
| unavailable | 无 Health 数据能力环境 | 连接按钮不可用或显示不可读取；仍可进入小屋浏览 | 待人工验证 |
| 设置页重新请求 | 小屋设置 -> Apple 健康 -> 连接或更新权限 | 状态文案刷新，不显示技术错误 | 待人工验证 |

记录时补充：
- 设备型号：
- iOS 版本：
- Apple Health 今日步数：
- App 读取步数：
- 授权弹窗是否出现：
- 是否有 Xcode `notification_proxy` 外部设备噪声：

## 任务32/34：页面对照清单

| MVP 页面 | SwiftUI 实现 | 入口 | 数据来源 | 资源依赖 | 空/异常状态 | 原型覆盖结论 |
| --- | --- | --- | --- | --- | --- | --- |
| 欢迎页 | `OnboardingView` | 首次启动，`onboardingCompleted == false` | `AppRepository.userFlags` | `onboarding_cabin_path`, `onboarding_cat_suitcase` | 无数据依赖 | 覆盖原型启动介绍，已替换为水彩视觉 |
| Health 连接页 | `HealthConnectView` | 欢迎完成后，`healthGuideDismissed == false` | `StepCountProvider.authorizationStatus()` | `health_steps_ticket`, `icon_health` | 不可用、未授权、拒绝、请求失败 | 覆盖原型权限引导；真机授权待验证 |
| 小屋页 | `CabinView`, `CabinSceneView` | Tab `小屋` | `AppRepository`, `StepCountProvider`, `TicketRuleEngine`, `AnimalVisitService` | cabin、animal、ticket、map、icon 资源 | Health 未连接、步数不足、今日已赠送、activeTrip | 覆盖原型主界面，保留两 Tab MVP |
| 赠送确认弹层 | `TicketGiftConfirmationView` | 小屋页读取步数且规则通过后 | `CabinViewModel.pendingGiftConfirmation` | `ticket_confirm_card`, `prop_ticket_single`, icons | 取消、确认中 | 原型无独立页；符合 MVP 补充流程 |
| 旅途中状态卡 | `TripStatusCard` | 有 `activeTrip` 时显示在小屋页 | `Trip`, manifest destinations | `trip_route_map_*`, `trip_marker_cat`, `prop_paper_plane` | route map fallback 到巴黎资源 | 覆盖旅行中状态，第一版只显示一张状态卡 |
| 邮箱页 | `MailboxView` | Tab `邮箱` | `AppRepository.postcards` | `mailbox_tray_base`, `envelope_*`, stamps | 邮箱空状态 | 覆盖原型邮箱列表，信封文字由 SwiftUI 渲染 |
| 明信片详情页 | `PostcardDetailView` | 邮箱点击信封，全屏覆盖 | `Postcard` | `postcard_template_classic`, destination, stamp, animal | 资源缺失由 `ArtImage` fallback | 覆盖原型详情页，底部 Tab 被遮住 |
| 设置页 | `SettingsView` | 小屋页设置按钮 sheet | `StepCountProvider`, `AppRepository` | settings icons | Health 状态刷新/请求失败 | 原型设置入口已覆盖 |
| 通知设置页 | `NotificationSettingsPage` | 设置页 NavigationLink | 本地 toggle UI | `settings_notification_note` | 暂无系统通知能力 | MVP 仅记录偏好，不调度通知 |
| 明信片收藏页 | `CollectionSettingsPage` | 设置页 NavigationLink | 已读 postcards | `settings_collection_empty`, stamps | 收藏为空 | 覆盖收藏入口；第一版按已读明信片展示 |
| 关于页 | `AboutSettingsPage` | 设置页 NavigationLink | 静态文案 | `settings_about_cabin` | 无 | 覆盖关于说明 |

原型有但 MVP 暂不做：
- 多层级目的地选择。
- 多天旅行多张明信片。
- 真实系统通知调度。
- matchedGeometryEffect 高级信封展开转场。
- 新伙伴点击、解锁、寄明信片。

## 任务30：可访问性人工检查

待人工检查：
- VoiceOver 跑通欢迎页、Health 连接页、小屋页、赠送确认、邮箱、明信片详情、设置二级页。
- Dynamic Type 下主要按钮、卡片、明信片正文不溢出。
- Reduce Motion 下小屋呼吸、机票浮动、赠送飞行动效被关闭或降低。
- 颜色对比度满足主要文本阅读。
- 装饰图默认隐藏，关键插画和操作按钮有 label。

## 任务31：包体积与资源检查

最终版待执行：
- Release 构建后记录 `Assets.car` 和 `TripPet.app` 体积。
- 执行 manifest 资源引用检查。
- 检查未使用资源，但不删除当前 MVP 必需资源。

## 任务40：最终集成验收

自动命令：

```bash
plutil -lint TripPet.xcodeproj/project.pbxproj
python3 -m json.tool TripPet/Resources/ContentManifest.json
node -e "const fs=require('fs'); const manifest=JSON.parse(fs.readFileSync('TripPet/Resources/ContentManifest.json','utf8')); const assets=new Set(fs.readdirSync('TripPet/Resources/Assets.xcassets',{recursive:true}).filter(p=>p.endsWith('.imageset')).map(p=>p.split('/').pop().replace(/\\.imageset$/,''))); const names=[]; for(const a of manifest.animals) names.push(a.homeAssetName,a.selfieAssetName,a.visitorAssetName); for(const d of manifest.destinations) names.push(d.landmarkAssetName,d.stampAssetName,d.routeMapAssetName); for(const p of manifest.postcards) names.push(p.templateAssetName,p.destinationAssetName,p.stampAssetName,p.animalAssetName,p.envelopeAssetName); const missing=[...new Set(names)].filter(n=>!assets.has(n)); if(missing.length){ console.error('Missing assets:', missing.join(', ')); process.exit(1); } console.log([...new Set(names)].length+' manifest asset names all exist');"
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project TripPet.xcodeproj -scheme TripPet -configuration Debug -sdk iphoneos -derivedDataPath .derivedData CODE_SIGNING_ALLOWED=NO build
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project TripPet.xcodeproj -scheme TripPet -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .derivedData CODE_SIGNING_ALLOWED=NO
```
