# TripPet 1.0.8 成就系统上下文总结与分支策略

更新时间：2026-06-25  
当前仓库路径：`/Users/edy/Documents/心理`  
当前分支：`1.0.7测试动画效果`  
目标：为“邮箱 Tab 替换为成就系统”独立开启 1.0.8 干净开发线，并避免未验证的 1.0.7 问题污染 1.0.8。

## 1. 项目守则

本仓库有强制项目守则：`.codex/skills/project-guardrails/SKILL.md`。继续工作前必须读取并遵守。

关键约束：

- 不要把无关模块一起改掉。
- Debug 和架构判断要基于证据，不要猜。
- 不要 push、发 PR、上传 GitHub，除非用户明确要求。
- 对可见正式美术资产，应使用图像生成/正式资源，不要用代码硬画正式美术。
- 当前成就网页线框是静态原型，不是正式美术资源，因此使用 CSS 勋章占位是可以的。

## 2. 当前 Git 状态

只读检查结果：

```text
## 1.0.7测试动画效果
 M TripPet/App/RootTabView.swift
 M TripPet/Features/Cabin/CabinView.swift
 M TripPet/Features/Cabin/FullScreenDepartureTransitionView.swift
 M TripPetTests/CabinViewModelTests.swift
?? .codex/
?? AGENTS.md
?? achievement-wireframe.html
```

当前本地分支：

```text
1.0.6文本库                 e3e9ee5 Replace duplicate rabbit text with bear postcard text
1.0.7测试动画效果           381764c Restore real HealthKit authorization on simulator
codex/1.0.7-notifications   381764c Restore real HealthKit authorization on simulator
codex/merge-trippet-1.0.5   e1125c3 Bump TripPet build number for 1.0.5
main                        f5641b8 [behind 2] Add TripPet structured data assets
```

重要结论：

- 当前工作区是脏的，不能直接从这里开 1.0.8。
- `1.0.7测试动画效果`、`origin/1.0.7`、`codex/1.0.7-notifications` 当前都指向 `381764c`。
- `achievement-wireframe.html` 是本轮为成就系统制作的静态网页线框，未跟踪。
- `.codex/`、`AGENTS.md` 是项目/环境指令相关未跟踪内容，不要随便删除。

## 3. 用户对成就系统的核心需求

用户希望把“邮箱 Tab 和逻辑”改成成就系统，但为了避免 1.0.7 未测试问题混入，先单独做静态网页线框和分支规划。

原始需求要点：

- 第 2 个 Tab 从“邮箱”改为“成就系统”。
- 成就系统由 1 个一级页和对应入口点击进入的二级页构成。
- 每个勋章对应 1 个成就。
- 需要做一个能刺激用户持续完成成就的勋章收集页面。
- 邮箱旧逻辑先不一定删除，当前倾向是先替换 Tab 入口，保留明信片数据用于成就统计。

成就分类：

1. 小动物旅行次数成就
2. 用户赠送脚步数成就
3. 小动物明信片收集成就

## 4. 成就统计口径

### 4.1 小动物旅行次数成就

统计方式：

- 每只小动物独立统计旅行次数。
- 数据可从 `repository.trips` 按 `animalId` 分组计算。
- 每只小动物都有 6 档旅行勋章。

档位与文案：

| 阈值 | 标题 | 副标题 |
| --- | --- | --- |
| 1 次 | 穷人乍富 | 初次体验旅游乐趣 |
| 10 次 | 小富即安 | 逐渐变为出行常客 |
| 20 次 | 观光达人 | 认识个有钱朋友可真好 |
| 30 次 | 游玩专家 | 永远享受别人买单的旅行真是惬意 |
| 50 次 | 探险大师 | 我在旅行生涯中一分钱没出过你敢信 |
| 100 次 | 环球旅人 | 我的成就来源于背后有一个贼有实力的大佬 |

### 4.2 用户赠送脚步数成就

统计方式：

- 全局累加 `repository.tickets.map(\.sourceSteps)`。
- 首张免费机票如果 `sourceSteps == 0`，不增加累计脚步。
- 当前线框示例值：`42,600 / 50,000`。

档位按数值从小到大：

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

### 4.3 小动物明信片收集成就

统计方式：

