# TripPet 1.0.2 明信片系统测试文档

更新时间：2026-06-10  
适用版本：TripPet 1.0.2 Postcard MVP  
项目路径：`/Users/edy/Documents/心理/TripPet`

## 1. 测试目标与版本边界

### 1.1 测试目标

1.0.2 的测试目标是验证“明信片系统 MVP 完整闭环”，而不是验证大规模内容量或长期扩展系统。

本轮验收必须确认：

- 用户可以把当前小屋里的可旅行动物送出旅行。
- 送出旅行时会生成确定的 `postcardPlan`。
- 到期后邮箱能按计划投递明信片。
- 明信片详情使用 1.0.2 大风景模板展示地点，而不是动物自拍。
- 明信片标题、正文、关系记忆体现动物感。
- 已读、未读、收藏、旅行完成、关系记忆都能正确保存。
- 旧明信片和旧本地数据不会因为 1.0.2 新字段崩溃。

### 1.2 版本硬约束

1.0.2 只验收以下范围：

- 动物：`cat` 墨迹、`dog` 汤圆、`rabbit` 灯灯。
- 目的地：`fr_paris` 巴黎、`is_reykjavik` 雷克雅未克、`pt_lisbon` 里斯本。
- 模板：只使用 `postcard_template_landscape_v102` 作为 1.0.2 默认明信片模板。
- 叙事：本地确定性 `PostcardNarrativeEngine`，不联网，不访问服务端，不运行时编造地点事实。
- 调度：短途 1 张，标准 1 张，长途 2 张；一次旅行最多 2 张明信片。
- UI：邮箱投递反馈、未读优先、Tab badge、详情大风景布局、打开标记已读、收藏页沿用已读明信片。

### 1.3 本轮不测范围

以下能力不属于 1.0.2 验收范围，不能因为未实现而阻塞发布：

- 多套明信片模板。
- 动物自拍姿势或动物视觉贴纸。
- 贴纸系统、纪念物系统、Lottie 或复杂转场帧。
- 联网生成、服务端生成、在线模型润色。
- 国内城市、美国城市、其他东亚城市。
- 系统通知真实调度。
- 新伙伴点击解锁和长期伙伴收藏系统。

## 2. 需求偏离防线

这一节用于防止 1.0.2 实现偏离最初需求。任何一项失败，都需要优先修复或记录为发布阻塞风险。

### 2.1 用户可见命名

测试点：

- App 内用户可见文本必须统一为“汤圆”。
- 项目中不应再出现用户可见的“糖圆”。
- 明信片标题示例必须为“汤圆寄来的里斯本明信片”，不是“糖圆寄来的里斯本明信片”。

建议检查：

```bash
rg -n "糖圆" /Users/edy/Documents/心理/TripPet
rg -n "汤圆" /Users/edy/Documents/心理/TripPet/TripPet
```

通过标准：

- `糖圆` 无命中，或仅命中历史讨论/非产品文档且明确不会进入 App。
- `ContentManifest.json`、`SeedData.swift`、测试断言和生成标题均使用“汤圆”。

### 2.2 首发目的地

测试点：

- manifest 首发目的地只能包含巴黎、雷克雅未克、里斯本。
- 不出现上海、中国城市、美国城市、其他东亚城市作为 1.0.2 可旅行目的地。
- 里斯本资源完整接入：风景、邮戳、路线图。

通过标准：

- `ContentManifest.json` 中目的地为 `fr_paris`、`is_reykjavik`、`pt_lisbon`。
- 三个目的地都有 `cityId`、`travelKind`、`postcardTemplateAssetName`、`scenes`。
- 里斯本引用 `destination_lisbon_line`、`stamp_lisbon`、`trip_route_map_lisbon`。

### 2.3 明信片视觉原则

测试点：

- 1.0.2 明信片详情不得展示小动物自拍。
- `PostcardDetailView` 不渲染 `postcard.animalAssetName`。
- 明信片文字必须由 SwiftUI 渲染，不能烘焙进 PNG。
- 风景图必须成为明信片第一视觉，邮戳不能压住正文。

通过标准：

- 详情页视觉层级为 template、destination、stamp、SwiftUI 文本。
- 图片资源中不包含正文、日期、目的地标题等可变文案。
- 旧字段 `animalAssetName` 只保留兼容，不参与 1.0.2 详情展示。

