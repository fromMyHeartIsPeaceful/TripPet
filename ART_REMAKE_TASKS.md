# 步旅小屋美术资源重做任务清单

本文档专门用于重做当前 App 内不符合方向的美术资源。当前真机看到线框感的原因是：`Assets.xcassets` 内大多数资源是程序化 SVG 线稿，并不是已确定的水彩手绘视觉方向。

重做目标：基于已有视觉方向稿和视觉规范，产出可直接接入 iOS App 的正式水彩手绘资源。

## 0. 必读参考

视觉方向必须参考以下文件：

- [VISUAL_ART_SPEC.md](/Users/qianyu/Documents/Trip/VISUAL_ART_SPEC.md)
- [ART_RESOURCE_TASKS.md](/Users/qianyu/Documents/Trip/ART_RESOURCE_TASKS.md)
- [visual_board_main_flow_a.png](/Users/qianyu/Documents/Trip/ArtReferences/visual_board_main_flow_a.png)
- [visual_board_main_flow_b.png](/Users/qianyu/Documents/Trip/ArtReferences/visual_board_main_flow_b.png)
- [visual_board_support_states.png](/Users/qianyu/Documents/Trip/ArtReferences/visual_board_support_states.png)

当前需要替换的资源目录：

- [Assets.xcassets](/Users/qianyu/Documents/Trip/TripPet/Resources/Assets.xcassets)
- [ArtSource](/Users/qianyu/Documents/Trip/TripPet/Resources/ArtSource)

## 1. 总原则

### 1.1 必须坚持的视觉方向

- 温馨治愈
- 水彩手绘
- 旅行手帐
- 柔和纸张质感
- 低饱和色
- 小动物小屋
- 纸质机票、信封、邮戳、明信片

### 1.2 禁止继续使用的产物类型

以下资源不能再作为正式美术资源：

- 程序化 SVG 线框插画
- 只有描边和简单填色的占位图
- 像网页 wireframe 的图形
- 带业务文字的整图
- 与参考视觉板明显不一致的扁平图标式插画

### 1.3 格式规则

| 资源类型 | 正式格式 | 说明 |
| --- | --- | --- |
| 小屋、动物、信封、明信片、目的地 | PNG @3x | 必须有真实水彩质感 |
| 小动物、道具、邮戳、地标 | PNG 透明背景优先 | 方便 SwiftUI 分层组合 |
| UI 图标 | PDF vector 或 SVG | 可以保留矢量，但必须是手绘图标风 |
| 纸张纹理 | PNG | 可平铺，小尺寸 |
| 源文件 | PSD / Procreate / Figma / SVG 源 | 可选，但应保留 |

## 2. 小猫新设定

小猫是 App 的第一主角，必须比当前版本更可爱，但不能变成夸张儿童卡通。

### 2.1 外貌方向

小猫关键词：

- 圆脸
- 软乎乎的短身体
- 小三角耳
- 额头 2-3 条浅色虎斑
- 小豆眼，但比当前更有神
- 小鼻子偏淡桃色
- 短短的小爪子
- 细尾巴，尾尖微微弯
- 可有一条浅鼠尾草绿小围巾

### 2.2 可爱度边界

应该增加：

- 脸更圆
- 表情更温柔
- 身体更小巧
- 动作更有生活感
- 眼睛增加小高光

不要增加：

- 超大动漫眼
- 过度拟人服装
- 强烈腮红
- 夸张卖萌姿势
- 高饱和卡通色

### 2.3 小猫统一描述

后续所有小猫资源都基于这个描述：

> 一只温柔治愈的手绘水彩小猫，圆脸，小豆眼带轻微高光，淡桃色小鼻子，额头有浅浅虎斑，短短小爪子，细尾巴微微弯，戴一条很淡的鼠尾草绿小围巾。整体可爱、安静、好奇，像旅行手帐里的小主角，不是夸张卡通。

