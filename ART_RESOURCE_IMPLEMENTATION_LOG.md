# 步旅小屋未完成美术方向实施记录

生成时间：2026-06-07

本文记录本轮按任务编号推进的美术资源实现结果。范围只包括资源、资源命名、内容清单和验收记录，不处理 Root 启动流、HealthKit、SwiftData 或旅行规则代码。

## ART_REMAKE_TASKS 任务1-6：首批水彩 PNG 重做

已建立正式 raster 源文件目录：

- `TripPet/Resources/ArtSourceRaster/`
- `TripPet/Resources/ArtSourceRaster/Animals/`
- `TripPet/Resources/ArtSourceRaster/Cabin/`
- `TripPet/Resources/ArtSourceRaster/Envelopes/`
- `TripPet/Resources/ArtSourceRaster/Postcards/`
- `TripPet/Resources/ArtSourceRaster/Destinations/`
- `TripPet/Resources/ArtSourceRaster/Stamps/`
- `TripPet/Resources/ArtSourceRaster/Textures/`

已补 README 模板：

- 根目录 README 记录导出规则、源文件和 asset catalog 的关系。
- 各资源类别 README 记录尺寸建议、透明背景规则和用途约束。

已重做并接入 PNG：

- `animal_cat_home`：更可爱的小猫首页主形象，透明背景。
- `animal_cat_selfie`：同一只小猫的半身自拍，透明背景。
- `animal_visitor_unknown`：门边探头的神秘来访伙伴，透明背景。
- `cabin_room_base`：温暖小屋室内主场景，不含小猫和业务文字。
- `prop_map_table`：小木桌、手绘地图、铅笔和便签，透明背景。

接入结果：

- PNG 源文件保存在 `TripPet/Resources/ArtSourceRaster/Animals/` 和 `TripPet/Resources/ArtSourceRaster/Cabin/`。
- Chroma-key 生成源图保存在 `TripPet/Resources/ArtSourceRaster/GeneratedKey/`。
- App 正式资源已复制到对应 `Assets.xcassets/Animals/*.imageset/` 和 `Assets.xcassets/Cabin/*.imageset/`。
- 五个 `Contents.json` 已改为 universal `3x` PNG，不再启用 `preserves-vector-representation`。
- 旧 SVG 暂保留在各 `.imageset` 目录内但不再被 catalog 引用，后续任务 18 统一清理或迁移。

## 任务10：欢迎页与首次进入流程美术

已补资源：

- `onboarding_cabin_path`：小屋外景、小路和远方天空。
- `onboarding_cat_suitcase`：带行李箱的小猫。

接入约束：

- 欢迎页标题、说明和按钮文字必须继续由 SwiftUI 渲染。
- 资源不包含任何固定文案。

## 任务11：Health 连接页美术

已补资源：

- `health_steps_ticket`：心形健康状态、脚步路径和机票连接插画。

接入约束：

- 用于 Health 授权引导页或未连接说明页。
- 不做步数仪表盘、进度环或健身工具视觉。

## 任务13：赠送确认弹层美术

已补资源：

- `ticket_confirm_card`：确认赠送用的纸质机票卡片底图。

接入约束：

- 只作为弹层视觉底图或装饰层。
- 小动物、目的地、票数、步数和按钮仍由 SwiftUI 渲染。

## 任务25：小屋页动效美术准备

资源结论：

- 当前 `animal_cat_home` 足够支持 SwiftUI 呼吸、轻微浮动、按钮下沉等第一版动效。
- 本轮不补 `cat_eye_open` / `cat_eye_closed`，避免在规则和动效实现未确定前增加分层维护成本。

## 任务26：信封与明信片转场动效美术准备

资源结论：

- 当前 `envelope_unread`、`envelope_read`、`envelope_old`、`postcard_template_classic` 足够支持 matchedGeometryEffect、opacity、scale 转场。
- 本轮不补转场帧，不引入 Lottie。

## 任务27：赠送成功动效美术准备

已补资源：

- `ticket_flight_trail`：纸飞机飞行轨迹和轻量光点。

复用资源：

- `prop_paper_plane`
- `animal_cat_home`

接入约束：

- 第一版动效用 SwiftUI 原生动画。
- Reduce Motion 下应关闭或降低飞行轨迹与浮动效果。