### 2.4 动物感表达原则

测试点：

- 动物感来自标题、正文、动物 profile、反应线、关系记忆。
- 不能依赖“动物自拍”来证明是谁寄来的。
- 墨迹、汤圆、灯灯的语气和动作倾向应能在正文中被区分。

通过标准：

- 标题包含动物名。
- `PostcardNarrativeEngine` 使用 `profileId` 查找动物 profile。
- 正文能体现 profile 中的 `motifs`、`reactionLines` 或 `relationshipLines`。

### 2.5 地点真实感原则

测试点：

- 明信片不能写成景点打卡介绍。
- 每张卡必须能回溯到城市、场景、核心物件、核心动作。
- 不能临时编造 manifest 之外的具体地点事实。

通过标准：

- 正文只使用 manifest scenes 中的 `sensoryDetails`、`localObjects`、`availableActions`，以及动物 profile 文案。
- 核心物件至少参与一次动作。
- 删除核心物件或核心动作后，结尾不应仍然完全成立。

## 3. 测试点清单

### 3.1 内容与 Manifest

覆盖文件：

- `TripPet/Resources/ContentManifest.json`
- `TripPet/Data/Manifest/ContentManifest.swift`
- `TripPet/Data/Manifest/ContentManifestLoader.swift`

测试点：

- JSON 可以被解析。
- `ContentManifest` 支持 `narrative`。
- `ManifestAnimal` 支持 `profileId`、`canTravel`、`displayRoleType`。
- `ManifestDestination` 支持 `cityId`、`postcardTemplateAssetName`、`travelKind`、`scenes`。
- `ManifestPostcard` 支持 1.0.2 metadata。
- `ContentManifestLoader.loadNarrative()` 能返回 narrative。
- 三只首发动物都 `canTravel == true`。
- `visitor_unknown` 如果存在，应不可旅行，且不进入派行轮换。
- 三个目的地每个至少 6 个 scenes。
- 每个 scene 包含 `sceneId`、`sceneName`、`sceneType`、`sensoryDetails`、`localObjects`、`availableActions`、`postcardTypes`、`microArcFits`、`animalAffinity`、`avoidWriting`。
- narrative profiles 包含 `moji_cat`、`tangyuan_puppy`、`dengdeng_rabbit`。
- narrative templates 覆盖当前调度会用到的 `daily_observation`、`personality_reaction`、`motif_echo`。

通过标准：

- JSON lint 通过。
- manifest decode 测试通过。
- 所有 manifest 引用的 asset name 都能在 `Assets.xcassets` 找到对应 `.imageset`。

### 3.2 美术资源

覆盖路径：

- `TripPet/Resources/ArtSourceRaster/Postcards/`
- `TripPet/Resources/ArtSourceRaster/Destinations/`
- `TripPet/Resources/ArtSourceRaster/Stamps/`
- `TripPet/Resources/Assets.xcassets/`

测试点：

- 新增源图存在：
  - `postcard_template_landscape_v102.png`
  - `destination_lisbon_line.png`
  - `stamp_lisbon.png`
  - `trip_route_map_lisbon.png`
- 对应 imageset 存在且 `Contents.json` 指向 `@3x.png`。
- PNG 命名与 manifest 引用完全一致。
- 明信片模板不烘焙正文、日期、标题、动物名。
- 风景图适合大面积展示，不能被模板装饰压缩成小角落。
- 邮戳透明或低干扰，叠在明信片和信封上不影响 SwiftUI 文本阅读。
- route map 能用于旅行状态卡，不错误复用巴黎或冰岛路线图。

手工视觉验收：

- 巴黎、雷克雅未克、里斯本第一眼可区分。
- 里斯本视觉应与巴黎、雷克雅未克形成差异：坡道、旧街、白墙、浅陶土、海风感。
- 1.0.2 默认卡面明显比旧 `postcard_template_classic` 更强调地点风景。

### 3.3 数据模型

覆盖文件：

- `TripPet/Domain/Models/Animal.swift`
- `TripPet/Domain/Models/Trip.swift`
- `TripPet/Domain/Models/Postcard.swift`
- `TripPet/Domain/Models/AnimalRelationshipMemory.swift`