- 每只小动物独立统计明信片数量。
- `Postcard` 自身有 `tripId`，需通过 `postcard.tripId -> Trip -> animalId` 关联回小动物。
- 每只小动物 9 档。

档位与文案：

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

## 5. 当前 HTML 线框结果

文件：`achievement-wireframe.html`

用途：

- 纯 HTML/CSS 静态网页线框。
- 不接入 Swift。
- 不改现有 `index.html`。
- 不影响 App 运行。
- 目前是未跟踪文件。

网页包含 4 个手机画布：

1. 成就一级页
2. 旅行次数成就详情页
3. 赠送脚步成就详情页
4. 明信片收集成就详情页

经过多轮优化后，重点修改的是“旅行勋章墙”：

- 旅行详情页不再拆成两个卡片。
- 改为一张融合式大卡。
- 大卡复用现有明信片底图：`TripPet/Resources/Assets.xcassets/Postcards/postcard_base_16x9.imageset/postcard_base_16x9@3x.png`
- 卡片内包含：
  - 返回按钮在卡片外顶部
  - 标题：`旅行勋章墙`
  - 当前小动物展示模块
  - 小动物头像：当前引用 `animal_home_xiaoman_hamster@3x.png`
  - 左右切换箭头：复用地图资源 `map_scroll_arrow_left/right`
  - 当前进度：`12 / 20`
  - 单条进度条
  - 6 枚旅行勋章
- 勋章显示结构：
  - 阈值，例如 `1次`
  - 标题，例如 `穷人乍富`
  - 副标题，例如 `初次体验旅游乐趣`
  - 数值，例如 `1 / 1`
- 已按用户要求删除：
  - `Health 已连接`
  - `18枚已亮起`
  - 旅行入口底部解释文案
  - 旅行详情顶部 `成就详情`
  - `小动物独立` 胶囊
  - 旧的动物切换胶囊
  - 旅行详情中独立的“勋章区标题说明”卡片
  - `完成后进入...` 说明

### 5.1 旅行入口“已收集 3 / 18”的含义

首页旅行入口不显示当前动物的 `12 / 20`，而显示分类总收集：

```text
已收集旅行勋章数 / 所有可收集旅行勋章数
```

当前示例：

```text
小满 2 枚 + 糖圆 1 枚 + 墨迹 0 枚 = 3
3 只小动物 * 6 档 = 18
所以显示：已收集 3 / 18
```

注意：真实 App 中动物数量可能是 9 只，则总数应为 `动物数 * 6`。

## 6. 1.0.6 和 1.0.7 的对比结果

对比范围：

```text
1.0.6文本库 (e3e9ee5)
到
1.0.7测试动画效果 / origin/1.0.7 (381764c)
```

不包含当前未提交工作区。

1.0.7 相对 1.0.6 多 9 个提交：

```text
381764c Restore real HealthKit authorization on simulator
9c3a90e Cover 1.0.7 release fixes with tests
1f2d31b Refine 1.0.7 cabin and globe layouts
6caa259 Fix 1.0.7 Health notification and mailbox flows
f16c07a Add 1.0.7 transition and map art assets
159dadc Update 1.0.7 globe cabin and HealthKit fixes
08e1b15 Integrate 1.0.7 visual updates
9cc780f Fix notification launch and map tab stability
94d1ffb Finalize TripPet 1.0.7 assets and postcard text
```

总差异：

```text
183 files changed, 6506 insertions(+), 794 deletions(-)
```

### 6.1 主要变化组

#### 小屋/动画/转场

涉及：

- `TripPet/Features/Cabin/CabinSceneView.swift`
- `TripPet/Features/Cabin/CabinView.swift`
- `TripPet/Features/Cabin/CabinViewModel.swift`
- `TripPet/Features/Cabin/FullScreenDepartureTransitionView.swift`
- `TripPet/Resources/AnimalAnimations/*.gif`
- `TripPet/Resources/DepartureTransitions/*.mp4`

风险：

- 改动量大。
- 用户仍在测试 1.0.7，这部分可能还不稳定。
- 不建议 1.0.8 直接继承。

#### 地图页

涉及：