## 任务36：目的地内容第一批

已补资源：

- `trip_route_map_iceland`：冰岛专用旅行路线图。

已更新内容清单：

- `ContentManifest.json` 中冰岛 `routeMapAssetName` 从 `trip_route_map_paris` 改为 `trip_route_map_iceland`。

暂不新增：

- 邮戳变体。
- 更多明信片图层。

原因：

- 巴黎和冰岛已有地标、邮戳和明信片模板；MVP 当前只缺冰岛路线图来避免目的地资源复用错位。

## 任务37：新伙伴出现规则美术

已补最小伙伴资源包：

- `animal_dog_home`
- `animal_dog_visitor`
- `animal_rabbit_home`
- `animal_rabbit_visitor`

已更新内容清单：

- `ContentManifest.json` 新增 `dog` 和 `rabbit` 非 resident 动物条目。
- `SeedData.preview` 同步新增 fallback 动物，并修正旧的 `animal_visitor_selfie` 缺失资源名。

暂不新增：

- 新伙伴自拍资源。
- 新伙伴明信片专属姿势。

原因：

- 新伙伴规则尚未最终确定，当前只保证小屋/来访视觉可用。

## 任务38：旅行与明信片时间规则美术

当前 MVP 资源矩阵：

| 状态 | 当前资源 | 本轮结论 |
| --- | --- | --- |
| 准备赠送 | `prop_ticket_single` | 已满足 |
| 确认赠送 | `ticket_confirm_card` | 本轮补齐 |
| 出发反馈 | `prop_paper_plane`, `ticket_flight_trail` | 本轮补齐 |
| 巴黎旅途中 | `trip_route_map_paris`, `trip_marker_cat` | 已满足 |
| 冰岛旅途中 | `trip_route_map_iceland`, `trip_marker_cat` | 本轮补齐 |
| 未读来信 | `envelope_unread` | 已满足 |
| 已读来信 | `envelope_read` | 已满足 |
| 旧明信片 | `envelope_old` | 已满足 |
| 明信片详情 | `postcard_template_classic`, destination line, stamp, animal selfie | 已满足 |

暂不新增：

- 多天旅行专属帧。
- 每日投递状态图。
- 多张明信片不同模板。

原因：

- 时间规则尚未定稿，先不抢代码规则或内容结构。

## 任务39：设置二级页美术

已补资源：

- `settings_notification_note`：通知设置二级页插图。
- `settings_collection_empty`：明信片收藏空状态插图。
- `settings_about_cabin`：关于页插图。

接入约束：

- Toggle 第一版建议继续 SwiftUI 自绘，不使用固定图片开关。
- 二级页文字继续由 SwiftUI 渲染。

## 任务31：包体积与资源压缩

构建后记录：

- `Assets.car`：1,629,000 bytes，约 1.55 MiB。
- `TripPet.app` Debug iphoneos 产物：3,760 KiB。
- `ArtSource` SVG 源文件目录：168 KiB。
- `Assets.xcassets` 源目录：388 KiB。
- 首屏核心 SVG 源资源合计约 15,207 bytes，约 14.9 KiB：`cabin_room_base`、`animal_cat_home`、`animal_visitor_unknown`、`prop_map_table`、`prop_ticket_single`、`texture_paper_grain`。
- 巴黎单目的地 SVG 源资源合计约 8,068 bytes，约 7.9 KiB：`destination_paris_line`、`trip_route_map_paris`、`stamp_paris`。
- 冰岛单目的地 SVG 源资源合计约 8,189 bytes，约 8.0 KiB：`destination_iceland_line`、`trip_route_map_iceland`、`stamp_iceland`。

当前处理：

- 新增资源均为 SVG vector asset，保留源文件在 `ArtSource`，asset catalog 使用 preserves vector representation。
- 当前不需要裁剪源 SVG；如后续上架包体积收紧，优先评估 `Assets.car` 编译策略，而不是删除 MVP 资源。

## 任务40：最终资源集成验收

验收项：

- `ContentManifest.json` 中所有 asset name 应存在于 `Assets.xcassets`。
- `ArtSource` 与 `Assets.xcassets` 中新增资源应成对存在。
- 主要页面和后续欢迎/Health 页面接入时不应出现 ArtImage fallback。
- 所有业务文字继续由 SwiftUI 渲染，不能烘焙进图片。