测试点：

- `Animal` 包含 `profileId`、`canTravel`、`displayRoleType`，且旧初始化点有默认值。
- `Trip` 包含 `travelKind`、`postcardPlan`、`revealedPostcardCount`、`completedAt`。
- `TripPostcardPlanItem` 可 Codable round-trip。
- `Postcard` 包含 1.0.2 metadata：`animalId`、`profileId`、`cityId`、`sceneId`、`postcardType`、`microArc`、`emotionalWeight`、`revealBudget`、`relationshipStageAtSend`。
- `AnimalRelationshipMemory` 可 Codable round-trip。
- 旧 postcard 缺少新 metadata 时能使用默认值展示。

通过标准：

- 所有旧测试仍能编译。
- 旧构造器调用不因新增字段破裂。
- 新 metadata 在生成 1.0.2 postcard 时完整填入。

### 3.4 调度规则

覆盖文件：

- `TripPet/Domain/Services/PostcardScheduler.swift`

测试点：

- `short` 生成 1 张计划：
  - `dueAt = departedAt + 1 天`
  - `postcardType = daily_observation`
  - `plannedEmotionalWeight = 0`
- `standard` 生成 1 张计划：
  - `dueAt = departedAt + 2 天`
  - `postcardType = personality_reaction`
  - `plannedEmotionalWeight = 1`
- `long` 生成 2 张计划：
  - 第 1 张 `dueAt = departedAt + 2 天`
  - 第 2 张 `dueAt = departedAt + 4 天`
  - 两张尽量不同 `sceneId`
  - 两张不同 `postcardType`
  - 两张不同 `preferredMicroArc`
- `travelKind` 缺失或未知时 fallback 到 `.standard`。
- 一次旅行不能生成 3 张或更多明信片。

现有覆盖：

- `testPostcardPlanCountsByTravelKind`

建议补充：

- 对 `dueAt` 进行精确断言。
- 对未知 `travelKind` fallback 到 standard 进行断言。
- 对 scenes 为空时仍能生成 fallback plan 进行断言。

### 3.5 叙事引擎

覆盖文件：

- `TripPet/Domain/Services/PostcardNarrativeEngine.swift`

测试点：

- 同一 trip、planItem、animal、destination、memory、date 输入下，生成文本稳定。
- 不使用 Swift `String.hashValue` 做跨进程稳定选择。
- `stableHash` 逻辑不会随 App 重启改变选择结果。
- scene 选择优先使用 planItem.sceneId，且避开 `memory.recentSceneIds`。
- motif 选择避开 `memory.recentlyUsedMotifs`。
- `emotionalWeight` 不超过 template 的 `maxEmotionalWeight`。
- `revealBudget` 来自 template，缺失时有兜底。
- 标题格式为 `动物名 + 寄来的 + 目的地名 + 明信片`。
- dog 标题必须为“汤圆寄来的里斯本明信片”。
- subtitle 第 1 张为“旅途中寄来”，第 2 张为“第二封来信”。
- postcard metadata 完整填入。
- 不联网、不服务端、不读取 manifest 以外的事实来源。

现有覆盖：

- `testV102GeneratedPostcardUsesLandscapeTemplateWithoutVisualAnimalDependency`

建议补充：

- `PostcardNarrativeEngine` 稳定性测试。
- `emotionalWeight` 被 template 上限截断的测试。
- recent scene 冷却测试。
- narrative 缺失时 fallback 仍生成可展示 postcard 的测试。

### 3.6 Repository 业务闭环

覆盖文件：

- `TripPet/Data/Repositories/AppRepository.swift`

测试点：

- 当前小屋动物按可旅行动物轮换：cat -> dog -> rabbit。
- 一天最多派出 3 只动物。
- 达到每日上限后小屋保持空。
- 第二天重置 dispatchedCount，并从 cat 重新开始。
- 当前小屋动物是谁，就优先使用它自己的 active wish。
- 没有 active wish 时，从 manifest destinations 为该动物创建下一个 wish。
- `giftTicket` 创建 ticket、trip、postcardPlan。
- `giftTicket` 根据 plan 最后一张 dueAt 设置 `expectedReturnAt`。
- `giftTicket` 写入 `travelKind`、`postcardPlan`、`revealedPostcardCount = 0`。
- 送出旅行后 wish 状态变为 `.traveling`。
- 送出旅行后 relationship memory 更新 `tripCount`、`visitedCityIds`、`relationshipStage`。
- `revealEligiblePostcards` 对 plan 为空的旧 trip 走旧 fallback 逻辑。
- `revealEligiblePostcards` 对 plan 非空的新 trip 按 sequence 投递。
- 同一 sequence 不重复投递。
- long trip 第 1 张投递后 trip 仍 `.traveling`。
- long trip 第 2 张投递后 trip `.completed`，wish `.completed`。

