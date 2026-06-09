# 步旅小屋并行任务清单

本文档用于多开任务窗口并行推进。所有任务默认基于以下上下文：

- 技术工程：[TripPet.xcodeproj](/Users/qianyu/Documents/Trip/TripPet.xcodeproj/project.pbxproj)
- SwiftUI 工程目录：[TripPet/](/Users/qianyu/Documents/Trip/TripPet)
- 技术上下文：[TECHNICAL_CONTEXT.md](/Users/qianyu/Documents/Trip/TECHNICAL_CONTEXT.md)
- 视觉规范：[VISUAL_ART_SPEC.md](/Users/qianyu/Documents/Trip/VISUAL_ART_SPEC.md)
- 美术资源任务：[ART_RESOURCE_TASKS.md](/Users/qianyu/Documents/Trip/ART_RESOURCE_TASKS.md)

## 并行原则

- 每个任务窗口只负责自己的任务，不要顺手重构无关模块。
- 如果需要改同一文件，优先先读当前文件，避免覆盖其他窗口改动。
- 美术资源命名必须与 `ART_RESOURCE_TASKS.md` 对齐。
- SwiftUI 页面先保留缺失资源降级，避免资源未交付时工程不可运行。
- 能用 `ContentManifest.json` 配置的内容，不要硬编码在 View 里。
- 所有开发任务完成后至少跑一次 iphoneos 无签名构建。

