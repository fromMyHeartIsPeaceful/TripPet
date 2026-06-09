# 小动物数据库 V2

这个目录实现《小动物旅行叙事系统产品规划》里的“小动物静态角色库”。

## 文件

- `AnimalProfiles_Bible.md`：作者可读的角色 bible，用来把握每只小动物的语气、边界和长期叙事方向。
- `animal_profiles.json`：生成器可读的结构化角色库，可直接作为 iOS bundle 内的本地 JSON 资产。
- `RelationshipMemoryShape.md`：运行时关系记忆的数据边界说明，不属于静态角色库。
- `PostcardWriting_TestGuide.md`：明信片文本样张的人工审核方法，先用于内容打磨，不要求生成器实现。
- `PostcardSampleReview_Log.md`：首批 30 张明信片样张的标注、问题记录和修正版。

## 稳定枚举

`relationshipStage`

- `stranger`：陌生
- `testing`：试探
- `familiar`：熟悉
- `trusted`：信任
- `attached`：牵挂

`revealBudget`

- `none`
- `tiny`
- `small`
- `medium`
- `major`

`emotionalWeight`

- `0`：轻松日常
- `1`：轻微情绪
- `2`：含蓄伤感
- `3`：明显创伤回声
- `4`：重大揭示

`postcardType`

- `daily_observation`：日常观察
- `personality_reaction`：性格反应
- `relationship_card`：关系明信片
- `memory_fragment`：记忆碎片
- `value_choice`：价值选择
- `motif_echo`：意象回声
- `silent_anomaly`：沉默异常

## 内容边界

- 静态库只回答“它是谁、它怎么说话、它不能乱说什么”。
- 用户见过几次、去过哪里、哪些秘密已揭示，全部进入关系记忆。
- `primaryTheme` 和 `secondaryThemes` 是内部写作字段，不出现在用户界面和明信片正文。
- 生成器只能抽取静态库已有线索、秘密和意象，不能临时编造角色过去。
- `PostcardWriting_TestGuide.md` 和 `PostcardSampleReview_Log.md` 是人工内容测试资产，不等同于正式 JSON schema。
- `animal_profiles.json` V2 已新增 `generationControl.locationIntegration`，用于和地点数据库 V2 对接。

## V2 地点联动字段

`generationControl.locationIntegration`

- `preferredSceneTypes`：这只小动物更适合的地点场景类型。
- `preferredEventTypes`：这只小动物更适合的旅行生活事件类型。
- `locationActionPatterns`：它在真实地点里容易做出的具体小动作。
- `avoidLocationWriting`：和地点联动时不应该使用的写法。

地点联动字段只决定“它在什么场景里更容易做什么”，不改变角色核心设定，也不能编造地点事实。