现有覆盖：

- `testCabinLodgingRotatesToNextTravelAnimal`
- `testCabinStopsAfterThreeDeparturesAndResetsNextDay`
- `testLongTripCompletesOnlyAfterSecondPostcardReveal`
- `testEligibleTripRevealsPostcardOnlyOnce`

建议补充：

- dog/rabbit 分别创建自己的 active wish。
- `expectedReturnAt == plan.last.dueAt`。
- `revealEligiblePostcards` 未到期时不投递。
- 同一到期时间重复调用不重复插卡。

### 3.7 关系记忆

覆盖文件：

- `TripPet/Domain/Models/AnimalRelationshipMemory.swift`
- `TripPet/Data/Repositories/AppRepository.swift`
- `TripPet/Data/Persistence/UserStatePersistence.swift`

测试点：

- 初始 relationship memory 对三只可旅行动物存在。
- resident cat 初始 `encounterCount` 可以为 1。
- dog/rabbit 初始 memory 不应缺失。
- 送出旅行后：
  - `encounterCount` 至少为 1。
  - `tripCount += 1`。
  - `visitedCityIds` 记录 cityId。
  - `relationshipStage` 按规则推进。
- 投递明信片后：
  - `sentPostcardIds` 追加 postcard id。
  - `recentSceneIds` 追加 sceneId，最多保留 8 个。
  - `recentlyUsedMotifs` 追加当前记录，最多保留 8 个。
- 当前实现里 `recentlyUsedMotifs` 写入的是 `postcard.microArc`，这属于 MVP 简化风险，应在文档中保留风险记录。
- 收藏页当前沿用已读展示，不要求 `favoritedPostcardIds` 完整联动。

建议补充：

- relationship memory SwiftData round-trip。
- 连续投递超过 8 张时 recent arrays 截断到 8。
- `visitedCityIds` 不重复追加。

### 3.8 持久化与迁移

覆盖文件：

- `TripPet/Data/Persistence/UserStatePersistence.swift`

测试点：

- `PersistedTrip` 新增字段为 optional：
  - `travelKindRawValue`
  - `postcardPlanJSON`
  - `revealedPostcardCount`
  - `completedAt`
- `PersistedPostcard` 新增 metadata 字段为 optional。
- 旧 trip 缺少 `travelKindRawValue` 时恢复为 `.standard`。
- 旧 trip 缺少或无法 decode `postcardPlanJSON` 时恢复为 `[]`。
- 旧 trip 缺少 `revealedPostcardCount` 时恢复为 `0`。
- 旧 postcard 缺少 metadata 时使用兼容默认值。
- `PersistedAnimalRelationshipMemory` 可保存与读取。
- `SwiftDataUserStateStore(inMemory: true)` 能跨 repository 实例保存 tickets、trips、postcards、read state、flags。
- 空邮箱不应自动 hydrate seed postcards。

现有覆盖：

- `testSwiftDataStorePersistsRepositoryStateAcrossRepositoryInstances`
- `testSwiftDataStoreDoesNotHydrateSeedPostcardsForEmptyMailbox`

发布前必做：

- 使用真实 1.0.1 设备数据库升级到 1.0.2。
- 检查旧 tickets、trips、postcards、wishes、flags 是否可加载。
- 检查旧明信片详情仍可打开，且旧 title “小猫寄来的自拍” 显示为“小猫寄来的明信片”。

### 3.9 Mailbox UI

覆盖文件：

- `TripPet/Features/Mailbox/MailboxView.swift`
- `TripPet/Features/Mailbox/MailboxViewModel.swift`
- `TripPet/App/RootTabView.swift`

测试点：