- `TripPet/Features/Map/WorldMapView.swift`
- `TripPet/Resources/Assets.xcassets/WorldMap/map_journal_night_sky_final.imageset`
- `TripPet/Resources/Assets.xcassets/WorldMap/world_travel_map.imageset/world_travel_map@3x.png`

风险：

- `WorldMapView.swift` 是最大改动文件之一。
- 1.0.8 成就系统只需要左右箭头资源，而这些箭头资源已存在，不必继承整套地图改动。

#### 通知 / 邮箱 / Health

涉及：

- `TripPet/App/AppEnvironment.swift`
- `TripPet/App/PostcardNotificationService.swift`
- `TripPet/App/PostcardNotificationDiagnostics.swift`
- `TripPet/App/RootTabView.swift`
- `TripPet/Features/Mailbox/MailboxViewModel.swift`
- `TripPet/Features/Mailbox/PostcardDetailView.swift`
- `TripPet/Domain/Services/HealthKitStepCountProvider.swift`

风险：

- 与“第二 Tab 从邮箱改成成就”有交叉。
- 1.0.7 仍有未测试问题时，直接继承会污染 1.0.8。
- 1.0.8 初期应避免整包合入通知/邮箱改动。

#### 明信片资源 / 文本扩展

涉及：

- `TripPet/Domain/Services/PostcardTextLibrary.swift`
- 大量 `TripPet/Resources/Assets.xcassets/Destinations/*`
- 大量 `TripPet/Resources/Assets.xcassets/Postcards/*`
- `Tools/import_imagegen_postcard_artwork.py`
- `Tools/generate_postcard_text_library.py`

风险：

- 资源量很大。
- 成就系统统计不依赖这些新资源。
- 可后续按需单独引入。

#### 设置页与测试

涉及：

- `TripPet/Features/Settings/SettingsView.swift`
- `TripPetTests/AppRepositoryTripTests.swift`
- `TripPetTests/CabinViewModelTests.swift`
- `TripPetTests/RootTabViewTests.swift`
- `TripPetTests/TicketRuleEngineTests.swift`

建议：

- 1.0.8 应为成就系统新写聚焦测试。
- 不要直接把 1.0.7 的测试整包搬入，避免带入未验证行为假设。

## 7. 分支策略建议

### 7.1 为什么不要从当前 1.0.7 开 1.0.8

当前 1.0.7 包含大量未完全验证的改动：

- 小屋布局
- 全屏出行动画
- 地图页大改
- 通知/Health 修复
- 邮箱流程改动
- 大量资源与视频

如果从 1.0.7 直接开 1.0.8，成就系统问题会和 1.0.7 已有问题混在一起，后续定位很困难。

### 7.2 推荐路线

推荐从 `1.0.6文本库` 开 1.0.8：

```text
1.0.6文本库
  -> codex/1.0.8-achievements
       只做成就系统
       只引入必要资源
       不合并 1.0.7 整包
```

### 7.3 可能的合并风险

从 1.0.6 开 1.0.8，未来和稳定后的 1.0.7 合并时，可能出现冲突，但不是不能合并。

主要冲突风险：

- `RootTabView.swift`：1.0.7 改 Tab / map / mailbox；1.0.8 要改第二 Tab 为成就。
- `AppEnvironment.swift`：1.0.7 改通知、明信片投递、Health；1.0.8 可能读取成就统计。
- `AppRepository.swift`：1.0.7 改旅行、明信片、持久化；1.0.8 可能新增统计方法。
- `TripPet.xcodeproj/project.pbxproj`：1.0.7 加大量资源；1.0.8 若加勋章资源也会冲突。
- `SettingsView.swift`：1.0.7 改设置/收藏；1.0.8 后续如移动明信片收藏入口可能冲突。

降低风险的原则：

- 1.0.8 成就计算尽量放新文件。
- 1.0.8 UI 尽量放新 feature 目录。
- 共享文件只做最小改动。
- 每个逻辑点单独提交，便于以后 cherry-pick。

## 8. 如何开 1.0.8 新分支

### 8.1 重要前提

当前工作区是脏的。开分支前必须处理这些未提交内容：

