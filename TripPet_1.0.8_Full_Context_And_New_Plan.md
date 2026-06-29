# TripPet 1.0.8 成就系统完整上下文总结与最新规划

更新时间：2026-06-26  
当前主工作目录：`/Users/edy/Documents/心理`  
当前主工作目录分支：`1.0.7测试动画效果`  
1.0.8 开发目录：`/Users/edy/Documents/TripPet-1.0.8-achievements`  
1.0.8 基线：`1.0.6文本库`  
远端 1.0.8 分支：`origin/1.0.8成就系统`  

本文档用于交接 1.0.8 成就系统的完整上下文：包括最早那份总结中的需求、为什么从 1.0.6 开 1.0.8、原型演进、本轮实现内容、当前远端分支状态，以及用户最新决定“1.0.7 邮箱和通知逻辑继续保留，1.0.8 勋章系统在此基础上合并”后的技术判断。

## 1. 项目守则

本仓库有强制项目守则：

- `/Users/edy/Documents/心理/.codex/skills/project-guardrails/SKILL.md`

继续开发、合并、测试、推送前必须遵守：

- 不要改无关模块。
- Debug 和架构判断必须基于证据。
- 不要 push、发 PR、上传 GitHub，除非用户明确要求。
- 可见正式美术资产应使用图像生成或正式资源，不要用代码硬画正式美术。
- 如果两轮迭代仍未解决问题，要停下来重新判断方向。

## 2. 当前 Git 和文件状态

主工作目录 `/Users/edy/Documents/心理` 当前状态：

```text
## 1.0.7测试动画效果...origin/1.0.7测试动画效果
?? .codex/
?? AGENTS.md
?? TripPet_1.0.8_Achievement_Wall_Task_Context_Summary.md
?? TripPet_1.0.8_Achievements_Context_Summary.md
?? achievement-wireframe.html
```

远端当前存在 1.0.8 分支：

```text
6e5c54957f7f7d22b0ac8e44a509b4a76f49c4cd refs/heads/1.0.8成就系统
```

重要结论：

- `1.0.8成就系统` 已经推到 GitHub。
- 1.0.8 的开发基线仍是 `1.0.6文本库`，不是从 1.0.7 开出来的。
- 当前主工作目录中两份总结文档和 `achievement-wireframe.html` 仍显示为未跟踪文件。
- 本文档是对早期总结、本轮任务总结、最新合并规划的整合版。

## 3. 1.0.8 的起点和来龙去脉

### 3.1 最早的产品方向

最早的需求是做 TripPet 的成就系统，核心想法是：

- 把第二个 Tab 从“邮箱”替换为“成就”。
- 成就系统分为三类：
  - 小动物旅行次数成就。
  - 用户赠送脚步数成就。
  - 小动物明信片收集成就。
- 成就页最早规划为“一级入口页 -> 二级勋章详情页”。
- 每个勋章对应一个成就，页面要有收集感和持续激励感。

当时对邮箱的态度是：

- 邮箱旧文件可以先保留。
- 明信片数据继续用于成就统计。
- 第二 Tab 入口先从邮箱切到成就。

### 3.2 为什么建议从 1.0.6 开 1.0.8

当时主线 1.0.7 已经包含大量仍在测试中的改动：

- 小屋布局。
- 全屏出行动画。
- 地图页大改。
- HealthKit 修复。
- 通知和邮箱流程修复。
- 明信片详情和大量资源。
- 出行动画、地图、小屋相关视频和图片资源。

如果直接从 1.0.7 开 1.0.8，会导致成就系统问题和 1.0.7 未验证问题混在一起，后续调试困难。

因此当时推荐路线是：

```text
1.0.6文本库
  -> codex/1.0.8-achievements
       只做成就系统
       只引入必要资源
       不合入 1.0.7 整包
```

后续实际采用了独立 worktree：

```text
/Users/edy/Documents/TripPet-1.0.8-achievements
```

并基于 `1.0.6文本库` 开始 1.0.8 成就系统开发。

## 4. 早期 HTML 原型和视觉演进

早期静态线框文件：

- `/Users/edy/Documents/心理/achievement-wireframe.html`

最早网页包含四个手机画布：

1. 成就一级页。
2. 旅行次数成就详情页。
3. 赠送脚步成就详情页。
4. 明信片收集成就详情页。