- 进入邮箱页时调用 `revealEligiblePostcards`。
- 有新明信片投递时显示 banner：“新的明信片已经送到邮箱”。
- 未读明信片排序在已读明信片前。
- 同一已读状态下按 `sentAt` 倒序排序。
- 未读信封使用 `envelope_unread`。
- 已读信封使用 `envelope_read`。
- 点击信封打开全屏详情。
- 打开明信片后调用 `markPostcardRead`。
- Root Tab 邮箱 badge 显示未读数量。
- badge 在打开明信片后减少。
- 空邮箱显示温柔空状态，不出现技术错误文案。

手工验收：

- 空邮箱。
- 一封未读。
- 一封已读。
- 多封混合时未读优先。
- long trip 第一封、第二封投递后排序正确。

### 3.10 明信片详情 UI

覆盖文件：

- `TripPet/Features/Mailbox/PostcardDetailView.swift`

测试点：

- 详情页全屏覆盖底部 Tab。
- 返回按钮可用，accessibility label 为“返回邮箱”。
- 背景为 `PaperBackground`。
- 主体 `PostcardArtwork` 为 16:9 横版。
- `templateAssetName` 作为底图。
- `destinationAssetName` 大面积放在上方或中上部。
- `stampAssetName` 弱化放在角落，不能遮挡正文。
- SwiftUI 渲染：
  - `destination`
  - `subtitle`
  - `sentAt`
  - `title`
  - `body`
- 不渲染 `animalAssetName`。
- `displayTitle` 将旧标题“小猫寄来的自拍”显示为“小猫寄来的明信片”。
- `accessibilityLabel` 包含 title、destination、subtitle、body。

小屏与字体验收：

- iPhone SE 或等效小屏下正文不严重溢出。
- Dynamic Type 放大后 title 和 body 不互相遮挡。
- body `lineLimit(5)` 不应截断到失去主要信息。
- 邮戳不压正文。
- 风景仍是第一视觉。

### 3.11 收藏页与设置页

覆盖文件：

- `TripPet/Features/Settings/SettingsView.swift`

测试点：

- 收藏页入口可点击。
- 收藏页当前展示已读 postcards。
- 未读 postcards 不进入收藏页列表。
- 已读 postcards 显示 stamp、title、destination、subtitle。
- 空收藏页显示 `settings_collection_empty`，不出现技术错误。
- 收藏页不要求 1.0.2 实现独立 favorite toggle。

### 3.12 可访问性

测试点：

- VoiceOver 能完成邮箱列表 -> 打开明信片 -> 返回邮箱。
- 信封 accessibility label 包含来源目的地和标题。
- 明信片详情 accessibility label 能读出标题、目的地、subtitle、正文。
- 返回按钮读法清晰。
- Dynamic Type 下主要文字不严重溢出。
- Reduce Motion 开启时信封 hover/press 动效不造成额外问题。
- 装饰图不应抢占过多 VoiceOver 焦点。

发布前必做：

- 在真机或模拟器手工跑 VoiceOver。
- 至少检查默认字号、大字号、超大字号。

### 3.13 工程文件

覆盖文件：

- `TripPet.xcodeproj/project.pbxproj`
- `TripPet/Resources/Assets.xcassets`
- `TripPetTests/AppRepositoryTripTests.swift`

测试点：

- 新增 Swift 文件已加入 Xcode project：
  - `TripPet/Domain/Models/AnimalRelationshipMemory.swift`
  - `TripPet/Domain/Services/PostcardNarrativeEngine.swift`
- project pbxproj lint 通过。
- 新增 assets 的 `.imageset/Contents.json` 合法。
- iPhone Simulator tests 通过。
- iPhoneOS Debug build 通过。
- 不要求 Release 签名通过，但发布前应另跑真机签名包。

## 4. 自动化测试与验证命令

以下命令从项目根目录 `/Users/edy/Documents/心理/TripPet` 执行。

### 4.1 JSON lint

```bash
python3 -m json.tool TripPet/Resources/ContentManifest.json >/dev/null
```

通过标准：

- 命令退出码为 0。
- 无 JSON 解析错误。

### 4.2 Xcode project lint

```bash
plutil -lint TripPet.xcodeproj/project.pbxproj
```

通过标准：

- 输出包含 `OK`。