```text
 M TripPet/App/RootTabView.swift
 M TripPet/Features/Cabin/CabinView.swift
 M TripPet/Features/Cabin/FullScreenDepartureTransitionView.swift
 M TripPetTests/CabinViewModelTests.swift
?? .codex/
?? AGENTS.md
?? achievement-wireframe.html
```

不要直接切分支，否则这些改动会跟着工作区进入新分支，污染 1.0.8。

### 8.2 推荐做法 A：保留当前 1.0.7 未提交工作，用 stash

适合：用户还没测试完 1.0.7，需要把当前工作区完整保留。

命令：

```bash
git stash push -u -m "wip-1.0.7-before-1.0.8-achievements"
git switch 1.0.6文本库
git switch -c codex/1.0.8-achievements
```

说明：

- `-u` 会把未跟踪的 `achievement-wireframe.html`、`.codex/`、`AGENTS.md` 一起 stash。
- 之后如果要回到 1.0.7 继续测试：

```bash
git switch 1.0.7测试动画效果
git stash list
git stash pop stash@{对应编号}
```

风险：

- stash pop 可能有冲突，但这是最完整保留当前工作区的方法。

### 8.3 推荐做法 B：只把网页线框单独备份，其他 1.0.7 改动继续留在当前分支

适合：想马上开干净 1.0.8，但不想把所有未提交内容混进去。

可先把 `achievement-wireframe.html` 复制到安全位置或提交到专门原型分支。由于用户没有要求提交，这里不自动执行。

如果由另一个任务窗口继续，建议先询问用户采用 stash 还是先提交线框。

### 8.4 推荐做法 C：用 git worktree 开独立工作树

这是最干净的方式，适合同时保留当前 1.0.7 工作区和开启 1.0.8。

示例：

```bash
git worktree add ../TripPet-1.0.8-achievements 1.0.6文本库
cd ../TripPet-1.0.8-achievements
git switch -c codex/1.0.8-achievements
```

优点：

- 当前目录的 1.0.7 脏工作区不动。
- 新目录从 `1.0.6文本库` 干净开始。
- 两条线可以并行。

注意：

- 路径 `../TripPet-1.0.8-achievements` 在当前仓库外，执行可能需要写权限确认。
- 如果要在本 Codex 环境执行，应先获得用户明确同意。

## 9. 1.0.8 实施建议

### 9.1 推荐目录结构

新建或使用类似结构：

```text
TripPet/Domain/Models/Achievement.swift
TripPet/Domain/Services/AchievementEngine.swift
TripPet/Features/Achievements/AchievementsView.swift
TripPet/Features/Achievements/AchievementDetailView.swift
TripPet/Features/Achievements/AchievementMedalView.swift
TripPetTests/AchievementEngineTests.swift
```

如果项目没有严格 feature 目录规范，也可以按现有风格调整，但原则是：成就逻辑尽量自成模块。

### 9.2 共享文件最小修改

预计必须修改：

- `TripPet/App/RootTabView.swift`
  - 第二 Tab 从 `.mailbox` 改成 `.achievements` 或等价命名。
  - UI 文案从“邮箱”改“成就”。
  - 图标改为成就/勋章图标。
  - 移除邮箱未读 badge 在 Tab 上的展示。

可能修改：

- `TripPet/App/PostcardNotificationService.swift`
  - 如果 1.0.6 已经有通知跳邮箱逻辑，需要兼容旧 payload。
  - 建议初期不要重做通知，只保证编译和现有行为不崩。
- `TripPet/DesignSystem/AppCopy.swift`
  - 新增 `Tabs.achievements`
  - 新增成就文案。
- `TripPet.xcodeproj/project.pbxproj`
  - 新增 Swift 文件和资源时会自动/手动更新。

不建议初期修改：

- 邮箱详情和明信片生成主循环。
- HealthKit 逻辑。
- 小屋出行动效。
- 地图页大逻辑。

### 9.3 成就计算接口建议

应以纯函数或轻量 service 形式实现，方便测试：

```swift
struct AchievementEngine {
    func travelProgress(animals: [Animal], trips: [Trip]) -> [AnimalAchievementProgress]
    func giftedStepsProgress(tickets: [Ticket]) -> AchievementTrackProgress
    func postcardProgress(animals: [Animal], trips: [Trip], postcards: [Postcard]) -> [AnimalAchievementProgress]
}
```

