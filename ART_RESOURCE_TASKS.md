# 步旅小屋美术资源任务清单

本文档用于连接美术设计、视觉规范与 iOS 技术实现。视觉方向以 [VISUAL_ART_SPEC.md](/Users/qianyu/Documents/Trip/VISUAL_ART_SPEC.md) 为准，技术上下文以 [TECHNICAL_CONTEXT.md](/Users/qianyu/Documents/Trip/TECHNICAL_CONTEXT.md) 为准。

## 1. 总体目标

下一步美术资源的目标不是一次性画完整插画库，而是先完成可接入当前 SwiftUI 工程的 MVP 资源包。

优先支持当前已实现页面：

- 小屋首页
- 邮箱列表
- 明信片详情
- 设置页
- Health 未连接状态
- 赠送脚步后创建旅行的状态反馈

资源生产原则：

- 优先满足真实 App 页面替换线框占位。
- 命名必须能直接放入 `Assets.xcassets`。
- 每个资源都要有明确使用页面和 SwiftUI 接入位置。
- 先做少量高复用资源，再扩展动物和目的地。
- 不按页面整图堆叠，尽量拆成可组合资源。

## 2. 资源接入方式

当前工程已创建：

```text
TripPet/Resources/Assets.xcassets
TripPet/Resources/ContentManifest.json
```

注意：

- 当前 `Assets.xcassets` 暂未加入 target Resources。
- 美术资源完成后，在正常 Xcode 环境中再加入 target。
- SwiftUI 中建议通过 `Image("asset_name")` 使用资源。
- `ContentManifest.json` 用于维护动物、目的地、明信片等内容配置，不建议把内容逻辑硬编码在 View 中。

推荐 asset catalog 分组：

```text
Assets.xcassets/
  Animals/
  Cabin/
  Destinations/
  Postcards/
  Stamps/
  Envelopes/
  UI/
  Textures/
```

## 3. 资源规格

### 3.1 格式

| 类型 | 推荐格式 | 说明 |
| --- | --- | --- |
| 水彩插画 | PNG / PDF vector fallback | 保留柔和边缘，适合动物、小屋、明信片 |
| 线性图标 | PDF vector | Xcode 中作为 single scale vector |
| 邮戳/简单线稿 | PDF vector 或 SVG 转 PDF | 便于缩放 |
| 纸张纹理 | PNG / WebP 源文件，App 内 PNG | 全局复用，低透明度 |
| 复杂动效 | Lottie JSON，暂缓 | 仅关键仪式感使用 |

iOS 工程首版建议使用：

- 插画：`PNG @3x`
- 图标：`PDF vector`
- 纹理：小尺寸可平铺 PNG

### 3.2 尺寸建议

| 资源 | 设计尺寸 | 导出建议 |
| --- | --- | --- |
| 小屋主场景 | 720 x 720 | PNG @3x，页面内按宽度适配 |
| 动物首页姿势 | 360 x 360 | PNG @3x，透明背景 |
| 动物自拍 | 420 x 420 | PNG @3x，透明背景 |
| 信封列表项装饰 | 640 x 220 | PNG @3x 或拆分为信封主体+邮票 |
| 明信片大图 | 900 x 620 | PNG @3x |
| 地标线稿 | 480 x 360 | PDF vector 或 PNG 透明背景 |
| 邮戳 | 180 x 180 | PDF vector |
| 底部 Tab 图标 | 24 x 24 | PDF vector |
| 设置图标 | 24 x 24 | PDF vector |
| 纸张纹理 | 512 x 512 | PNG，可平铺 |

### 3.3 透明背景

需要透明背景的资源：

- 小动物
- 来访伙伴
- 地标线稿
- 邮戳
- 邮票
- 图标
- 小道具

不需要透明背景的资源：

- 小屋主场景背景
- 明信片完整画面
- 纸张纹理

## 4. P0 资源：替换当前线框所必需

P0 目标：让当前 SwiftUI App 从线框占位进入可展示的真实视觉版本。

### 4.1 小屋首页