### 4.3 Manifest 资源引用检查

```bash
node -e "const fs=require('fs'); const manifest=JSON.parse(fs.readFileSync('TripPet/Resources/ContentManifest.json','utf8')); const assets=new Set(fs.readdirSync('TripPet/Resources/Assets.xcassets',{recursive:true}).filter(p=>p.endsWith('.imageset')).map(p=>p.split('/').pop().replace(/\\.imageset$/,''))); const names=[]; for(const a of manifest.animals) names.push(a.homeAssetName,a.selfieAssetName,a.visitorAssetName); for(const d of manifest.destinations) names.push(d.landmarkAssetName,d.stampAssetName,d.routeMapAssetName,d.postcardTemplateAssetName); for(const p of manifest.postcards) names.push(p.templateAssetName,p.destinationAssetName,p.stampAssetName,p.animalAssetName,p.envelopeAssetName); const missing=[...new Set(names.filter(Boolean))].filter(n=>!assets.has(n)); if(missing.length){ console.error('Missing assets:', missing.join(', ')); process.exit(1); } console.log([...new Set(names.filter(Boolean))].length+' manifest asset names all exist');"
```

通过标准：

- 无 missing assets。
- 输出引用资源数量。

### 4.4 禁止旧名检查

```bash
rg -n "糖圆" TripPet TripPetTests
```

通过标准：

- App 源码、测试、manifest 中无 `糖圆`。

### 4.5 Simulator tests

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project TripPet.xcodeproj -scheme TripPet -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .derivedData CODE_SIGNING_ALLOWED=NO
```

通过标准：

- `TEST SUCCEEDED`。
- 现有测试全部通过。

### 4.6 iPhoneOS Debug build

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project TripPet.xcodeproj -scheme TripPet -configuration Debug -sdk iphoneos -derivedDataPath .derivedData CODE_SIGNING_ALLOWED=NO build
```

通过标准：

- `BUILD SUCCEEDED`。

## 5. 现有单元测试映射

### 5.1 已覆盖的 1.0.2 核心测试

`testPreviewAnimalsUseV102TravelProfiles`

- 覆盖三只首发动物 profile。
- 覆盖 dog 名称为“汤圆”。
- 覆盖三只动物 `canTravel == true`。

`testPostcardPlanCountsByTravelKind`

- 覆盖 short/standard/long 卡数。
- 覆盖 long 两张卡 sceneId、postcardType、microArc 不重复。

`testV102GeneratedPostcardUsesLandscapeTemplateWithoutVisualAnimalDependency`

- 覆盖 1.0.2 明信片使用 `postcard_template_landscape_v102`。
- 覆盖里斯本风景和邮戳资源。
- 覆盖 dog metadata 与标题“汤圆寄来的里斯本明信片”。

`testLongTripCompletesOnlyAfterSecondPostcardReveal`

- 覆盖 long trip 生成 2 张 plan。
- 覆盖第一张投递后 trip 仍 traveling。
- 覆盖第二张投递后 trip 和 wish completed。
- 覆盖两张卡 sceneId、postcardType、microArc 不重复。

### 5.2 仍建议补充的自动化测试

优先级 P0：

- `testContentManifestContainsOnlyV102LaunchDestinations`
- `testProjectDoesNotContainVisibleTangyuanTypo`
- `testPostcardNarrativeEngineIsDeterministicForSameInput`
- `testGiftTicketExpectedReturnAtUsesLastPlanDueAt`
- `testRevealEligiblePostcardsDoesNotRevealBeforeDueAt`
- `testRelationshipMemoryPersistsAcrossSwiftDataStore`

优先级 P1：

- `testNarrativeEngineCapsEmotionalWeightByTemplate`
- `testNarrativeEngineAvoidsRecentlyUsedScene`
- `testUnknownTravelKindFallsBackToStandardPlan`
- `testEmptyScenesStillGenerateFallbackPlan`
- `testVisitedCityIdsDoesNotDuplicate`
- `testRecentSceneIdsKeepsOnlyLatestEight`

优先级 P2：

- 邮箱排序可抽成纯函数后增加测试。
- 旧 postcard title 兼容显示可抽成 helper 后增加测试。
- manifest 资源引用扫描可转成 XCTest 或 CI 脚本。

## 6. 手工验收矩阵