构建命令：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project TripPet.xcodeproj -scheme TripPet -configuration Debug -sdk iphoneos -derivedDataPath .derivedData CODE_SIGNING_ALLOWED=NO build
```

---

# 任务1：P0 美术资源生成

目标：生成首批可替换线框的核心水彩资源。

输入：

- [VISUAL_ART_SPEC.md](/Users/qianyu/Documents/Trip/VISUAL_ART_SPEC.md)
- [ART_RESOURCE_TASKS.md](/Users/qianyu/Documents/Trip/ART_RESOURCE_TASKS.md)

产出资源：

- `texture_paper_grain`
- `cabin_room_base`
- `animal_cat_home`
- `prop_map_table`
- `prop_ticket_single`
- `animal_visitor_unknown`
- `mailbox_tray_base`
- `envelope_unread`
- `envelope_read`
- `envelope_old`
- `postcard_template_classic`
- `destination_paris_line`
- `destination_iceland_line`
- `animal_cat_selfie`
- `stamp_paris`
- `stamp_iceland`

要求：

- 水彩手绘、温馨治愈、低饱和。
- 动物、邮戳、地标、道具尽量透明背景。
- 不把业务文字画进图片。
- 资源命名严格使用上述名称。

验收：

- 每个资源有明确文件。
- 风格与视觉规范一致。
- 资源可被放入 `Assets.xcassets`。

---

# 任务2：UI 图标资源生成

目标：生成 App 内所有基础手绘线性图标，替代系统图标。

产出资源：

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

要求：

- 24 x 24 基准画布。
- 手绘线性风格。
- 线条圆润，适合 SwiftUI 着色。
- 优先 PDF vector 或 SVG 源文件。

验收：

- 小尺寸下清晰。
- 与水彩资源风格不冲突。
- 可直接进入 `Assets.xcassets/UI`。

---

# 任务3：Assets.xcassets 接入

目标：把资源目录重新接入 iOS target，并建立清晰分组。

输入：

- `TripPet/Resources/Assets.xcassets`
- `ART_RESOURCE_TASKS.md`

工作内容：

- 确认 `Assets.xcassets` 被加入 target Resources。
- 建立分组：
  - `Animals`
  - `Cabin`
  - `Destinations`
  - `Postcards`
  - `Stamps`
  - `Envelopes`
  - `UI`
  - `Textures`
- 加入已有或占位资源。
- 保证资源名可被 `Image("name")` 读取。

验收：

- Xcode 工程能识别 asset catalog。
- iphoneos 无签名构建成功。
- 不破坏现有 SwiftUI 页面。

---

# 任务4：ArtImage 通用图片组件

目标：新增统一图片组件，支持缺失资源降级。

工作内容：

- 新增 `ArtImage` SwiftUI 组件。
- 支持：
  - asset name
  - content mode
  - accessibility hidden
  - Debug 缺失资源占位
  - Release 通用纸张占位
- 可选：支持固定宽高、圆角、轻纸张阴影。

验收：

- `ArtImage(name: "animal_cat_home")` 可正常使用。
- 缺失资源不会导致页面空白不可理解。
- 后续页面统一用它接图。

---

# 任务5：视觉基础样式系统

目标：把视觉规范中的颜色、字体、间距、阴影落成 SwiftUI 代码。

工作内容：

- 新增颜色常量：
  - paper white
  - ivory
  - sage
  - deep sage
  - mist blue
  - peach
  - ochre
  - olive ink
  - pencil gray
  - paper gray
- 新增字体层级：
  - page title
  - card title
  - body
  - caption
  - button
  - tab
- 新增通用纸张卡片样式。
- 新增主按钮/次按钮样式。

验收：

- 当前页面可引用统一样式。
- 不再散落硬编码颜色。
- 与 `VISUAL_ART_SPEC.md` 对齐。

---

# 任务6：小屋页真实视觉替换

目标：将当前小屋页线框场景替换为水彩分层视觉。

依赖：

- 任务1 或资源占位
- 任务4
- 任务5

工作内容：

- 使用 `ZStack` 组合：
  - `cabin_room_base`
  - `prop_map_table`
  - `animal_cat_home`
  - `animal_visitor_unknown`
  - `prop_ticket_single`
- 保留顶部状态、标题、设置按钮。
- 将行动卡改为纸质票据风格。
- 主按钮使用统一按钮样式。

验收：

- 小屋页仍为一屏设计。
- 没有横向溢出。
- 资源缺失时仍有降级显示。
- 当前业务按钮仍可触发赠送流程。

---

# 任务7：邮箱页真实视觉替换

目标：将邮箱页替换为水彩信件托盘 + 信封列表视觉。

依赖：

- 任务1 或资源占位
- 任务4
- 任务5

工作内容：

- 顶部加入 `mailbox_tray_base` 氛围图。
- 信封列表项使用：
  - `envelope_unread`
  - `envelope_read`
  - `envelope_old`
- 邮戳按明信片目的地展示。
- 保留点击信封打开全屏详情。

验收：

- 一级邮箱页一屏。
- 信封文字由 SwiftUI 渲染，不写死在图片里。
- 点击交互不回退。

---

# 任务8：明信片详情真实视觉替换

目标：把全屏明信片详情替换成模板化水彩明信片。

依赖：

- 任务1 或资源占位
- 任务4
- 任务5

工作内容：

- 使用分层组合：
  - `postcard_template_classic`
  - destination asset
  - animal selfie asset
  - stamp asset
  - SwiftUI 文本
- 保留返回按钮。
- 详情页继续覆盖底部 Tab。

验收：

- 明信片详情打开/关闭正常。
- 文字不被图片遮挡。
- 巴黎、冰岛两张明信片能显示不同目的地资源。

---

# 任务9：设置页视觉升级

目标：将设置页改成水彩纸条列表风格。

依赖：

- 任务2
- 任务5

工作内容：

- Health 状态使用纸质标签。
- 请求 Health 权限按钮使用主按钮样式。
- 设置项使用手绘图标：
  - `icon_health`
  - `icon_notification`
  - `icon_collection`
  - `icon_about`
- 避免系统设置页冷硬风格。

验收：

- Health 权限请求入口仍可用。
- 视觉与小屋/邮箱一致。

---

# 任务10：欢迎页与首次进入流程

目标：新增首次进入欢迎页，为真实 App 建立情绪入口。

工作内容：

- 欢迎页标题：`步旅小屋`
- 副标题：`把今天的脚步，送给想去远方的小动物`
- 主按钮：`开始`
- 插画使用：
  - `onboarding_cabin_path`
  - `onboarding_cat_suitcase`
- 首次进入后进入 Health 连接页或主界面。

验收：

- App 首次启动显示欢迎页。
- 用户点击开始后不再重复显示，除非重置状态。
- 状态可先用内存或 `AppStorage`。

---

# 任务11：Health 连接页

目标：新增独立 Health 连接引导页。

工作内容：

- 标题：`连接健康`
- 文案：`只读取每日步数，用来生成旅行机票`
- 主按钮：`连接 Apple 健康`
- 次级入口：`稍后再说`
- 使用 `health_steps_ticket` 插画。
- 接入现有 `HealthKitStepCountProvider` 权限请求。

验收：

- 点击连接可触发 HealthKit 授权。
- 稍后再说可进入小屋未连接状态。
- 设置页仍可再次请求权限。

---

# 任务12：Health 未连接状态

目标：小屋页支持 Health 未连接时的视觉与操作状态。

工作内容：

- 顶部状态显示 `Health 未连接`。
- 行动卡文案改为：`连接健康后，小动物才能收到今日脚步`。
- 主按钮：`连接 Apple 健康`。
- 次级按钮：`先看看小屋`。

验收：

- Health 未连接时不会显示可赠送机票。
- 连接按钮能进入授权流程。
- 连接成功后恢复正常赠送状态。

---

# 任务13：赠送确认弹层

目标：点击赠送今日脚步后，先出现纸质机票确认弹层。

工作内容：

- 弹层使用 `ticket_confirm_card` 或纸张样式。
- 展示：
  - 今日可赠送 `1` 张机票
  - 小动物
  - 目的地愿望
- 主按钮：`确认赠送`
- 次按钮：`再想想`
- 确认后调用现有赠送逻辑创建 `Trip`。

验收：

- 每天最多赠送 1 次规则不变。
- 不满足步数时不出现确认赠送或显示温柔提示。
- 确认后旅行状态更新。

---

# 任务14：旅途中状态页面/状态卡

目标：赠送后让用户看到小动物已经出发。

工作内容：

- 使用 `Trip` 状态判断是否存在进行中的旅行。
- 显示：
  - `小猫正在去巴黎`
  - `预计明天寄来明信片`
- 使用：
  - `trip_route_map_paris`
  - `trip_marker_cat`
  - `prop_paper_plane`
- 可以先做成小屋内状态卡，后续再决定是否独立页面。

验收：

- 赠送后小屋页状态有明显变化。
- 不影响邮箱和明信片详情。

---

# 任务15：ContentManifest 扩展

目标：把动物、目的地、明信片资源名集中配置。

输入：

- [ContentManifest.json](/Users/qianyu/Documents/Trip/TripPet/Resources/ContentManifest.json)

工作内容：

- 增加或整理：
  - animals
  - destinations
  - postcards
- 为每条内容配置 asset names。
- 避免 View 中硬编码资源名。

验收：

- 猫、巴黎、冰岛、两张明信片都能从 manifest 读取资源名。
- JSON 结构清晰，后续可扩展。

---

# 任务16：Manifest 解析服务

目标：实现读取 `ContentManifest.json` 的轻量服务。

工作内容：

- 新增 manifest model。
- 新增 loader service。
- 将解析结果注入 `AppEnvironment` 或 Repository。
- 解析失败时使用内置 fallback 数据。

验收：

- App 启动能读取 manifest。
- JSON 缺失或格式错误时 App 不崩溃。
- 动物、目的地、明信片内容可由 manifest 驱动。

---

# 任务17：AnimalVisitService 接资源配置

目标：让随机来访伙伴使用 manifest 中的动物资源。

工作内容：

- `AnimalVisitService` 返回动物 id 或动物配置。
- 小屋页根据 `visitorAssetName` 显示来访伙伴。
- 当前没有新伙伴时显示 `animal_visitor_unknown` 或不显示。

验收：

- 每次进入或指定触发时能稳定显示一个来访伙伴。
- 不破坏默认小猫主角显示。

---

# 任务18：PostcardScheduler 接资源配置

目标：让明信片生成与目的地/动物资源绑定。

工作内容：

- `PostcardScheduler` 创建 `Postcard` 时带上：
  - destination id
  - animal id
  - template asset name
  - stamp asset name
  - destination image asset name
  - animal selfie asset name
- 邮箱列表和详情页基于这些字段展示。

验收：

- 巴黎和冰岛明信片显示不同资源。
- 新增目的地时无需改 View。

---

# 任务19：TicketRuleEngine 单元测试

目标：补齐机票规则测试。

工作内容：

- 测试步数小于 3000 不可赠送。
- 测试步数等于 3000 可赠送。
- 测试步数大于 3000 可赠送。
- 测试每天最多赠送 1 次。
- 测试跨天可再次赠送。

验收：

- 单元测试可运行。
- 规则变更时测试能及时暴露问题。

---

# 任务20：Trip 状态单元测试

目标：测试赠送脚步后旅行创建与状态变化。

工作内容：

- 测试赠送成功创建 `Trip`。
- 测试 active trip 可被首页读取。
- 测试 trip 完成后可生成 postcard。
- 测试重复赠送不会创建重复 trip。

验收：

- 核心业务闭环有测试覆盖。

---

# 任务21：Repository 持久化方案设计

目标：为 SwiftData/Core Data 迁移做设计，不急着全量实现。

工作内容：

- 梳理当前内存 `AppRepository` 数据读写点。
- 设计持久化实体：
  - Animal
  - TravelWish
  - Ticket
  - Trip
  - Postcard
  - DailyStepGift
- 明确哪些来自 manifest，哪些是用户状态。

产出：

- 一份持久化设计文档或代码注释方案。

验收：

- 后续实现 SwiftData 时不需要重新理解业务边界。

---

# 任务22：SwiftData 初版实现

目标：将用户状态从内存迁移到 SwiftData。

依赖：

- 任务21

工作内容：

- 新增 SwiftData model。
- 持久化：
  - 已赠送日期
  - tickets
  - trips
  - postcards
  - onboarding 状态
  - Health 引导状态
- 保持 manifest 内容不重复持久化。

验收：

- 重启 App 后邮箱明信片和旅行状态仍存在。
- 构建成功。

---

# 任务23：AppEnvironment 整理

目标：让环境依赖更清晰，便于测试和预览。

工作内容：

- 梳理 `AppEnvironment` 中的 repository、services、providers。
- 为 Preview 提供 mock environment。
- 为测试提供 fake step provider。

验收：

- 页面 Preview 不依赖 HealthKit 真权限。
- 单元测试可以注入假数据。

---

# 任务24：SwiftUI Preview 样例数据

目标：为关键页面补 Preview，提高设计调试效率。

工作内容：

- 小屋页 Preview：
  - Health 已连接
  - Health 未连接
  - 可赠送
  - 已赠送/旅途中
- 邮箱页 Preview：
  - 空邮箱
  - 有两封信
- 明信片详情 Preview：
  - 巴黎
  - 冰岛

验收：

- Xcode Preview 可看主要状态。
- 不依赖真实 HealthKit。

---

# 任务25：小屋页动效

目标：为小屋首页增加轻量治愈动效。

工作内容：

- 小猫轻微呼吸或眨眼。
- 主按钮点击轻微下沉。
- 机票图标轻微浮动。
- 动效可在 Reduce Motion 下关闭。

验收：

- 动效不影响布局。
- `UIAccessibility.isReduceMotionEnabled` 时减少或关闭动画。

---

# 任务26：信封与明信片转场动效

目标：提升邮箱打开明信片的仪式感。

工作内容：

- 信封点击时轻微浮起。
- 明信片详情从信封位置展开或淡入。
- 返回时自然收起。
- 保持全屏覆盖 Tab。

验收：

- 动效流畅。
- 不影响点击和返回。
- 低性能设备上不过度复杂。

---

# 任务27：赠送成功动效

目标：赠送今日脚步后有明确但克制的反馈。

工作内容：

- 机票弹出。
- 小动物轻轻挥手或纸飞机飞出。
- 更新到旅途中状态。
- 暂不引入 Lottie，先用 SwiftUI 原生动画。

验收：

- 赠送后用户明确知道操作成功。
- 动效结束后状态稳定。

---

# 任务28：空状态与异常状态

目标：补齐真实 App 必备状态。

工作内容：

- 邮箱为空。
- 今日步数不足 3000。
- 今日已经赠送过。
- Health 权限被拒绝。
- Health 数据读取失败。
- Manifest 资源缺失。

验收：

- 每个状态都有温柔文案和可执行下一步。
- 不出现技术错误文案。

---

# 任务29：真机 HealthKit 验证

目标：在真机上验证 HealthKit 权限和步数读取。

工作内容：

- 检查 Entitlements。
- 真机请求 Health 权限。
- 读取今日步数。
- 验证无权限、拒绝、授权后的状态。

验收：

- 真机能读取今日步数。
- 权限状态能正确反映到小屋页和设置页。

---

# 任务30：可访问性检查

目标：保证治愈视觉不牺牲可用性。

工作内容：

- 为关键按钮设置 accessibility label。
- 图片装饰设为 hidden。
- 明信片正文可被 VoiceOver 读出。
- 检查颜色对比度。
- 支持 Dynamic Type 的基本缩放。

验收：

- VoiceOver 能完成小屋赠送和打开明信片流程。
- 文字不因字号放大而严重溢出。

---

# 任务31：包体积与资源压缩

目标：控制美术资源进入 App 后的体积。

工作内容：

- 检查 PNG 尺寸和压缩。
- 移除未使用资源。
- 对大图资源制定按需加载策略。
- 记录首屏资源体积。

验收：

- 首屏视觉资源接近或低于 `800KB` 目标。
- 单个目的地资源接近或低于 `250KB` 目标。

---

# 任务32：从网页原型到 SwiftUI 对照清理

目标：确认旧 `index.html` 原型中的交互都已在 SwiftUI 中实现。

工作内容：

- 对照 `index.html`：
  - 小屋页
  - 邮箱页
  - 信封点击
  - 明信片全屏详情
  - 返回关闭
  - 设置入口
- 标记 SwiftUI 已覆盖/未覆盖项。

产出：

- 简短对照清单，可写入技术上下文或单独文档。

验收：

- 不遗漏原型中的关键交互。

---

# 任务33：更新 TECHNICAL_CONTEXT.md

目标：将新增视觉、资源、接入方式同步到技术上下文。

工作内容：

- 更新资源目录状态。
- 更新视觉规范文档链接。
- 更新美术资源任务链接。
- 记录 asset catalog 接入状态。
- 记录新增页面/状态。
- 记录构建结果。

验收：

- 新开任务窗口能只读技术上下文快速接上。

---

# 任务34：整理最终 MVP 页面清单

目标：明确第一版上线到底包含哪些页面和状态。

工作内容：

- 输出页面表：
  - 欢迎
  - Health 连接
  - 小屋
  - 赠送确认
  - 旅途中状态
  - 邮箱
  - 明信片详情
  - 设置
- 标注每页：
  - 入口
  - 是否一级页
  - 数据来源
  - 资源依赖
  - 空状态

验收：

- 产品、设计、开发对 MVP 边界一致。

---

# 任务35：文案系统整理

目标：统一 App 中所有中文文案，避免页面里各写各的。

工作内容：

- 整理：
  - 按钮文案
  - Health 权限说明
  - 赠送规则
  - 邮箱空状态
  - 明信片正文示例
  - 异常提示
- 可先做 Swift 常量或文档。

验收：

- 文案温柔克制。
- 不出现健身工具感太强的表述。
- 业务规则表达清晰。

---

# 任务36：目的地内容第一批

目标：完善巴黎和冰岛的内容配置。

工作内容：

- 巴黎：
  - 目的地名
  - 愿望文案
  - 明信片标题
  - 明信片正文
  - 地标资源名
  - 邮戳资源名
- 冰岛：
  - 目的地名
  - 旧明信片标题
  - 明信片正文
  - 地标资源名
  - 邮戳资源名

验收：

- 邮箱两封信内容完整。
- 明信片详情不再依赖临时硬编码。

---

# 任务37：新伙伴出现规则设计

目标：明确随机伙伴何时出现、出现多久、是否可交互。

工作内容：

- 设计规则：
  - 每日首次打开概率
  - 赠送后是否提高概率
  - 是否根据目的地解锁
  - 是否只是视觉出现还是可点击
- 与 `AnimalVisitService` 对齐。

产出：

- 规则文档或服务接口草案。

验收：

- 后续实现不会和产品预期冲突。

---

# 任务38：旅行与明信片时间规则设计

目标：明确 Trip 到 Postcard 的时间关系。

工作内容：

- 设计：
  - 赠送后多久出发
  - 第几天收到明信片
  - 是否每天只收一张
  - 旧明信片如何出现
  - 旅行结束条件
- 与 `PostcardScheduler` 对齐。

验收：

- 邮箱内容生成有规则，不只是写死两封信。

---

# 任务39：设置二级页实现

目标：实现通知设置、明信片收藏、关于页入口。

工作内容：

- 通知设置页：
  - 收到明信片提醒
  - 小动物出发提醒
  - 每日可赠送提醒
- 明信片收藏页：
  - 已收明信片列表/手帐布局
- 关于页：
  - App 说明、版本、隐私说明入口

验收：

- 设置页入口可点击。
- 可以先用静态内容和占位资源。

---

# 任务40：最终集成验收

目标：合并并行任务后的完整检查。

工作内容：

- 拉齐所有任务改动。
- 跑构建。
- 检查小屋/邮箱/明信片/设置主流程。
- 检查资源是否缺失。
- 检查 Health 未连接和已连接状态。
- 更新上下文文档。

验收：

- iphoneos 无签名构建成功。
- 主流程可走通。
- 视觉资源接入无明显缺失。
- 文档与实际状态一致。