早期旅行勋章墙原型为“一张融合式大卡”：

- 返回按钮在卡片外顶部。
- 卡片内标题为 `旅行勋章墙`。
- 卡片背景复用明信片底图。
- 小动物头像使用当前动物的 `homeAssetName`。
- 左右切换箭头复用地图箭头资源。
- 显示当前进度和进度条。
- 同一张卡片内展示 6 枚旅行勋章。

后续根据模拟器截图逐步调整：

- 删除整体进度条模块。
- 删除勋章外层方框。
- 标题移到页面顶部，节省卡片内部空间。
- 使用 1.0.7 的明信片底图和小动物对应装饰资源，而不是错误的通用 PNG 底图。
- 将“一级入口页 -> 二级详情页”改为在同一成就墙内放三个入口按钮。

## 5. 成就统计口径

### 5.1 旅行成就

统计方式：

- 每只小动物独立统计旅行次数。
- 从 `Trip.animalId` 分组。
- 不按 `TripStatus` 过滤；只要有 Trip 记录，就计入该动物旅行次数。
- 使用分段独立进度。

旅行 6 档：

| 阈值 | 标题 | 副标题 |
| --- | --- | --- |
| 1 次 | 穷人乍富 | 初次体验旅游乐趣 |
| 10 次 | 小富即安 | 逐渐变为出行常客 |
| 20 次 | 观光达人 | 认识个有钱朋友可真好 |
| 30 次 | 游玩专家 | 永远享受别人买单的旅行真是惬意 |
| 50 次 | 探险大师 | 我在旅行生涯中一分钱没出过你敢信 |
| 100 次 | 环球旅人 | 我的成就来源于背后有一个贼有实力的大佬 |

分段独立进度示例：

- 当前旅行次数为 1。
- 第一档显示 `1 / 1`，状态为已收集。
- 第二档显示 `0 / 10`，状态为进行中。
- 后续显示 `0 / 20`、`0 / 30` 等，状态为未开始或未收集。

### 5.2 脚步成就

最新规划中，脚步成就也按小动物独立统计。

统计方式：

- 新增 `Ticket.animalId: String?`。
- 用户给某只小动物送票时，将当前 `resolvedAnimalId` 写入 Ticket。
- 累计该动物所有 Ticket 的 `sourceSteps`。
- `sourceSteps == 0` 不计入脚步成就。
- 旧票 `animalId == nil` 时，通过 `Ticket.giftedAt` 和 `Trip.departedAt` 同时间匹配推断动物。
- 推断不到的旧票不归属到任何动物，避免错误串数。

脚步 14 档：

| 阈值 | 标题 |
| --- | --- |
| 3000 步 | 您也是辛苦了 |
| 9000 步 | 没病走两步 |
| 20000 步 | 佛山无影脚在世传人 |
| 30000 步 | 要啥自行车 |
| 50000 步 | 有了闪现技能还想去送外卖的热爱走路人士 |
| 100000 步 | 您真是白脚起家呀！ |
| 200000 步 | 一人之力托举起9个小动物的奉献之神 |
| 300000 步 | 这地球，这世界，全是您走出来的！ |
| 400000 步 | 不知道您是否听说过一个叫骆驼祥子的人？ |
| 500000 步 | 11路公交车司机 |
| 600000 步 | 你的腿不是腿，是塞纳河畔的春水 |
| 700000 步 | 踏破铁鞋无觅处，蓦然回首，那人却在灯火阑珊处 |
| 800000 步 | 铁板烧！不，是铁脚板！ |
| 1000000 步 | 宇也球说“我是谁呀，我是您脚底的一颗痣而已” |

### 5.3 明信片成就

统计方式：

- 每只小动物独立统计明信片数量。
- `Postcard` 通过 `tripId` 关联到 `Trip`。
- 再通过 `Trip.animalId` 归属到对应小动物。
- 找不到 Trip 的明信片不计入，避免错误串数。

明信片 9 档：