### 6.1 全新安装路径

步骤：

1. 全新安装 App。
2. 完成欢迎页和 Health 引导，或稍后进入。
3. 进入小屋。
4. 确认当前动物为 cat 墨迹。
5. 赠送机票。
6. 等待或模拟到期后进入邮箱。
7. 打开明信片。

期望：

- 旅行创建成功。
- 邮箱到期出现明信片。
- 明信片详情使用大风景模板。
- 不出现动物自拍。
- 打开后未读 badge 减少。

### 6.2 三只动物派行路径

步骤：

1. 第一次派出 cat。
2. 1 小时后刷新小屋。
3. 第二次派出 dog。
4. 1 小时后刷新小屋。
5. 第三次派出 rabbit。
6. 再刷新小屋。
7. 第二天刷新小屋。

期望：

- 顺序为 cat -> dog -> rabbit。
- 第三次后达到每日上限，小屋保持空。
- 第二天从 cat 重新开始。
- dog 用户可见名称始终为“汤圆”。

### 6.3 三个目的地路径

步骤：

1. 分别触发巴黎、雷克雅未克、里斯本旅行。
2. 检查旅行状态卡路线图。
3. 检查邮箱投递明信片。
4. 检查详情页风景和邮戳。

期望：

- 巴黎使用 `destination_paris_line`、`stamp_paris`、`trip_route_map_paris`。
- 雷克雅未克使用 `destination_iceland_line`、`stamp_iceland`、`trip_route_map_iceland`。
- 里斯本使用 `destination_lisbon_line`、`stamp_lisbon`、`trip_route_map_lisbon`。
- 三个目的地视觉可区分。

### 6.4 长途两张卡路径

步骤：

1. 触发雷克雅未克 long trip。
2. 到第 2 天投递第一张。
3. 检查 trip 仍为 traveling。
4. 到第 4 天投递第二张。
5. 检查 trip 和 wish completed。

期望：

- 第一张 subtitle 为“旅途中寄来”。
- 第二张 subtitle 为“第二封来信”。
- 两张 sceneId、postcardType、microArc 不重复。
- 一次旅行不会出现第三张明信片。

### 6.5 邮箱与已读路径

步骤：

1. 准备多张已读和未读明信片。
2. 打开邮箱。
3. 打开一封未读明信片。
4. 返回邮箱。
5. 进入收藏页。

期望：

- 未读优先。
- 同状态按 sentAt 倒序。
- 打开后标记已读。
- Root Tab badge 减少。
- 收藏页显示已读明信片，不显示未读明信片。

### 6.6 旧数据升级路径

步骤：

1. 准备 1.0.1 真实设备数据库。
2. 安装或升级到 1.0.2。
3. 启动 App。
4. 检查旧 tickets、trips、postcards、wishes。
5. 打开旧明信片详情。
6. 再触发一趟 1.0.2 新旅行。

期望：

- App 不崩溃。
- 旧 trip 缺少 postcardPlan 时走旧 fallback 逻辑。
- 旧 postcard 缺少 metadata 时仍可展示。
- 旧 title “小猫寄来的自拍”显示为“小猫寄来的明信片”。
- 新旅行可以生成 1.0.2 plan 和新明信片。

### 6.7 小屏、Dynamic Type、VoiceOver

步骤：

1. 使用 iPhone SE 或小屏模拟器打开明信片详情。
2. 切换较大 Dynamic Type。
3. 开启 VoiceOver。
4. 开启 Reduce Motion。
5. 重跑邮箱打开明信片流程。

期望：

- 明信片正文不严重溢出。
- 标题不压正文。
- 邮戳不压正文。
- VoiceOver 可以读完整关键内容。
- Reduce Motion 下动效不影响点击和返回。

## 7. 内容 QA 标准

### 7.1 三句话标准

每张明信片先过三句话：

```text
像它。
像发生过。
像寄给你的。
```

解释：

- 像它：语气、动作、观察角度符合这只小动物。
- 像发生过：卡片内部有一个很小的事件链，不是地点句、意象句、关系句拼接。
- 像寄给你的：有私人距离，但不把用户当咨询对象，不强行安慰或投射。

### 7.2 单张明信片标注

人工抽样时，每张明信片必须标注：

