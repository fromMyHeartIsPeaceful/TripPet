# TripPet 1.0.2 明信片系统测试结论

测试时间：2026-06-10 16:40-16:42  
测试分支：`codex/trippet-1.0.2-postcard`  
项目路径：`/Users/edy/Documents/心理/TripPet`

## 总结论

1.0.2 明信片系统的自动化与静态验收通过，可以进入人工发布验收阶段。

当前已确认：

- 代码可以通过 iPhone Simulator 单元测试。
- iPhoneOS Debug 目标可以成功构建。
- manifest、资源、Xcode 工程文件、1.0.2 核心业务规则和主要 UI 代码路径通过静态检查。
- 1.0.2 需求偏离防线通过：三动物、三目的地、通用大风景模板、本地确定性叙事、无动物自拍详情依赖、无“糖圆”用户可见旧名。

当前未在命令环境完成、仍需发布前人工确认：

- 真实 1.0.1 设备数据库升级到 1.0.2。
- iPhone SE 或小屏设备的明信片详情视觉。
- 大 Dynamic Type 下的明信片详情文字溢出情况。
- VoiceOver 邮箱与明信片详情完整流程。
- 15 张明信片样张内容人工终审。

## 已执行检查

### 1. JSON lint

命令：

```bash
python3 -m json.tool TripPet/Resources/ContentManifest.json >/dev/null
```

结果：通过。

### 2. Xcode project lint

命令：

```bash
plutil -lint TripPet.xcodeproj/project.pbxproj
```

结果：通过，输出 `TripPet.xcodeproj/project.pbxproj: OK`。

### 3. Manifest 资源引用检查

命令：

```bash
node -e "const fs=require('fs'); const manifest=JSON.parse(fs.readFileSync('TripPet/Resources/ContentManifest.json','utf8')); const assets=new Set(fs.readdirSync('TripPet/Resources/Assets.xcassets',{recursive:true}).filter(p=>p.endsWith('.imageset')).map(p=>p.split('/').pop().replace(/\\.imageset$/,''))); const names=[]; for(const a of manifest.animals) names.push(a.homeAssetName,a.selfieAssetName,a.visitorAssetName); for(const d of manifest.destinations) names.push(d.landmarkAssetName,d.stampAssetName,d.routeMapAssetName,d.postcardTemplateAssetName); for(const p of manifest.postcards) names.push(p.templateAssetName,p.destinationAssetName,p.stampAssetName,p.animalAssetName,p.envelopeAssetName); const missing=[...new Set(names.filter(Boolean))].filter(n=>!assets.has(n)); if(missing.length){ console.error('Missing assets:', missing.join(', ')); process.exit(1); } console.log([...new Set(names.filter(Boolean))].length+' manifest asset names all exist');"
```

结果：通过，输出 `16 manifest asset names all exist`。

### 4. 旧名检查

命令：

```bash
rg -n "糖圆" TripPet TripPetTests
```

结果：通过，无命中。

### 5. 1.0.2 manifest 约束检查

检查内容：

- 可旅行动物为 `cat`、`dog`、`rabbit`。
- dog 显示名为“汤圆”，profile 为 `tangyuan_puppy`。
- 目的地为 `fr_paris`、`is_reykjavik`、`pt_lisbon`。
- 巴黎 `travelKind` 为 `standard`。
- 雷克雅未克 `travelKind` 为 `long`。
- 里斯本 `travelKind` 为 `short`。
- 三个目的地都使用 `postcard_template_landscape_v102`。
- 每个目的地都有 6 个 scenes。
- scenes 包含 `sceneId`、`sceneName`、`sceneType`、`sensoryDetails`、`localObjects`、`availableActions`、`postcardTypes`、`microArcFits`、`animalAffinity`、`avoidWriting`。
- narrative profiles 包含 `moji_cat`、`tangyuan_puppy`、`dengdeng_rabbit`。
- narrative templates 覆盖 `daily_observation`、`personality_reaction`、`motif_echo`。

结果：通过，输出 `v102 manifest constraints ok`。

### 6. 1.0.2 美术资源检查

检查文件：

- `TripPet/Resources/ArtSourceRaster/Postcards/postcard_template_landscape_v102.png`
- `TripPet/Resources/ArtSourceRaster/Destinations/destination_lisbon_line.png`
- `TripPet/Resources/ArtSourceRaster/Destinations/trip_route_map_lisbon.png`
- `TripPet/Resources/ArtSourceRaster/Stamps/stamp_lisbon.png`
- 对应四个 `.imageset/Contents.json`

结果：通过。

PNG 尺寸：