## 3. 任务1：建立正式资源生产模板

目标：先建立所有任务共用的产物结构，避免各任务交付格式不一致。

工作内容：

- 新建或整理源文件目录：
  - `TripPet/Resources/ArtSourceRaster/`
  - `TripPet/Resources/ArtSourceRaster/Animals/`
  - `TripPet/Resources/ArtSourceRaster/Cabin/`
  - `TripPet/Resources/ArtSourceRaster/Envelopes/`
  - `TripPet/Resources/ArtSourceRaster/Postcards/`
  - `TripPet/Resources/ArtSourceRaster/Destinations/`
  - `TripPet/Resources/ArtSourceRaster/Stamps/`
  - `TripPet/Resources/ArtSourceRaster/Textures/`
- 确定导出规则：
  - 正式 App 资源进入 `Assets.xcassets`
  - 源文件进入 `ArtSourceRaster`
  - 同名资源替换现有 `.imageset` 中的 SVG
- 为每类资源准备一份 `README.md`，记录尺寸、透明背景、用途。

交付：

- 目录结构
- 导出规则说明
- 一个示例 imageset，证明 PNG 可以正常接入

验收：

- 资源命名与 `ContentManifest.json` 兼容。
- 不需要改 SwiftUI 资源名。

## 4. 任务2：小猫首页主形象

资源名：

- `animal_cat_home`

目标：替换当前首页小猫线框 SVG。

画面内容：

- 更可爱的小猫主角
- 坐姿或半站姿
- 戴淡鼠尾草绿围巾
- 手边可有小地图或票角，但不要喧宾夺主
- 透明背景

建议尺寸：

- 1024 x 1024 源图
- App 导出 PNG @3x

提示词方向：

```text
温馨治愈水彩手绘小猫，圆脸，小豆眼带轻微高光，淡桃色小鼻子，额头浅虎斑，短短小爪子，细尾巴微微弯，戴淡鼠尾草绿小围巾，安静好奇地坐着，旅行手帐风格，柔和纸张质感，低饱和色，透明背景，不要文字，不要夸张卡通，不要线框占位。
```

验收：

- 真机首页小猫明显比当前更温柔可爱。
- 与小屋背景融合。
- 不是简单 SVG 线条。

## 5. 任务3：小猫自拍形象

资源名：

- `animal_cat_selfie`

目标：用于明信片详情中的小猫自拍层。

画面内容：

- 同一只小猫
- 半身自拍姿势
- 微微靠近镜头
- 表情开心但克制
- 可露出一只举起的小爪子
- 透明背景

建议尺寸：

- 1024 x 1024 源图
- App 导出 PNG @3x

验收：

- 与 `animal_cat_home` 是同一角色。
- 可用于巴黎和冰岛明信片。
- 不包含背景和文字。

## 6. 任务4：未知来访伙伴

资源名：

- `animal_visitor_unknown`

目标：替换当前问号线框来访者。

画面内容：

- 门口探头的小小来访伙伴剪影
- 有神秘感，但不吓人
- 可以是半透明水彩轮廓
- 有一个温柔的问号形态或小帽子遮挡
- 透明背景

验收：

- 一眼能看出是“新伙伴来了”。
- 不像错误占位符。

## 7. 任务5：小屋主场景

资源名：

- `cabin_room_base`

目标：替换当前小屋线框背景。

画面内容：

- 温暖小屋室内
- 窗户、墙面、地板、柔软地毯
- 可见旅行地图或墙上明信片位置，但主道具仍可分层
- 早晨光线
- 水彩纸张质感
- 不包含小猫、不包含来访伙伴、不包含业务文字

建议尺寸：

- 1440 x 1440 源图
- App 导出 PNG @3x

验收：

- 放入首页后，小屋页立即脱离线框感。
- 与动物和道具能分层叠放。

## 8. 任务6：小屋桌子与地图

资源名：

- `prop_map_table`