```text
小动物：
地点城市：
地点场景：
明信片类型：
主导关联机制：
核心物件：
核心动作：
结尾来源：
```

审核问题：

- 删掉核心物件后，结尾还成立吗？
- 删掉核心动作后，结尾还成立吗？
- 最后一句是否由前文动作自然推出？
- 是否有一句话只是为了漂亮？
- 是否像朋友发来的近况，而不是作者在写散文？

### 7.3 15 张样张矩阵

发布前建议抽样 15 张：

- 每只动物 5 张。
- 每个城市至少覆盖 3 张。
- `daily_observation`、`personality_reaction`、`motif_echo` 至少各覆盖 2 张。
- 至少覆盖 2 种以上 microArc。
- 雷克雅未克至少覆盖一次 long trip 第二封。

通过建议：

- 15 张中至少 12 张通过。
- 每只动物至少 4 张通过。
- 任一城市不能连续出现明显事实风险。
- 连续 5 张同一动物不能都靠同一意象或同一结尾方式。

### 7.4 退稿条件

出现以下问题应退回内容修改：

- 明显抽象金句。
- 过度心理化，例如直接解释“我害怕”“我防御”“你治好了我”。
- 过度景点介绍，像旅游宣传而不是明信片。
- 核心意象只被提到，没有参与动作。
- 结尾脱离前文也成立。
- 为了余味而过度忧郁。
- 同一动物连续两张都过重。
- 同一动物连续两张都像同一种文艺腔。
- 句子之间没有空间、物件、动作或情绪承接。
- 用户可见文本直接解释内部心理主题。

## 8. 发布前必做清单

P0 必做：

- JSON lint 通过。
- pbxproj lint 通过。
- manifest 资源引用检查通过。
- Simulator tests 通过。
- iPhoneOS Debug build 通过。
- `糖圆` 检查通过。
- 真实 1.0.1 设备数据库升级验证。
- iPhone SE 或小屏明信片详情验收。
- 大 Dynamic Type 明信片详情验收。
- VoiceOver 邮箱与详情完整流程。
- 15 张内容样张人工终审。

P1 建议：

- relationship memory SwiftData round-trip 测试。
- 叙事引擎稳定性测试。
- 未到期不投递测试。
- dueAt 精确断言测试。
- 邮箱排序逻辑单元测试。

P2 可后续：

- Snapshot/UI test。
- 自动内容抽样脚本。
- motif/object/action metadata 扩展。
- 收藏与 `favoritedPostcardIds` 联动。

## 9. 已知风险记录

1. SwiftData 真实迁移仍需设备级验证。当前 optional 字段和 in-memory 测试降低风险，但不能替代真实 1.0.1 数据升级。

2. Dynamic Type 仍需手工确认。`PostcardDetailView` 使用 16:9 布局、正文 5 行和缩放因子，小屏和大字号下可能截断过多。

3. VoiceOver 信息量需要手工感受。当前详情 label 合并了 title、destination、subtitle、body，但未读状态是否需要更明确读出仍需验收。

4. 内容仍需人工终审。manifest scenes 和 profile 已进入 MVP，但地点文案必须继续按“城市、场景、物件、动作”回溯。

5. `recentlyUsedMotifs` 当前写入 `postcard.microArc`，严格来说不是 motif 本身。它能起到部分叙事机制冷却效果，但后续建议给 Postcard 增加真正的 motif/object/action metadata。

6. UI 暂无自动截图测试。本轮以 build、unit tests 和手工验收为主，后续可以补 snapshot 或 UI test。

## 10. 验收结论模板

每次发布前验收可以复制以下模板：

```text
TripPet 1.0.2 明信片系统验收记录

日期：
设备 / 模拟器：
iOS 版本：
测试人：

自动化：
- JSON lint：
- pbxproj lint：
- manifest asset scan：
- Simulator tests：
- iPhoneOS Debug build：
- 糖圆检查：

手工：
- 全新安装路径：
- 三只动物派行：
- 三目的地资源：
- 长途两张卡：
- 邮箱未读/已读：
- 明信片详情：
- 收藏页：
- 小屏：
- Dynamic Type：
- VoiceOver：
- 1.0.1 数据升级：
- 15 张内容样张：

阻塞问题：

非阻塞风险：

结论：
```