## ART_REMAKE_TASKS 任务14：设置页水彩 PNG 重做

已重做并接入 PNG：

- `settings_notification_note`：铃铛、纸条、信封，用于通知设置页。
- `settings_collection_empty`：空手帐与未贴满的明信片位置，用于收藏空状态。
- `settings_about_cabin`：小屋、纸票、睡觉小猫，用于关于页。

接入结果：

- PNG 源文件保存在 `TripPet/Resources/ArtSourceRaster/Settings/`。
- App 正式资源已复制到对应 `Assets.xcassets/Settings/*.imageset/`。
- 三个 `Contents.json` 已改为 universal `3x` PNG，不再启用 `preserves-vector-representation`。
- 原设置页线框 SVG 已归档到 `TripPet/Resources/ArtSource/LegacyLineArt/Settings/`。

## ART_REMAKE_TASKS 任务15：UI 图标二次检查

检查范围：

- `icon_home`
- `icon_mail`
- `icon_settings`
- `icon_back`
- `icon_health`
- `icon_ticket`
- `icon_steps`
- `icon_notification`
- `icon_collection`
- `icon_about`

结论：

- 10 个 UI 图标均为 24 x 24 viewBox。
- 统一使用 `stroke-width="1.9"`、round cap、round join。
- Asset catalog 均保留 `template-rendering-intent`，适合 SwiftUI 按主题色渲染。
- 风格为简化手绘线条，可作为 UI 图标继续保留 SVG vector。
- 暂不重画为 PNG，避免底部 Tab 和设置列表在不同尺寸下模糊。

## ART_REMAKE_TASKS 任务16-18：资产替换、验收与旧资源清点

本轮已完成：

- 设置页三张插画从旧 SVG 正式替换为 PNG。
- 已有 `ArtSourceRaster` PNG 中的 5 张核心资源也已正式替换：`animal_cat_home`、`animal_cat_selfie`、`animal_visitor_unknown`、`cabin_room_base`、`prop_map_table`。
- 已经指向 `@3x` PNG 的其它插画资源也完成旧 SVG 清理归档：机票、目的地、信封、欢迎页、明信片、邮戳资源。
- 已替换资源的旧线框 SVG 均已移出正式 `.imageset` 并归档。
- 图标类 SVG 已判定可保留。

2026-06-07 续跑补齐：

- `animal_dog_home` 已替换为透明背景水彩 PNG。
- `animal_dog_visitor` 已替换为透明背景水彩 PNG。
- `animal_rabbit_home` 已替换为透明背景水彩 PNG。
- `animal_rabbit_visitor` 已替换为透明背景水彩 PNG。
- `trip_marker_cat` 已替换为透明背景水彩 PNG。
- `prop_paper_plane` 已替换为透明背景水彩 PNG。
- `texture_paper_grain` 已替换为纸张纹理 PNG。
- 以上 7 个资源的旧 SVG asset/source 已归档到 `TripPet/Resources/ArtSource/LegacyLineArt/`。

验收备注：

- 当前任务 14 范围的设置页资源已脱离线框 SVG。
- 小猫首页、小猫自拍、未知访客、小屋背景、地图桌已脱离线框 SVG。
- 狗、兔、旅途猫标记、纸飞机、纸张纹理也已脱离线框 SVG。
- Asset catalog 中已无插画类 SVG；剩余 SVG 仅为 UI 图标。

任务 17 视觉验收记录：