| 资源名 | 内容 | 用途 | 接入页面 |
| --- | --- | --- | --- |
| `cabin_room_base` | 小屋室内水彩背景，含墙面、地面、窗户基础结构 | 替换首页线框小屋区域 | `HomeView` / 小屋场景组件 |
| `animal_cat_home` | 小猫坐姿或站姿，适合放在小屋内 | 默认主角 | `HomeView` |
| `animal_visitor_unknown` | 随机来访伙伴剪影或问号伙伴 | 表示新伙伴随机出现 | `HomeView` |
| `prop_map_table` | 桌面地图和小桌子组合 | 小屋旅行氛围 | `HomeView` |
| `prop_ticket_single` | 一张纸质机票 | 行动卡、赠送确认 | `HomeView` / 赠送反馈 |
| `texture_paper_grain` | 全局纸张肌理 | 页面背景 | 全局样式 |

技术建议：

- 小屋资源优先拆为背景、动物、道具三层。
- SwiftUI 使用 `ZStack` 组合，便于后续根据 `Trip` 状态替换小动物位置和道具。
- 不建议把小猫、地图、来访伙伴全部画死在一张小屋图里。

### 4.2 邮箱列表

| 资源名 | 内容 | 用途 | 接入页面 |
| --- | --- | --- | --- |
| `mailbox_tray_base` | 手绘信件托盘或小邮箱 | 邮箱页顶部氛围图 | `MailboxView` |
| `envelope_unread` | 未读信封 | 新明信片列表项 | `MailboxView` |
| `envelope_read` | 已读信封 | 已读明信片列表项 | `MailboxView` |
| `envelope_old` | 旧明信片信封 | 旧明信片列表项 | `MailboxView` |
| `stamp_paris` | 巴黎邮戳 | 巴黎信封和明信片 | `MailboxView` / `PostcardDetailView` |
| `stamp_iceland` | 冰岛邮戳 | 冰岛信封和明信片 | `MailboxView` / `PostcardDetailView` |

技术建议：

- 信封主体可以作为背景图，文字仍由 SwiftUI 渲染。
- 不要把 `来自巴黎` 等文案画进图片里，避免本地化和动态内容困难。

### 4.3 明信片详情

| 资源名 | 内容 | 用途 | 接入页面 |
| --- | --- | --- | --- |
| `postcard_template_classic` | 经典明信片纸张底和边框 | 明信片详情容器 | `PostcardDetailView` |
| `destination_paris_line` | 巴黎铁塔/街景水彩线稿 | 巴黎明信片图像层 | `PostcardDetailView` |
| `destination_iceland_line` | 冰岛云、山、远方线稿 | 冰岛明信片图像层 | `PostcardDetailView` |
| `animal_cat_selfie` | 小猫自拍半身像 | 巴黎明信片 | `PostcardDetailView` |
| `postmark_overlay_soft` | 半透明邮戳/邮路装饰 | 明信片氛围层 | `PostcardDetailView` |

技术建议：

- 明信片详情建议用模板 + destination + animal + stamp 分层组合。
- 标题、日期、正文由 SwiftUI 渲染。
- `Postcard` 模型中可以增加或映射 `imageAssetName`、`stampAssetName`、`animalAssetName`。

### 4.4 UI 图标

| 资源名 | 内容 | 用途 |
| --- | --- | --- |
| `icon_home` | 小屋 Tab 图标 | 底部导航 |
| `icon_mail` | 邮箱 Tab 图标 | 底部导航 |
| `icon_settings` | 设置图标 | 小屋页右上角 |
| `icon_back` | 返回图标 | 明信片详情、设置二级页 |
| `icon_health` | Health 连接状态图标 | 状态标签 |
| `icon_ticket` | 机票图标 | 行动卡、规则说明 |
| `icon_steps` | 脚步图标 | 权限页、步数说明 |

技术建议：

- 图标使用 PDF vector，颜色由 SwiftUI `foregroundStyle` 控制。
- 图标风格应为手绘线性，不要使用 SF Symbols 默认风格，除非只是临时占位。

## 5. P1 资源：完善核心体验闭环

P1 目标：支持从赠送脚步到旅途中、收到明信片的完整视觉反馈。

### 5.1 欢迎与 Health 权限

| 资源名 | 内容 | 用途 |
| --- | --- | --- |
| `onboarding_cabin_path` | 小屋外景和小路 | 欢迎页 |
| `onboarding_cat_suitcase` | 拿行李箱的小猫 | 欢迎页 |
| `health_steps_ticket` | 心形步数连接机票插画 | Health 权限页 |

技术建议：

- 欢迎页和 Health 页可以暂时不进入主 Tab。
- 资源不应包含按钮文字。

### 5.2 赠送和旅行状态