目标：替换桌子地图线框资源。

画面内容：

- 小木桌
- 手绘地图
- 铅笔、便签、折角
- 温柔低饱和
- 透明背景

验收：

- 可独立放在小屋里。
- 不包含小猫。
- 不包含文字。

## 9. 任务7：机票资源组

资源名：

- `prop_ticket_single`
- `ticket_confirm_card`
- `ticket_flight_trail`

目标：让赠送脚步和出发流程有真实纸质机票感。

内容：

- `prop_ticket_single`：小纸质机票，透明背景
- `ticket_confirm_card`：确认弹层中使用的大机票纸张
- `ticket_flight_trail`：机票或纸飞机飞行轨迹装饰

要求：

- 不写业务文字
- 保留虚线孔、邮戳感、纸张边缘
- 水彩淡赭色和象牙白为主

验收：

- 行动卡和确认弹层不再像线框 UI。

## 10. 任务8：邮箱托盘

资源名：

- `mailbox_tray_base`

目标：替换邮箱页顶部信件托盘线框。

画面内容：

- 木质或纸质信件托盘
- 几封叠放的信
- 柔和水彩
- 不包含动态信件标题文字

验收：

- 邮箱页一打开有真实收信氛围。
- 不抢信封列表主内容。

## 11. 任务9：信封状态资源

资源名：

- `envelope_unread`
- `envelope_read`
- `envelope_old`

目标：替换当前三个信封 SVG。

画面内容：

- `envelope_unread`：纸张较新，略鼓，邮票明显
- `envelope_read`：颜色更淡，打开过的折痕
- `envelope_old`：微泛黄，旧明信片感

要求：

- 不包含 `来自巴黎` 等文字
- 保留可放置 SwiftUI 文本的中间空间
- 横向比例适合邮箱列表

建议尺寸：

- 1280 x 520 源图
- App 导出 PNG @3x

验收：

- 信封列表不再像边框卡片。
- 文字叠加后清晰可读。

## 12. 任务10：明信片纸张模板

资源名：

- `postcard_template_classic`

目标：替换详情页明信片模板线框。

画面内容：

- 经典明信片纸张
- 轻微折痕、纸张边缘、胶带或角标
- 预留中部画面区和底部正文区
- 不包含地标、小动物、业务文字

验收：

- 可同时承载巴黎、冰岛和后续目的地。
- SwiftUI 文本叠加后不拥挤。

## 13. 任务11：巴黎目的地资源

资源名：

- `destination_paris_line`
- `stamp_paris`
- `trip_route_map_paris`

目标：让巴黎相关明信片、信封和旅途中状态有正式水彩资产。

内容：

- `destination_paris_line`：巴黎铁塔、清晨云、街灯或屋顶，透明背景或浅背景
- `stamp_paris`：巴黎邮戳，半透明水彩/手绘
- `trip_route_map_paris`：小屋到巴黎的纸质路线地图

验收：

- 巴黎明信片能明显识别目的地。
- 邮戳不抢正文。

## 14. 任务12：冰岛目的地资源

资源名：

- `destination_iceland_line`
- `stamp_iceland`
- `trip_route_map_iceland`

目标：让冰岛明信片和旧信件有正式水彩资产。

内容：

- `destination_iceland_line`：云、雪山、远方道路、海岸风感
- `stamp_iceland`：冰岛邮戳
- `trip_route_map_iceland`：小屋到冰岛的纸质路线地图

验收：

- 和巴黎有明显区分。
- 色调更冷，但仍温柔。

## 15. 任务13：欢迎页资源

资源名：

- `onboarding_cabin_path`
- `onboarding_cat_suitcase`
- `health_steps_ticket`

目标：替换欢迎页和 Health 连接页资源。

内容：

- `onboarding_cabin_path`：小屋外景、小路、纸票
- `onboarding_cat_suitcase`：同一只更可爱小猫，拿行李箱
- `health_steps_ticket`：步数/心形/机票连接插画