| 阈值 | 标题 |
| --- | --- |
| 1 张 | 初次相识 |
| 10 张 | 些许相知 |
| 50 张 | 你也有点可爱 |
| 100 张 | 有钱人也不会是无情无义之人 |
| 200 张 | 谁说的有钱人无情无义！ |
| 300 张 | 你说什么都对，My Lord |
| 500 张 | 很难想象世界上还有你这样完美的人 |
| 800 张 | 我要打包银河系的爱给你 |
| 1000 张 | 还是打包整个宇宙吧，全是我的真心 |

## 6. 本轮 1.0.8 已实现内容

### 6.1 功能层

已完成的小动物成就墙逻辑：

- 第二 Tab 直接进入成就墙。
- 成就墙顶部有当前小动物展示。
- 左右箭头切换小动物。
- 三个入口按钮：`旅行 / 脚步 / 明信片`。
- 点击入口按钮时，只切换勋章区域。
- 旅行、脚步、明信片都接真实数据。
- 三类成就都按当前小动物独立统计。

### 6.2 UI 层

最终方向：

- 不再做一级入口页。
- 用户进入成就 Tab 后直接看到当前小动物的成就墙。
- 三个入口按钮放在小动物区域下方。
- 同一张明信片底图上切换不同勋章网格。
- 明信片底图、小动物头像、左右箭头、按钮区域保持稳定。
- 勋章区域内部滚动，避免脚步 14 枚、明信片 9 枚撑高卡片。

已修复的问题：

- 分类切换时底图和 UI 发生缩放、变形。
- 修复方式：
  - 移除卡片外层随 `selectedCategory` 的整体动画。
  - 卡片使用稳定高度。
  - 勋章区固定高度。
  - 只在勋章网格区域做局部淡入淡出。
  - 顶部标题不参与布局动画。

### 6.3 资源层

成就墙复用了 1.0.7 的明信片资源组合：

- `postcard_base_portrait`
- `postcard_edge_<animalStyle>`
- `postcard_motif_<animalStyle>`

动物风格映射：

| 动物资源 | 明信片风格 |
| --- | --- |
| `animal_home_xiaoman_hamster` | `xiaoman_hamster` |
| `animal_home_tangyuan_puppy` | `tangyuan_puppy` |
| `animal_home_moji_cat` | `moji_cat` |
| `animal_home_dengdeng_rabbit` | `dengdeng_rabbit` |
| `animal_home_feifei_parrot` | `feifei_parrot` |
| `animal_home_xiaolu_guinea_pig` | `xiaolu_guinea_pig` |
| `animal_home_jiujiu_deer` | `deer_visitor` |
| `animal_home_aini_fox` | `fox_visitor` |
| `animal_home_dundun_bear` | `bear_visitor` |

注意：

- 这些明信片 edge/motif 资源来自 1.0.7。
- 本轮没有新增正式勋章美术。
- 勋章仍使用 SwiftUI 圆形占位表达状态。

## 7. 1.0.8 主要代码改动

### 7.1 新增或重构的成就模块

- `TripPet/Domain/Models/Achievement.swift`
  - `AchievementCategory`
  - `AchievementTier`
  - `AchievementMedalProgress`
  - `AchievementAnimalProgress`
  - `AchievementSummary`

- `TripPet/Domain/Services/AchievementEngine.swift`
  - 三类成就计算。
  - 旅行 6 档。
  - 脚步 14 档。
  - 明信片 9 档。
  - 按动物独立统计。
  - 保留 `travelProgress` / `travelSummary` 兼容旧测试或旧调用。

- `TripPet/Features/Achievements/TravelAchievementWallView.swift`
  - 文件名仍叫 `TravelAchievementWallView.swift`。
  - 内部主视图已经扩展为通用 `AchievementWallView`。
  - 实现小动物成就墙、三入口按钮、勋章网格切换。

### 7.2 数据模型和持久化

- `TripPet/Domain/Models/Ticket.swift`
  - 新增 `animalId: String? = nil`。

- `TripPet/Data/Repositories/AppRepository.swift`
  - `giftTicket` 创建 Ticket 时写入当前动物 id。

- `TripPet/Data/Persistence/UserStatePersistence.swift`
  - `PersistedTicket` 增加 optional `animalId`。
  - 保存和加载时同步 `Ticket.animalId`。
  - 因为是 optional 字段，目标是兼容旧数据。

### 7.3 当前 1.0.8 中仍存在但需要按最新规划调整的改动

当前远端 `1.0.8成就系统` 仍包含早期方案中的这些行为：