| 资源名 | 内容 | 用途 |
| --- | --- | --- |
| `ticket_confirm_card` | 带虚线边的纸质机票 | 赠送确认弹层 |
| `trip_route_map_paris` | 小屋到巴黎路线地图 | 旅途中页面 |
| `trip_marker_cat` | 地图上的小猫位置标记 | 旅途中页面 |
| `prop_paper_plane` | 纸飞机 | 出发反馈和旅途中 |
| `effect_ticket_spark_soft` | 非夸张小光点/纸屑 | 赠送成功瞬间 |

技术建议：

- `Trip` 创建后，小屋页可根据 active trip 显示「旅途中」状态。
- 旅途中页面是否作为独立页或小屋内状态卡，可由产品后续决定；资源命名保持通用。

### 5.3 设置页

| 资源名 | 内容 | 用途 |
| --- | --- | --- |
| `settings_sleeping_cat` | 睡觉小猫和纸票 | 设置页底部插画 |
| `icon_notification` | 通知图标 | 设置页 |
| `icon_collection` | 明信片收藏图标 | 设置页 |
| `icon_about` | 关于图标 | 设置页 |
| `toggle_paper_on` | 手绘打开态开关 | 通知设置 |
| `toggle_paper_off` | 手绘关闭态开关 | 通知设置 |

技术建议：

- 如果 toggle 用 SwiftUI 自绘更灵活，则只需要图标，不必制作 `toggle_paper_on/off`。

## 6. P2 资源：扩展内容库

P2 目标：在 MVP 可运行后，扩展动物、目的地和收藏系统。

### 6.1 新动物

| 资源名 | 内容 | 用途 |
| --- | --- | --- |
| `animal_dog_home` | 小狗来访或小屋姿势 | 随机伙伴 |
| `animal_rabbit_home` | 小兔来访或小屋姿势 | 随机伙伴 |
| `animal_bear_home` | 小熊来访或小屋姿势 | 随机伙伴 |
| `animal_bird_mail` | 小鸟信使 | 邮箱、通知 |

技术建议：

- `AnimalVisitService` 可使用 `ContentManifest.json` 中的 `homeAssetName` 随机选择来访动物。

### 6.2 目的地扩展

| 资源名 | 内容 |
| --- | --- |
| `destination_kyoto_line` | 京都鸟居和纸伞 |
| `destination_seaside_line` | 海边灯塔和海浪 |
| `destination_swiss_line` | 瑞士雪山和小屋 |
| `stamp_kyoto` | 京都邮戳 |
| `stamp_seaside` | 海边邮戳 |
| `stamp_swiss` | 瑞士邮戳 |

技术建议：

- 每个目的地在 `ContentManifest.json` 中维护：
  - `id`
  - `displayName`
  - `landmarkAssetName`
  - `stampAssetName`
  - `primaryColor`

### 6.3 明信片收藏

| 资源名 | 内容 | 用途 |
| --- | --- | --- |
| `collection_scrapbook_base` | 手帐收藏纸张底 | 明信片收藏页 |
| `postcard_slot_locked` | 未解锁目的地占位 | 收藏页 |
| `tape_corner_soft` | 胶带贴角 | 明信片装饰 |
| `pin_paper_round` | 圆形纸钉 | 明信片装饰 |

## 7. ContentManifest 建议字段

为了让美术资源和技术逻辑对齐，建议后续把资源名集中配置在 `ContentManifest.json`，避免散落在 View 里。

建议动物配置：

```json
{
  "animals": [
    {
      "id": "cat",
      "displayName": "小猫",
      "homeAssetName": "animal_cat_home",
      "selfieAssetName": "animal_cat_selfie",
      "visitorAssetName": "animal_cat_home"
    }
  ]
}
```

建议目的地配置：

```json
{
  "destinations": [
    {
      "id": "paris",
      "displayName": "巴黎",
      "landmarkAssetName": "destination_paris_line",
      "stampAssetName": "stamp_paris",
      "routeMapAssetName": "trip_route_map_paris"
    }
  ]
}
```

建议明信片配置：

```json
{
  "postcards": [
    {
      "id": "paris_day_2_cat_selfie",
      "destinationId": "paris",
      "animalId": "cat",
      "templateAssetName": "postcard_template_classic",
      "title": "小猫寄来的自拍",
      "subtitle": "第 2 天清晨"
    }
  ]
}
```