验收：

- 首次打开 App 就能传达温馨水彩风格。
- Health 页不显得像系统权限页。

## 16. 任务14：设置页资源

资源名：

- `settings_about_cabin`
- `settings_collection_empty`
- `settings_notification_note`

目标：替换设置二级页和空状态插画。

内容：

- `settings_about_cabin`：小屋、纸票、睡觉小猫
- `settings_collection_empty`：空手帐、未贴满的明信片位置
- `settings_notification_note`：铃铛、纸条、信封

验收：

- 设置页也保持温馨，不像系统列表。

## 17. 任务15：UI 图标二次检查

资源名：

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

目标：判断哪些当前 SVG 可以保留，哪些需要重画。

要求：

- 图标可以继续是矢量。
- 但线条必须像手绘旅行手帐，不要像 SF Symbols 或工程占位图。
- 统一 24 x 24 画布，线条粗细统一。

验收：

- 底部 Tab 和设置页图标与水彩插画风格一致。

## 18. 任务16：资产接入与替换

目标：把新 PNG 资源接入 `Assets.xcassets`，替换当前 SVG。

工作内容：

- 对每个 `.imageset`：
  - 移除或停用旧 SVG
  - 加入新的 PNG
  - 更新 `Contents.json`
- 保持 asset name 不变。
- 不改 SwiftUI 代码，除非尺寸适配确实需要。

验收：

- 真机重新安装后，首页、邮箱、明信片不再显示线框资源。
- `Image("asset_name")` 仍能正常读取。

## 19. 任务17：真机视觉验收

目标：确认新资源在真实手机上的观感。

检查页面：

- 欢迎页
- Health 连接页
- 小屋页
- 赠送确认弹层
- 旅途中状态
- 邮箱页
- 明信片详情
- 设置页

验收标准：

- 视觉接近参考设计板。
- 小猫更可爱，但不夸张。
- 没有明显线框占位感。
- 没有图片模糊、裁切、拉伸。
- 文字没有压在插画复杂区域上。
- 包体积增长可接受。

## 20. 任务18：旧线框资源清理

目标：避免旧 SVG 继续混入正式包。

工作内容：

- 清点 `Assets.xcassets` 中仍存在的插画类 SVG。
- 插画类 SVG 替换为 PNG 后移到 `ArtSource/LegacyLineArt/` 或删除。
- 图标类 SVG 可保留。
- 更新 `ART_RESOURCE_IMPLEMENTATION_LOG.md` 或新建资源替换记录。

验收：

- 正式 App 不再引用线框插画。
- 旧资源有清晰归档，不会误用。

## 21. 推荐并行启动顺序

第一批并行：

- 任务1：建立正式资源生产模板
- 任务2：小猫首页主形象
- 任务3：小猫自拍形象
- 任务5：小屋主场景
- 任务8：邮箱托盘
- 任务10：明信片纸张模板

第二批并行：

- 任务4：未知来访伙伴
- 任务6：小屋桌子与地图
- 任务7：机票资源组
- 任务9：信封状态资源
- 任务11：巴黎目的地资源
- 任务12：冰岛目的地资源

第三批并行：

- 任务13：欢迎页资源
- 任务14：设置页资源
- 任务15：UI 图标二次检查

最后串行：

- 任务16：资产接入与替换
- 任务17：真机视觉验收
- 任务18：旧线框资源清理

## 22. 统一验收红线

任何资源如果出现以下情况，直接判定不通过：

- 看起来像线框图
- 看起来像程序画出来的 SVG
- 和参考视觉板明显不是一个世界
- 小猫不可爱或太夸张
- 图片里写死业务文字
- 放进 App 后文字不可读
- 资源名和工程不一致
- 不能通过 `Image("asset_name")` 读取

最终目标不是“有图”，而是让真机上的 App 明确变成一个温馨水彩旅行手帐世界。