- `xcodebuild -project TripPet.xcodeproj -scheme TripPet -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath .derivedData build` 已通过。
- 欢迎页截图：`.derivedData/trippet-visual-check-home.png`。
- Health 连接页截图：`.derivedData/trippet-visual-check-health.png`。
- 小屋页截图：`.derivedData/trippet-visual-check-cabin.png`。
- 欢迎页、Health 页、小屋页均显示正式水彩 PNG，无明显线框占位感。
- 小屋页小猫、房间背景、地图桌和票据资源无明显模糊、裁切或拉伸。
- 设置二级页的三张 PNG 已完成资源级检查与构建检查；当前环境不允许 `osascript` 辅助访问 Simulator 窗口，未能自动点击进入设置二级页截图。
- 续跑后已用 Python 校验 7 个新 `Contents.json` 均指向存在的 `@3x.png`，且 6 个透明资源均为 RGBA。
- `find TripPet/Resources/Assets.xcassets -name '*.svg'` 只剩 `UI/` 图标 SVG。
- `xcodebuild -project TripPet.xcodeproj -scheme TripPet -configuration Debug -sdk iphoneos -derivedDataPath .derivedData CODE_SIGNING_ALLOWED=NO build` 已通过。
- `xcodebuild test -project TripPet.xcodeproj -scheme TripPet -destination 'platform=iOS Simulator,id=0F39C893-4E39-4C55-BEA7-9F0D221D664D' -derivedDataPath .derivedData CODE_SIGNING_ALLOWED=NO` 已通过。
- 真机构建/安装/启动已完成：使用 Team ID `ZNY52MWKJN` + `-allowProvisioningUpdates` 构建成功，使用 `iOS Team Provisioning Profile: com.qianyu.TripPet`，UUID `34a5e200-dc04-4f42-ab6a-c93ba77ec6af`。
- 签名 entitlements 已确认包含 `application-identifier = ZNY52MWKJN.com.qianyu.TripPet` 和 `com.apple.developer.healthkit = true`。
- `devicectl device install app --device BC67627A-9384-5020-AD2D-51F02D4E8C2C .derivedData/Build/Products/Debug-iphoneos/TripPet.app` 已安装成功。
- `devicectl device process launch --device BC67627A-9384-5020-AD2D-51F02D4E8C2C com.qianyu.TripPet` 已启动成功。

## ART_REMAKE_TASKS 任务7-13：票据、邮箱、明信片、目的地与欢迎页 PNG 重做

已重做并接入 PNG：

- 任务7 机票资源组：`prop_ticket_single`、`ticket_confirm_card`、`ticket_flight_trail`。
- 任务8 邮箱托盘：`mailbox_tray_base`。
- 任务9 信封状态：`envelope_unread`、`envelope_read`、`envelope_old`。
- 任务10 明信片模板：`postcard_template_classic`。
- 任务11 巴黎目的地：`destination_paris_line`、`stamp_paris`、`trip_route_map_paris`。
- 任务12 冰岛目的地：`destination_iceland_line`、`stamp_iceland`、`trip_route_map_iceland`。
- 任务13 欢迎与 Health：`onboarding_cabin_path`、`onboarding_cat_suitcase`、`health_steps_ticket`。

接入结果：

- PNG 源文件保存在 `TripPet/Resources/ArtSourceRaster/Cabin/`、`Postcards/`、`Envelopes/`、`Destinations/`、`Stamps/`、`Onboarding/`。
- 原始生成图保存在 `TripPet/Resources/ArtSourceRaster/GeneratedRaw/`。
- App 正式资源已复制到对应 `Assets.xcassets/**/*.imageset/`，文件名统一为 `asset_name@3x.png`。
- 17 个 `Contents.json` 已改为 universal `3x` PNG，不再启用 `preserves-vector-representation`。
- 需要分层叠放的资源已处理为透明 PNG：`prop_ticket_single`、`ticket_flight_trail`、`destination_paris_line`、`destination_iceland_line`、`stamp_paris`、`stamp_iceland`、`onboarding_cat_suitcase`。
- 纸张/列表/页面底图类资源保持不透明纸张背景，便于 SwiftUI 文本叠加和列表裁切。
- 对应旧线框 SVG 已移出正式 `.imageset`；既有旧源文件继续归档在 `TripPet/Resources/ArtSource/LegacyLineArt/`。

验收记录：

- 已生成本地总览图 `/private/tmp/trip_art_tasks_7_13_final_contact.png` 检查透明边缘、信封留白、巴黎/冰岛区分和欢迎页小猫设定。
- 已用 Python JSON 解析校验 `Assets.xcassets` 内 55 个 `Contents.json` 均可读。
- 已确认任务 7-13 的 17 个 PNG 非空且尺寸符合当前接入用途。
- `actool --print-asset-tag-combinations` 可完成，未再出现任务 7-13 旧 SVG 的 unassigned child 警告。
- 完整 `xcodebuild` 仍受本机 Xcode 环境影响失败，失败点为 `swift-plugin-server` / SwiftData / Preview 宏加载异常，不是 asset catalog 引用错误。