## 8. SwiftUI 接入建议

### 8.1 图片组件封装

建议新增通用资源组件：

```swift
struct ArtImage: View {
    let name: String
    var contentMode: ContentMode = .fit

    var body: some View {
        Image(name)
            .resizable()
            .aspectRatio(contentMode: contentMode)
            .accessibilityHidden(true)
    }
}
```

好处：

- 后续统一处理占位、降级、暗色模式、调试边框。
- 避免每个页面重复写 `Image(name).resizable()`。

### 8.2 缺失资源降级

在美术资源未完全加入 target 前，建议保留线框占位组件。

策略：

- Debug 下缺失资源显示线框占位和资源名。
- Release 下缺失资源显示通用纸张占位。

这样美术和开发可以并行，不会因为某个资源缺失导致页面不可用。

### 8.3 分层组合

小屋和明信片建议用 `ZStack` 组合：

```text
小屋：
room_base
window/state layer
table/map props
animal
visitor
action card

明信片：
template
destination landmark
animal selfie
stamp
text
```

不要把动态文字画入图片。

## 9. 动效任务

### 9.1 P0 动效

| 动效 | 实现方式 | 触发 |
| --- | --- | --- |
| 主按钮按压 | SwiftUI scale + opacity | 点击按钮 |
| 信封点击浮起 | SwiftUI offset + scale | 点击信封 |
| 明信片详情打开 | matched/scale transition | 进入详情 |

### 9.2 P1 动效

| 动效 | 实现方式 | 触发 |
| --- | --- | --- |
| 小猫眨眼 | 拆分眼睛图层或 SwiftUI overlay | 小屋待机 |
| 机票弹出 | SwiftUI spring animation | 赠送成功 |
| 纸飞机飞出 | SwiftUI path/offset | 出发成功 |
| 邮戳盖下 | scale + rotation | 收到明信片 |

### 9.3 Lottie 暂缓

首版不建议立刻引入 Lottie。原因：

- 当前核心页面仍在资源替换阶段。
- SwiftUI 原生动效足够表达轻量治愈感。
- Lottie 一旦过多，会影响包体积和维护成本。

如需 Lottie，首版最多 2 个：

- 首次赠送脚步成功
- 首次收到明信片

## 10. 交付检查清单

每个美术资源交付时必须包含：

- 资源名
- 设计尺寸
- 导出倍率
- 是否透明背景
- 使用页面
- 是否可复用
- 是否包含文字
- 是否需要暗色模式版本

验收标准：

- 放入 `Assets.xcassets` 后能被 `Image("name")` 正常读取。
- 在 440 x 956 设计比例下不糊、不裁切。
- 不依赖图片内文字承载关键业务信息。
- 同一类资源风格、描边、水彩颗粒一致。
- 单个资源大小符合预算。

## 11. 推荐执行顺序

第一批：

1. `texture_paper_grain`
2. `icon_home`
3. `icon_mail`
4. `icon_settings`
5. `icon_back`
6. `cabin_room_base`
7. `animal_cat_home`
8. `prop_map_table`
9. `prop_ticket_single`
10. `envelope_unread`
11. `envelope_old`
12. `postcard_template_classic`
13. `destination_paris_line`
14. `animal_cat_selfie`
15. `stamp_paris`

第二批：

1. `mailbox_tray_base`
2. `envelope_read`
3. `destination_iceland_line`
4. `stamp_iceland`
5. `animal_visitor_unknown`
6. `ticket_confirm_card`
7. `trip_route_map_paris`
8. `trip_marker_cat`
9. `prop_paper_plane`

第三批：

1. 欢迎页资源
2. Health 权限页资源
3. 设置页插画
4. 新动物
5. 新目的地
6. 收藏页资源

## 12. 与开发联动的下一步

建议开发与美术同步推进：

1. 美术先交付第一批 P0 资源。
2. 开发把 `Assets.xcassets` 加回 target Resources。
3. 开发新增 `ArtImage` 封装和缺失资源降级。
4. 开发把小屋、邮箱、明信片详情改成分层图片组件。
5. 开发把资源名接入 `ContentManifest.json`。
6. 真机或正常 Xcode 环境验证 asset catalog 编译。
7. 再进入 P1 动效和旅途中状态。

这样可以避免美术资源先画很多，但技术侧无法确定如何接入；也避免开发继续在线框上堆逻辑，后续替换成本过高。