不要把成就计算直接写在 SwiftUI View 中。

### 9.4 UI 重点

一级页：

- 标题：成就
- 最近目标卡
- 三个入口：
  - 旅行勋章墙
  - 脚步勋章墙
  - 明信片勋章墙
- 每个入口显示当前最近目标和进度条。

旅行详情页：

- 采用当前 HTML 线框的融合式大卡。
- 顶部放当前小动物头像。
- 左右箭头切换小动物。
- 进度条只指向当前小动物的下一个旅行勋章。
- 下方同卡内展示 6 枚旅行勋章。
- 勋章显示标题、副标题、阈值和当前数值。

脚步详情页：

- 全局一组 14 枚勋章。
- 顶部单进度条指向下一个脚步阈值。

明信片详情页：

- 类似旅行详情，但阈值是明信片张数。
- 每只小动物独立统计。

## 10. 1.0.7 与 1.0.8 后续合并策略

不要把未验证的 1.0.7 整包 merge 到 1.0.8。

推荐流程：

```text
1.0.7测试动画效果
  -> 继续测试、修复
  -> 得到稳定 1.0.7 分支

codex/1.0.8-achievements
  -> 从 1.0.6文本库干净开发成就
  -> 小提交、模块化

integration/1.0.8-with-1.0.7
  -> 试合并稳定 1.0.7 + 1.0.8
  -> 解决冲突
  -> 跑测试和人工验收
```

如果合并冲突太大，反向操作：

```text
从稳定后的 1.0.7 开 integration 分支
cherry-pick 1.0.8 的成就提交
```

因此 1.0.8 每次提交要小而清晰：

1. 成就模型/定义
2. 成就计算器
3. 成就 UI
4. Tab 替换
5. 测试
6. 资源

这样未来 cherry-pick 才容易。

## 11. 推荐给下一个任务窗口的执行步骤

### 第一步：确认用户希望如何处理当前脏工作区

需要问用户或按用户明确指令执行：

- 是否允许 stash 当前所有未提交内容？
- 是否要用 worktree 另开干净目录？
- 是否要保留/迁移 `achievement-wireframe.html`？

推荐优先级：

1. 最推荐：`git worktree` 开干净 1.0.8，不动当前 1.0.7 目录。
2. 次推荐：stash 当前工作区，然后从 `1.0.6文本库` 开分支。
3. 不推荐：在当前脏工作区直接切到 `1.0.6文本库` 开分支。

### 第二步：开 1.0.8 分支

如果用户允许 worktree：

```bash
git worktree add ../TripPet-1.0.8-achievements 1.0.6文本库
cd ../TripPet-1.0.8-achievements
git switch -c codex/1.0.8-achievements
```

如果用户允许 stash：

```bash
git stash push -u -m "wip-1.0.7-before-1.0.8-achievements"
git switch 1.0.6文本库
git switch -c codex/1.0.8-achievements
```

### 第三步：先不要合入 1.0.7

从 1.0.6 直接实现最小成就系统。

只按需参考：

- `achievement-wireframe.html`
- 现有模型：`Animal`、`Trip`、`Ticket`、`Postcard`
- 现有 Tab 结构：`RootTabView`

### 第四步：实现顺序

建议顺序：

1. 新增成就定义和计算器。
2. 写 `AchievementEngineTests`。
3. 新增成就一级页。
4. 新增旅行详情页。
5. 接入 Tab。
6. 再做脚步和明信片详情页。
7. 最后处理图标/正式勋章资源。

### 第五步：验收

最少测试：

- 编译通过。
- 成就计算单元测试通过。
- 空数据时不崩。
- 有 trips/tickets/postcards 时统计正确。
- 第二 Tab 显示成就页。
- 邮箱旧逻辑未被误删导致编译错误。

人工验收：

- 一级页能看到三个入口。
- 旅行详情页能看到单只小动物融合式展示。
- 左右箭头位置在页面中部。
- 勋章标题和副标题都显示。
- 数字一行显示完毕。

## 12. 本文档生成说明

本文档只总结上下文、分析和建议。

本轮未执行：

- 未切分支
- 未提交
- 未 push
- 未删除文件
- 未合并 1.0.7

本轮只新增本文档。
