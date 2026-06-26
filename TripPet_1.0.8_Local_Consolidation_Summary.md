# TripPet 1.0.8 本地改动收束

## 基线

当前本地分支：`1.0.7测试动画效果`。

本次收束覆盖 2026-06-26 本地可见改动。按要求，仍在执行中的「规范勋章美术并修复箭头」任务不做文件改动，只在本文中标记边界。

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