- `RootTabView.swift`
  - 第二 Tab 从邮箱替换为成就。
  - Tab 文案为 `成就`。
  - 不显示邮箱 unread badge。

- `PostcardNotificationService.swift`
  - 旧通知 payload `target == "mailbox"` 安全路由到 `.achievements`。

- `RootTabViewTests.swift`
  - 测试中包含“第二 Tab 是成就”的早期预期。

根据用户 2026-06-26 的最新规划，这些内容后续不能直接原样合入 1.0.7，必须重新处理。

## 8. 已做验证

1.0.8 worktree 中最近一次测试命令：

```sh
xcodebuild test -project TripPet.xcodeproj -scheme TripPet -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4.1'
```

结果：

```text
TEST SUCCEEDED
```

已做过模拟器手动验证：

- iPhone 17 模拟器可打开成就 Tab。
- 三入口按钮可切换旅行、脚步、明信片。
- 左右切换小动物可用。
- 分类切换时底图、头像、箭头、按钮区域不再缩放变形。

## 9. 1.0.7 和 1.0.8 的关系

### 9.1 1.0.7 包含的主要内容

1.0.7 相对 1.0.6 包含大量变化：

- 小屋视觉和布局。
- 小屋出行动画。
- 地图页视觉和交互。
- HealthKit 授权和读取修复。
- 通知修复。
- 邮箱和明信片流程修复。
- 明信片详情页正式资源组合。
- 大量目的地、明信片、动画、视频资源。
- 多处测试更新。

### 9.2 1.0.8 包含的主要内容

1.0.8 相对 1.0.6 主要是：

- 成就模型。
- 成就计算服务。
- 小动物成就墙 UI。
- 旅行、脚步、明信片三类统计。
- `Ticket.animalId` 及持久化。
- 成就相关测试。
- 一部分来自 1.0.7 的明信片 edge/motif 资源。
- 早期方案中的“第二 Tab 改成成就”和“旧 mailbox 通知转成就”。

### 9.3 之前的合并风险判断

早期判断中，未来 1.0.8 和 1.0.7 合并风险主要集中在：

- `TripPet.xcodeproj/project.pbxproj`
- `TripPet/App/RootTabView.swift`
- `TripPet/App/PostcardNotificationService.swift`
- `TripPet/Data/Persistence/UserStatePersistence.swift`
- `TripPet/Data/Repositories/AppRepository.swift`
- `TripPet/DesignSystem/AppCopy.swift`
- `TripPet/Domain/Models/Ticket.swift`
- `TripPetTests/RootTabViewTests.swift`

这些风险仍然存在，但最新规划会改变处理方式。

## 10. 用户最新规划

用户最新决定：

1. 1.0.7 之前的邮箱和通知逻辑仍然保留，后续再做优化。
2. 1.0.8 的勋章系统在这个前提下开发和合并，不应该再和 1.0.7 邮箱/通知产生产品逻辑冲突。

技术判断：

- 这个规划是正确的，比早期“第二 Tab 直接替换邮箱”的方案更稳。
- 产品层面，邮箱/通知和成就系统可以拆开：
  - 1.0.7 继续保留邮箱和通知。
  - 1.0.8 作为新增成就模块。
  - 明信片仍可作为成就统计数据来源。
- 但代码层面，当前已推送的 `1.0.8成就系统` 分支仍包含替换邮箱 Tab 和修改 mailbox 通知目标的实现。
- 因此后续不能直接整体 merge 1.0.8 到 1.0.7。

一句话结论：

```text
最新规划在产品上不会和 1.0.7 冲突；但当前 1.0.8 分支代码里仍有早期替换邮箱/通知的改动，合并前必须剔除、改写或选择性移植。
```

## 11. 最新规划下的推荐合并策略

### 11.1 不建议直接做的事

不要直接执行：

```sh
git merge origin/1.0.8成就系统
```

原因：

- 会把“第二 Tab 改成成就”的早期实现带入 1.0.7。
- 会把旧 mailbox 通知路由到 `.achievements` 的早期实现带入 1.0.7。
- 会让 `RootTabViewTests` 的旧预期和新的产品方向冲突。
- 会把产品决策冲突转化成代码冲突。

### 11.2 推荐方式

推荐后续开一个 integration 分支：

