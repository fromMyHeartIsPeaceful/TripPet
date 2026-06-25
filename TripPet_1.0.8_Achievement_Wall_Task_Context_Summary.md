# TripPet 1.0.8 小动物成就墙任务上下文总结

更新时间：2026-06-25

## 1. 当前目录和分支

### 1.0.8 开发目录

- 路径：`/Users/edy/Documents/TripPet-1.0.8-achievements`
- 分支：`codex/1.0.8-achievements`
- 基线：`1.0.6文本库`
- 当前 HEAD：`e3e9ee5 Replace duplicate rabbit text with bear postcard text`
- 重要结论：`codex/1.0.8-achievements` 是基于 `1.0.6文本库` 开的，没有合入 1.0.7。

### 1.0.7 当前目录

- 路径：`/Users/edy/Documents/心理`
- 当前分支：`1.0.7测试动画效果`
- 当前 HEAD：`c21fbaf Polish departure card transition`
- 1.0.7 已包含：动画效果、HealthKit、通知、邮箱、地图/小屋视觉、明信片详情等一批改动。

### 最早上下文总结

- 文件：`/Users/edy/Documents/心理/TripPet_1.0.8_Achievements_Context_Summary.md`
- 作用：记录最早的 1.0.8 成就系统需求、为什么从 1.0.6 开 1.0.8、1.0.7 合并风险、原始 HTML 线框等。
- 本文档是本轮“小动物成就墙三入口切换 + 动画修复”的追加上下文。

## 2. 本轮 1.0.8 已完成内容

### 核心功能

- 第二个 Tab 保持为 `成就`，直接进入成就墙，不再做“一级成就页 -> 二级详情页”。
- 成就墙内有 3 个入口按钮：`旅行 / 脚步 / 明信片`。
- 入口按钮只切换同一张明信片底图上的勋章区域。
- 小动物头像、左右切换箭头、明信片底图保持稳定。
- 旅行、脚步、明信片都按当前小动物独立统计。

### 三类统计口径

- 旅行：按 `Trip.animalId` 统计旅行次数，继续使用分段独立进度。
  - 示例：完成 1 次后第一枚为 `1 / 1`，第二枚为 `0 / 10`。
- 脚步：新增 `Ticket.animalId: String?`，送票时记录当前小动物，按动物累计 `sourceSteps`。
  - `sourceSteps == 0` 不计入。
  - 旧票 `animalId == nil` 时，通过 `Ticket.giftedAt` 和 `Trip.departedAt` 同时间匹配推断动物；推断不到则不计入任何动物，避免串数。
- 明信片：通过 `Postcard.tripId -> Trip.animalId` 归属到小动物。
  - 找不到 Trip 的明信片不计入。

### UI 和动画

- 主视图：`AchievementWallView`，文件仍在 `TripPet/Features/Achievements/TravelAchievementWallView.swift`。
- 卡片背景复用明信片资产：
  - `postcard_base_portrait`
  - `postcard_edge_<animalStyle>`
  - `postcard_motif_<animalStyle>`
- 已修复分类切换时底图/UI 变形：
  - 移除卡片外层随 `selectedCategory` 的整体动画。
  - 卡片使用稳定高度。
  - 勋章区固定高度并内部滚动。
  - 淡入淡出只作用于勋章网格区域。
  - 脚步 14 枚、明信片 9 枚、旅行 6 枚不会撑高或缩短外层卡片。

## 3. 代码改动清单

### 新增/重构的成就模块

- `TripPet/Domain/Models/Achievement.swift`
  - 新增 `AchievementCategory`
  - 新增通用 `AchievementTier`
  - 新增通用 `AchievementMedalProgress`
  - 新增通用 `AchievementAnimalProgress`
  - 新增 `AchievementSummary`

- `TripPet/Domain/Services/AchievementEngine.swift`
  - 旅行 6 档。
  - 脚步 14 档。
  - 明信片 9 档。
  - 支持三类按小动物独立计算。
  - 保留 `travelProgress` / `travelSummary` 兼容测试和旧调用。

- `TripPet/Features/Achievements/TravelAchievementWallView.swift`
  - 文件名暂未改，内部主视图为 `AchievementWallView`。
  - 实现小动物成就墙和三入口切换。
  - 固定卡片高度和勋章区滚动，避免切换变形。

### 接入 Tab 和通知

- `TripPet/App/RootTabView.swift`
  - 第二 Tab 改为 `AchievementWallView`。
  - Tab 文案为 `成就`。
  - 图标复用 `icon_collection`。
  - 不再显示邮箱 unread badge。