- `postcard_template_landscape_v102.png`：1536 x 1024
- `destination_lisbon_line.png`：1704 x 923
- `trip_route_map_lisbon.png`：1690 x 931
- `stamp_lisbon.png`：1254 x 1254

imageset 检查：

- `Contents.json` 均为合法 JSON。
- 文件名均指向预期 `@3x.png`。

### 7. 明信片详情动物自拍依赖检查

命令：

```bash
rg -n "animalAssetName" TripPet/Features/Mailbox/PostcardDetailView.swift
```

结果：通过，`PostcardDetailView` 不引用 `animalAssetName`。

### 8. 叙事引擎本地确定性静态检查

检查内容：

- `PostcardNarrativeEngine.swift` 不引用 `URLSession`、`http://`、`https://`、`Network`、`NWConnection`。
- 不使用 Swift `String.hashValue` 或 `hashValue`。

结果：通过，输出 `Narrative engine has no network/String.hashValue references`。

### 9. UI 关键路径静态检查

检查到以下关键路径存在：

- `RootTabView` 邮箱 badge 基于未读 postcards。
- `MailboxView` 进入时调用 `revealEligiblePostcards`。
- `MailboxView` 未读优先排序。
- `MailboxViewModel` 打开明信片时调用 `markPostcardRead`。
- `MailboxView` 使用 `fullScreenCover` 打开详情。
- `PostcardDetailView` 渲染 destination、stamp、SwiftUI 文本。
- `PostcardDetailView` 返回按钮和正文有 accessibility label。
- `SettingsView` 收藏页过滤 `isRead` postcards。

结果：通过。

### 10. Xcode project 新文件接入

检查文件：

- `TripPet/Domain/Models/AnimalRelationshipMemory.swift`
- `TripPet/Domain/Services/PostcardNarrativeEngine.swift`

结果：通过，两个新增 Swift 文件都已在 `project.pbxproj` 的 file reference、group 和 sources build phase 中。

### 11. Simulator 单元测试

命令：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project TripPet.xcodeproj -scheme TripPet -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .derivedData CODE_SIGNING_ALLOWED=NO
```

结果：通过，输出 `** TEST SUCCEEDED **`。

测试结果路径：

```text
/Users/edy/Documents/心理/TripPet/.derivedData/Logs/Test/Test-TripPet-2026.06.10_16-40-29-+0800.xcresult
```

通过的关键 1.0.2 测试：

- `testPreviewAnimalsUseV102TravelProfiles`
- `testPostcardPlanCountsByTravelKind`
- `testV102GeneratedPostcardUsesLandscapeTemplateWithoutVisualAnimalDependency`
- `testLongTripCompletesOnlyAfterSecondPostcardReveal`

本次测试总量：

- `AppRepositoryTripTests`：18 个通过。
- `CabinViewModelTests`：6 个通过。
- `TicketRuleEngineTests`：7 个通过。
- 合计：31 个通过。

### 12. iPhoneOS Debug build

命令：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project TripPet.xcodeproj -scheme TripPet -configuration Debug -sdk iphoneos -derivedDataPath .derivedData CODE_SIGNING_ALLOWED=NO build
```

结果：通过，输出 `** BUILD SUCCEEDED **`。

## 发布前剩余人工验收

以下项目没有在当前命令环境完成，不能被视为已通过：

1. 真实 1.0.1 数据迁移
   - 使用真实设备上的 1.0.1 SwiftData 数据升级到 1.0.2。
   - 检查旧 tickets、trips、postcards、wishes 是否可加载。
   - 检查旧 postcard 是否仍可打开。

2. 小屏视觉
   - 使用 iPhone SE 或等效小屏设备检查明信片详情。
   - 重点看正文、邮戳、日期、标题是否互相遮挡。

3. Dynamic Type
   - 检查较大字号和超大字号。
   - 确认正文不会严重溢出或截断到失去主要内容。

4. VoiceOver
   - 跑通邮箱列表、打开明信片、阅读详情、返回邮箱。
   - 确认未读状态和正文读法舒服。

5. 内容人工终审
   - 抽样 15 张。
   - 每只动物 5 张。
   - 每个城市至少 3 张。
   - 标注小动物、城市、场景、类型、微型关联机制、核心物件、核心动作、结尾来源。

## 最终判断

自动化、静态工程、资源完整性与核心业务测试均通过。

1.0.2 明信片系统代码和资源可以合并为独立版本分支并推送到 GitHub；但正式发布前仍建议完成真实迁移、小屏、Dynamic Type、VoiceOver 和内容样张人工终审。