```text
基于 1.0.7 目标分支
  -> 新建 integration 分支
      -> 选择性移植 1.0.8 成就模块
      -> 保留 1.0.7 邮箱和通知逻辑
```

可选分支名示例：

```text
1.0.8成就系统-合并1.0.7
```

或按 Codex 默认习惯：

```text
codex/1.0.8-achievements-on-1.0.7
```

### 11.3 应该带入的 1.0.8 内容

建议带入：

- `TripPet/Domain/Models/Achievement.swift`
- `TripPet/Domain/Services/AchievementEngine.swift`
- `TripPet/Features/Achievements/TravelAchievementWallView.swift`
- `TripPetTests/AchievementEngineTests.swift`
- 明信片 edge/motif 资源，如果 1.0.7 当前目标分支还没有。
- `Ticket.animalId: String?`
- `PersistedTicket.animalId`
- `AppRepository.giftTicket` 写入动物 id 的逻辑。
- 成就页所需 copy，但不要覆盖邮箱 copy。

### 11.4 不应该原样带入的 1.0.8 内容

不建议原样带入：

- `RootTabView.swift` 中“第二 Tab 从邮箱改成成就”的逻辑。
- `PostcardNotificationService.swift` 中“旧 mailbox target 落到 achievements”的逻辑。
- `RootTabViewTests.swift` 中“第二 Tab 标题为成就”的测试。
- `AppCopy.swift` 中如果覆盖了邮箱 Tab 文案的部分。

这些内容要根据新规划重新设计。

## 12. 新规划下的成就入口建议

既然 1.0.7 邮箱和通知保留，成就入口不应再抢第二 Tab。

后续可以从以下方案中选一个：

### 方案 A：新增第四个 Tab

优点：

- 成就足够重要，入口清晰。
- 不影响邮箱和通知。

风险：

- 底部 Tab 数量增加，需要重新评估移动端空间和视觉平衡。

### 方案 B：放在小屋页入口

优点：

- 成就和小动物绑定强。
- 用户进入小屋时能自然看到“小动物成就”。

风险：

- 小屋页目前已经承载动画、送票、动物状态，入口太多可能变复杂。

### 方案 C：放在邮箱/明信片相关页面入口

优点：

- 明信片成就和邮箱有关联。
- 不新增底部 Tab。

风险：

- 旅行和脚步成就不完全属于邮箱，入口语义稍弱。

### 方案 D：放在设置或收藏入口下

优点：

- 对主流程影响小。

风险：

- 成就的激励价值会降低，不如直接露出。

当前更推荐：

```text
保留邮箱 Tab，成就作为新增入口接入；具体入口位置后续单独定。
```

不要在合并时顺手做大入口改版，避免把 1.0.7 邮箱/通知稳定性和 1.0.8 成就入口设计绑在一起。

## 13. 合并时需要重点处理的文件

### 13.1 `TripPet.xcodeproj/project.pbxproj`

两边都新增了文件和资源，冲突概率高。

处理原则：

- 保留 1.0.7 所有已有文件和资源引用。
- 加入 1.0.8 的成就模型、服务、视图、测试文件引用。
- 检查 target membership。

### 13.2 `TripPet/App/RootTabView.swift`

最新规划下以 1.0.7 邮箱 Tab 为准。

处理原则：

- 不再把第二 Tab 改成成就。
- 保留邮箱 Tab 和 unread badge 逻辑，除非用户后续明确要求调整。
- 成就入口另行接入，不要让旧 mailbox 通知进入空页面。

### 13.3 `TripPet/App/PostcardNotificationService.swift`

最新规划下以 1.0.7 通知逻辑为准。

处理原则：

- 不把 mailbox target 改到 achievements。
- 保留 1.0.7 的通知投递、授权、跳转修复。
- 如果未来新增 achievement notification target，应作为独立 target 添加，而不是复用 mailbox。

### 13.4 `TripPet/DesignSystem/AppCopy.swift`

处理原则：

- 保留邮箱相关文案。
- 仅新增成就相关文案。
- 不覆盖 `Tabs.mailbox`。

### 13.5 `TripPet/Domain/Models/Ticket.swift`

处理原则：

- 保留 `animalId: String? = nil`。
- 不要改成非 optional。
- 旧数据必须能继续加载。