- `TripPet/App/PostcardNotificationService.swift`
  - `AppTab` 使用 `.achievements`。
  - 旧通知 payload `target == "mailbox"` 安全路由到 `.achievements`。

- `TripPet/DesignSystem/AppCopy.swift`
  - 增加或改用 `AppCopy.Tabs.achievements = "成就"`。

### 数据模型和持久化

- `TripPet/Domain/Models/Ticket.swift`
  - 新增 `animalId: String? = nil`。

- `TripPet/Data/Repositories/AppRepository.swift`
  - `giftTicket` 创建 `Ticket` 时写入 `animal.id`。

- `TripPet/Data/Persistence/UserStatePersistence.swift`
  - `PersistedTicket` 新增 optional `animalId`。
  - 保存/加载 `Ticket.animalId`。
  - 因为是 optional 字段，目标是兼容已有数据；后续和 1.0.7 合并时仍需重点验证真实 SwiftData store 启动。

### 测试

- `TripPetTests/AchievementEngineTests.swift`
  - 旅行空数据、1 次、12 次、211 次、按动物分开。
  - 脚步按动物独立累计。
  - `sourceSteps == 0` 不计入。
  - 旧票按同时间 Trip 推断动物。
  - 无法推断旧票不计入。
  - 明信片按 `tripId -> Trip.animalId` 关联。
  - 缺失 Trip 的明信片不计入。
  - 三类 summary 总数验证。
  - 三入口顺序验证：`旅行 / 脚步 / 明信片`。

- `TripPetTests/RootTabViewTests.swift`
  - 第二 Tab 文案为 `成就`。
  - 旧 mailbox 通知路由到 `.achievements`。
  - 保留明信片标题 sender fallback 相关测试。

## 4. 美术资源整理

### 已复制到 1.0.8 的 1.0.7 明信片动物资源

这些资源来自 1.0.7，用于成就墙背景的小动物风格装饰；不是本轮新生成美术。

Edge：

- `postcard_edge_xiaoman_hamster`
- `postcard_edge_tangyuan_puppy`
- `postcard_edge_moji_cat`
- `postcard_edge_dengdeng_rabbit`
- `postcard_edge_feifei_parrot`
- `postcard_edge_xiaolu_guinea_pig`
- `postcard_edge_deer_visitor`
- `postcard_edge_fox_visitor`
- `postcard_edge_bear_visitor`

Motif：

- `postcard_motif_xiaoman_hamster`
- `postcard_motif_tangyuan_puppy`
- `postcard_motif_moji_cat`
- `postcard_motif_dengdeng_rabbit`
- `postcard_motif_feifei_parrot`
- `postcard_motif_xiaolu_guinea_pig`
- `postcard_motif_deer_visitor`
- `postcard_motif_fox_visitor`
- `postcard_motif_bear_visitor`

### 动物风格映射

成就墙和 1.0.7 明信片详情页保持同一套映射：

- `animal_home_xiaoman_hamster` -> `xiaoman_hamster`
- `animal_home_tangyuan_puppy` -> `tangyuan_puppy`
- `animal_home_moji_cat` -> `moji_cat`
- `animal_home_dengdeng_rabbit` -> `dengdeng_rabbit`
- `animal_home_feifei_parrot` -> `feifei_parrot`
- `animal_home_xiaolu_guinea_pig` -> `xiaolu_guinea_pig`
- `animal_home_jiujiu_deer` -> `deer_visitor`
- `animal_home_aini_fox` -> `fox_visitor`
- `animal_home_dundun_bear` -> `bear_visitor`

## 5. 当前验证结果

最近一次通过的命令：

```sh
xcodebuild test -project TripPet.xcodeproj -scheme TripPet -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4.1'
```

结果：`TEST SUCCEEDED`

手动验证状态：

- 已安装并启动到 iPhone 17 模拟器。
- 最新启动 PID：`29419`。
- 已修复分类切换导致的底图/UI 变形问题。

## 6. 后续如何和 1.0.7 合并

### 推荐合并方向

不要直接在当前 1.0.8 worktree 里硬合 1.0.7。

推荐后续单独开 integration 分支：

1. 从 1.0.7 当前目标分支开新分支，例如基于 `1.0.7测试动画效果`。
2. 把 1.0.8 成就墙改动 cherry-pick 或手动移植进去。
3. 以 1.0.7 的 Health、通知、地图、小屋、动画、明信片主流程为准。
4. 以 1.0.8 的成就模型、成就墙 UI、三类统计、`Ticket.animalId` 为准。
5. 合并后跑完整测试，并在模拟器里验证小屋送票、明信片生成、成就页切换。

### 为什么这样合

- 1.0.8 是基于 1.0.6 开的。
- 1.0.7 已经在多个共享文件中改了核心流程。
- 如果直接把 1.0.7 merge 到 1.0.8，容易把 Health、通知、邮箱、地图、小屋动画的冲突一次性堆在一起。
- 从 1.0.7 开 integration，再移植 1.0.8 成就功能，冲突面更清晰。

## 7. 合并时重点注意

### 高风险文件

- `TripPet/App/RootTabView.swift`
  - 1.0.8 第二 Tab 是成就。
  - 1.0.7 可能仍有邮箱入口或其他 Tab/动画改动。
  - 合并后确认第二 Tab 仍为 `成就`，且不再显示邮箱 unread badge。

- `TripPet/App/PostcardNotificationService.swift`
  - 1.0.8 旧 mailbox 通知路由到 `.achievements`。
  - 1.0.7 可能有通知授权/投递相关修复。
  - 合并时保留 1.0.7 通知稳定性，同时保留旧 mailbox target 不进入无内容 Tab 的安全路由。

- `TripPet/App/AppEnvironment.swift`
  - 1.0.8 当前没有主动改它，但成就页读取 repository 数据。
  - 1.0.7 在 Health、通知、明信片 reveal 相关逻辑上可能有改动，合并时不要回退。

- `TripPet/Data/Repositories/AppRepository.swift`
  - 1.0.8 在 `giftTicket` 写入 `Ticket.animalId`。
  - 1.0.7 可能改了旅行/明信片/小屋状态流。
  - 合并时要确保每次送票创建 Ticket 时仍能拿到最终出发动物 id，并写入 `animalId`。

- `TripPet/Data/Persistence/UserStatePersistence.swift`
  - 1.0.8 增加 `PersistedTicket.animalId`。
  - 1.0.7 如果改过 SwiftData schema 或迁移方式，需要重新评估兼容。
  - 合并后必须用已有模拟器 store 启动一次，确认不崩。

- `TripPet/Domain/Models/Ticket.swift`
  - 保留 `animalId: String? = nil`。
  - 不要改成非 optional，否则旧数据和旧测试容易出问题。

- `TripPet/Features/Mailbox/PostcardDetailView.swift`
  - 1.0.7 有正式明信片底图/edge/motif 组合逻辑。
  - 成就墙复用了同一套 edge/motif 命名，合并时不要删除资源或映射。

- `TripPet.xcodeproj/project.pbxproj`
  - 1.0.8 新增成就模型/服务/视图/测试文件引用。
  - 1.0.7 可能也有新增资源或文件引用。
  - pbxproj 冲突建议手动核对 target membership，尤其是 `Achievement.swift`、`AchievementEngine.swift`、`TravelAchievementWallView.swift`、`AchievementEngineTests.swift`。

### 行为验收清单

合并后至少检查：

- 第二 Tab 是 `成就`。
- 成就页默认显示旅行。
- 点击 `旅行 / 脚步 / 明信片` 时底图和头像不缩放、不跳动。
- 脚步 14 枚可在勋章区内部滚动。
- 左右切换小动物后，当前分类保持不变。
- 旅行次数不串动物。
- 脚步按 `Ticket.animalId` 不串动物。
- 明信片按 `Postcard.tripId -> Trip.animalId` 不串动物。
- 小屋送票后仍正常创建 Trip、Ticket、Postcard。
- 旧 mailbox 通知不会把 TabView 导向不存在页面。
- 1.0.7 的 HealthKit 授权、通知、地图、小屋动画不回退。

## 8. 当前不做的事

- 没有提交 commit。
- 没有 push。
- 没有创建 PR。
- 没有删除邮箱文件。
- 没有合入 1.0.7。
- 没有新增正式勋章美术。
- 没有修改 HealthKit 读取逻辑。
- 没有修改地图页主逻辑。

## 9. 给后续任务窗口的建议流程

如果继续在 1.0.8 worktree 上开发：

1. 先进入 `/Users/edy/Documents/TripPet-1.0.8-achievements`。
2. 确认分支为 `codex/1.0.8-achievements`。
3. 运行测试命令确认基线。
4. 优先完善成就墙视觉细节，不碰 Health/地图/小屋主流程。

如果准备和 1.0.7 合并：

1. 从 `/Users/edy/Documents/心理` 当前 1.0.7 目标分支开 integration 分支。
2. 移植 1.0.8 成就相关代码和资源。
3. 手动解决高风险文件冲突。
4. 跑完整测试。
5. 模拟器验证 Tab、成就切换、小屋送票、明信片投递、旧通知路由。