### 13.6 `TripPet/Data/Persistence/UserStatePersistence.swift`

处理原则：

- 合入 `PersistedTicket.animalId`。
- 保持 optional。
- 合并后必须用已有模拟器 store 启动验证。

### 13.7 `TripPet/Data/Repositories/AppRepository.swift`

处理原则：

- 保留 1.0.7 旅行、明信片、通知、小屋状态逻辑。
- 只补充送票时写入 `Ticket.animalId`。
- 不回退 1.0.7 对小屋/明信片主流程的修复。

### 13.8 `TripPetTests/RootTabViewTests.swift`

处理原则：

- 删除或改写“第二 Tab 是成就”的测试。
- 保留邮箱 Tab 测试。
- 新增成就入口测试时，应根据最终入口位置设计。

## 14. 最新合并后的测试验收清单

自动测试：

- `AchievementEngineTests` 全部通过。
- 邮箱/通知相关测试全部通过。
- RootTab 相关测试按新入口设计更新后通过。
- `Ticket.animalId` 旧数据兼容测试通过。
- 明信片通过 `tripId -> Trip.animalId` 统计测试通过。
- 脚步按动物独立统计测试通过。

手动验收：

- 邮箱 Tab 仍存在。
- 旧通知仍能打开正确邮箱/明信片流程。
- 成就入口可进入小动物成就墙。
- 成就墙默认显示旅行分类。
- 点击 `旅行 / 脚步 / 明信片` 只切换勋章区域。
- 明信片底图、头像、箭头、按钮区域不缩放、不跳动。
- 左右切换小动物后，当前分类保持不变。
- 旅行、脚步、明信片都按当前小动物独立统计。
- 小屋送票后仍正常创建 Trip、Ticket、Postcard。
- HealthKit 授权和读取不回退。
- 地图、小屋动画、出行动画不回退。

## 15. 给后续任务窗口的建议流程

如果只是继续做 1.0.8 成就墙视觉：

1. 进入 `/Users/edy/Documents/TripPet-1.0.8-achievements`。
2. 确认当前分支和远端关系。
3. 不碰 1.0.7 邮箱/通知/Health/地图/小屋主逻辑。
4. 继续完善成就墙 UI 和测试。

如果准备按最新规划和 1.0.7 合并：

1. 从 1.0.7 目标分支开新的 integration 分支。
2. 不要直接 merge 整个 `origin/1.0.8成就系统`。
3. 选择性移植成就模型、服务、视图、测试、资源、`Ticket.animalId`。
4. 保留 1.0.7 邮箱和通知逻辑。
5. 重新决定成就入口，不再默认替换第二 Tab。
6. 更新 RootTab 和通知测试。
7. 跑完整测试。
8. 上模拟器手动验收邮箱、通知、成就、小屋送票、明信片和分类切换。

## 16. 当前不应做的事

- 不要把 1.0.8 当前分支直接 merge 到 1.0.7。
- 不要删除邮箱文件。
- 不要删除邮箱通知 target。
- 不要把 mailbox target 改成 achievements。
- 不要把 `Ticket.animalId` 改成非 optional。
- 不要把 HealthKit、小屋动画、地图页主逻辑和成就合并混在一个不可控大改里。
- 不要在未明确入口方案前重写 RootTab。

## 17. 最终结论

1.0.8 的来龙去脉是：

```text
最早想用成就替换邮箱 Tab
  -> 为避免 1.0.7 未验证改动污染，从 1.0.6 开 1.0.8
  -> 先做旅行勋章墙
  -> 扩展为旅行 / 脚步 / 明信片三入口小动物成就墙
  -> 修复分类切换时底图和 UI 变形
  -> 推送远端 1.0.8成就系统分支
  -> 用户最新决定：1.0.7 邮箱和通知保留，1.0.8 成就作为新增能力合并
```

最新技术结论：

```text
产品方向上，保留 1.0.7 邮箱/通知 + 引入 1.0.8 成就是可行的。
代码合并上，当前 1.0.8 分支不能直接整体合入，因为它还包含早期替换邮箱/通知的实现。
正确做法是基于 1.0.7 新开 integration 分支，选择性移植 1.0.8 成就模块，并保留 1.0.7 邮箱和通知逻辑。
```
