# 真实地点与生活场景文本数据库规划 V2

本文件用于把“小动物去哪里、在那里能遇到什么”从单张样张里的临时设定，升级为可长期维护的文本数据库。

当前阶段不落 Swift 代码，但已经生成完整 V2 文本数据资产。目标是固定数据层级、字段边界、内容规模和人工测试方法。

V2 已完成一次地点事实风险修复：旧版全城市复用的占位场景已经移除，当前场景改为“真实城市 + 生活锚点 + 可行动物件”的待人工终审资产。

## 1. 核心结论

需要提前规划真实地点数据库。V2 已按完整内容资产推进：300 个城市候选、300 个详细城市包、每城 10 个可写场景、100 个旅行生活事件。

重要状态：当前 3000 个场景均已删除旧模板化占位写法，并新增粗粒度地理能力表先筛掉地理常识级错误。具体地点锚点仍为 `needs_human_final_review`，进入最终产品文案前必须逐条人工终审。

推荐分三层：

```text
cityCandidatePool
    300 个世界城市候选，用于目的地池和调度。

cityDetailPack
    300 个城市详细包，每城 10 个可写场景。

sceneEventLibrary
    100 个可复用旅行生活事件。
```

原因：

- 300 个城市候选可以让旅行目的地显得广阔，也方便后续扩展。
- 300 x 10 个场景资料不应写成景点大全，而应写成城市中的可发生生活空间。
- 明信片真正需要的不是景点数量，而是“地点细节 + 普通事件 + 小动物动作”能组成一件小事。
- 生活事件库独立后，等车、买票、避雨、排队、错拿东西等事件可以跨城市复用，再由城市风物细节提供当地感。

## 2. 分层数据结构

### 2.1 城市候选池 `cityCandidatePool`

用途：

- 用于旅行目的地抽取。
- 用于控制地区覆盖、距离等级、稀有地点概率。
- 用于未来扩展详细城市包。
- 不直接用于生成具体明信片正文。

建议规模：

```text
V2 规划池：300 个城市
V2 可抽取池：300 个城市
V2 详细包：300 个城市
```

每个城市候选的轻量字段：

```text
cityId
cityNameZh
cityNameLocal
countryOrRegion
continent
travelDistanceTier
climateOrGeography
modernLifeTags
emotionTags
culturalNotes
avoidStereotypes
detailPackStatus
```

字段说明：

- `travelDistanceTier`：`near`、`regional`、`far`、`rare`，用于步数和旅行时长调度。
- `modernLifeTags`：公共交通、市场、港口、雨季、夜生活、书店、公园、老城区等。
- `emotionTags`：轻松、尴尬、温柔、怀旧、等待、迷路、临时决定等。
- `detailPackStatus`：`candidate_only`、`planned`、`ready`、`needs_review`。

示例：

```json
{
  "cityId": "cn_shanghai",
  "cityNameZh": "上海",
  "cityNameLocal": "Shanghai",
  "countryOrRegion": "中国",
  "continent": "Asia",
  "travelDistanceTier": "regional",
  "climateOrGeography": "滨海城市，湿润，雨后街面和地铁通勤感明显。",
  "modernLifeTags": ["地铁", "江边", "弄堂", "便利店", "咖啡店", "雨天"],
  "emotionTags": ["临时改道", "等待", "尴尬", "温柔", "轻松日常"],
  "culturalNotes": ["避免把城市只写成高楼和速度。"],
  "avoidStereotypes": ["不要把上海固定写成冷漠、精英或只有繁华夜景。"],
  "detailPackStatus": "ready"
}
```

### 2.2 详细城市包 `cityDetailPack`

用途：

- 供明信片生成器直接抽取真实地点细节。
- 保证城市不只是名字，而有可发生事件的普通生活空间。
- 为不同小动物提供不同动作入口。

V2 规模：

```text
城市详细包：300 个城市
每个城市：10 个可写场景
总场景：3000 个
```

每个城市 10 个场景建议结构：

```text
2-3 个知名地点或城市标志物
3-4 个普通生活地点
2-3 个交通、天气或街边食物场景
1-2 个安静、回访或边缘场景
```

重要原则：

- 知名地点可以出现，但不能让明信片变成景点打卡。
- 普通生活地点是长期耐读的核心。
- 每个场景必须能发生小动作，例如拿起、放回、排队、修补、遮住、递还、让开、留下。

每个城市包字段：

```text
cityId
cityNameZh
countryOrRegion
overviewForWriters
globalAvoidRules
scenes
```

每个场景字段：

```text
sceneId
sceneName
sceneType
isFamousPlace
realWorldAnchor
sensoryDetails
localObjects
possibleEvents
availableActions
emotionTags
postcardTypes
microArcFits
animalAffinity
culturalNotes
avoidWriting
anchorKind
verificationStatus
sourceRefs
```

字段说明：

- `sceneType`：`landmark`、`transport`、`market`、`food`、`weather`、`quiet_place`、`lodging`、`street_corner` 等。
- `realWorldAnchor`：真实地点锚点，可以是具体地点，也可以是城市中稳定存在的生活空间。
- `sensoryDetails`：声音、气味、天气、光线、材质、人群节奏。
- `localObjects`：能被小动物实际使用的物件，例如车票、杯套、伞扣、纸袋、围巾、菜单、门牌。
- `possibleEvents`：适合这里发生的小事件。
- `availableActions`：小动物可以做的动作。
- `microArcFits`：动作型、误会型、旁观型、反转型、回声型、缺席型、选择型。
- `anchorKind`：锚点粒度，例如 `city_life_area`、`landmark_edge`。
- `verificationStatus`：事实状态；当前 V2 默认为 `needs_human_final_review`。
- `sourceRefs`：人工终审入口，优先补官方、半官方、OpenStreetMap、Wikidata 等来源。

另有 `city_geography_capabilities_v2.json` 维护城市级地理能力，用于避免内陆海边、无轨电车、错误港边轮渡、无稳定水系城市水边场景等粗粒度错误。

示例场景：

```json
{
  "sceneId": "cn_shanghai_metro_transfer",
  "sceneName": "上海地铁换乘通道",
  "sceneType": "transport",
  "isFamousPlace": false,
  "realWorldAnchor": "上海城市地铁换乘空间",
  "sensoryDetails": ["长通道", "换乘指示牌", "刷卡声", "人群脚步", "空调风"],
  "localObjects": ["车票", "交通卡", "站内地图", "纸袋", "掉落的扣子"],
  "possibleEvents": ["临时改道", "差点坐错线", "帮陌生人指路", "少检查一次也到达"],
  "availableActions": ["停下看路线", "把路线画在票背面", "让开通道", "捡起小物件"],
  "emotionTags": ["临时决定", "轻微紧张", "轻松日常"],
  "postcardTypes": ["daily_observation", "personality_reaction", "value_choice"],
  "microArcFits": ["选择型", "动作型", "误会型"],
  "animalAffinity": ["xiaoman_hamster", "tangyuan_puppy", "moji_cat"],
  "culturalNotes": ["写现代通勤感，不把城市简化成夜景。"],
  "avoidWriting": ["不要写成抽象的都市孤独。"]
}
```

### 2.3 生活事件库 `sceneEventLibrary`

用途：

- 把旅行中常见的小事独立出来，避免每个城市重复写一遍。
- 通过标签匹配城市场景、小动物动作模式和微型关联机制。
- 支持明信片内部事件链，而不是只提供背景词。

V2 规模：

```text
旅行生活事件：100 个
每类：10 个事件
每个事件至少：2 种可变体
```

事件类型建议：

```text
transport_waiting：等车、换乘、买票、错过车
weather_shelter：避雨、风大、突然降温、鞋底湿
small_purchase：买咖啡、买面包、找零钱、点错菜单
queue_and_order：排队、让位、被催、拿错号码牌
lost_and_reroute：迷路、临时改道、地图折错、路牌看不清
object_repair：修伞、缝扣子、整理围巾、捡回票
quiet_observation：旁观、记录、看见别人生活
help_without_intrusion：帮忙但不打扰、提醒但不接管
name_and_ticket：假名字、票据、收据、地址
not_sending：没投递、没敲门、没说出口、先带回去
```

每个生活事件字段：

```text
eventId
eventName
eventType
trigger
coreObject
actionOptions
possibleOutcomes
microArcFits
postcardTypes
animalAffinity
sceneTypeFits
emotionWeightRange
styleRisks
continuityCheck
```

示例事件：

```json
{
  "eventId": "object_repair_broken_umbrella_clasp",
  "eventName": "伞扣坏了，临时修好",
  "eventType": "object_repair",
  "trigger": "雨天或雨后，角落里有一把收不起来的伞。",
  "coreObject": "坏伞扣",
  "actionOptions": ["用备用扣子临时缝上", "发现只是扣带绕住", "把伞放到不容易绊倒人的位置"],
  "possibleOutcomes": ["伞能合起来", "备用扣子少一颗", "没有把伞带走"],
  "microArcFits": ["动作型", "误会型", "选择型"],
  "postcardTypes": ["daily_observation", "personality_reaction", "motif_echo"],
  "animalAffinity": ["xiaoman_hamster", "xiaolu_guinea_pig", "moji_cat"],
  "sceneTypeFits": ["transport", "street_corner", "weather", "lodging"],
  "emotionWeightRange": [0, 2],
  "styleRisks": ["不要把坏伞写成命运隐喻。", "不要让结尾脱离修伞动作。"],
  "continuityCheck": "结尾必须来自伞扣、备用物或是否带走这把伞。"
}
```

## 3. 生成组合顺序

建议的内容组合顺序：

```text
1. 选择城市
2. 选择城市内具体场景
3. 选择适合该场景的生活事件
4. 选择可行动物件
5. 选择小动物动作模式
6. 选择主导微型关联机制
7. 写出一张内部有关联的明信片
8. 做地点真实感、连续性和文风检查
```

注意：

- 城市不能只提供名字，至少要提供一个能被证明的场景细节。
- 场景不能只提供背景，必须提供可行动物件。
- 生活事件不能只提供主题，必须提供触发、动作和结果。
- 小动物动作必须改变事件的某个小状态。
- 结尾必须来自本张卡的地点、物件或动作。

## 4. 首发内容规模建议

### 4.1 城市候选池

先建立 300 个候选城市的轻量池，目的不是立即生成，而是提供世界感和扩展路线。

建议分布：

```text
中国大陆及港澳台：40-60
东亚与东南亚：45-60
南亚、中亚、西亚：30-45
欧洲：70-90
北美：35-50
拉美：25-40
非洲：25-40
大洋洲：10-20
```

候选城市入池标准：

- 有明确真实地理位置。
- 有可写普通生活场景，不只是观光符号。
- 可以避免刻板印象地书写。
- 未来至少能扩展出 8-12 个场景。

### 4.2 详细城市包

首发建议先做 12 个详细城市包，覆盖不同气候、交通、文化区域和生活节奏。

每个城市至少：

```text
10 个可写场景
30 个风物或感官细节
15 个本地可发生小事件
10 个可行动物件
5 个避免刻板印象规则
5 个适合情绪标签
```

12 个城市可以先覆盖：

```text
中国现代大城市
中国慢节奏或水边城市
东亚高密度城市
东南亚湿热城市
欧洲交通枢纽城市
欧洲水边或老城城市
北美公共交通或街区城市
拉美市场和广场城市
西亚或北非历史城市
南亚日常密度城市
非洲现代城市
大洋洲港口或海边城市
```

这里先定义类型，不在本文件锁死具体城市名单。具体城市名单应在 `cityCandidatePool` 建立时统一选择，避免样张先行造成地区偏差。

### 4.3 生活事件库

首批至少 100 个事件。建议按 10 类事件，每类 10 个。

每个事件必须能回答：

```text
它为什么发生？
核心物件是什么？
小动物能做什么？
动作后有什么变化？
哪些小动物适合？
哪些场景适合？
哪里容易写得太文艺或太心理化？
```

## 5. 风物细节规划

风物细节要按“城市 + 场景”实际组合规划，不建议只做孤立词库。

不推荐：

```text
雨、桥、地铁、市场、钟声、街边食物
```

推荐：

```text
上海 / 地铁换乘通道 / 空调风、刷卡声、换乘指示牌、长通道
成都 / 小区门口包子铺 / 蒸汽、排队、楼上喊人、热纸袋
青岛 / 雨后石阶路 / 潮湿台阶、脚印、海风、墙边水痕
巴黎 / 北站 / 站台风、广播声、拖箱轮、咖啡纸杯
```

原因：

- 孤立风物词很容易变成背景装饰。
- 城市场景组合能提供真实感。
- 具体风物能成为事件物件，例如杯套、车票、纸袋、伞扣、门牌、票角。

每个风物细节最好标注：

```text
能否参与动作
适合哪些生活事件
适合哪些小动物
是否容易产生刻板印象
```

## 6. 人工测试方法

### 6.1 三个样板城市包

先抽 3 个城市做样板包，每城 10 个场景。

测试目标：

- 城市是否有当地感。
- 场景是否有普通生活。
- 每个场景是否至少有 3 个可行动物件。
- 每个场景是否能支持 2 种以上情绪。
- 知名地点是否没有压过日常场景。

### 6.2 二十个事件跨城市测试

从 100 个生活事件中抽 20 个，分别套到不同城市。

测试问题：

```text
同一事件换城市后是否自然？
换城市后是否只是在替换城市名？
城市风物是否参与动作？
事件是否仍然是一件小事，而不是剧情大纲？
```

### 6.3 十二张地点驱动样张

用 6 只小动物各写 2 张地点驱动样张，共 12 张。

每张必须标注：

```text
城市
场景
生活事件
核心风物
核心动作
主导关联机制
地点真实感是否成立
是否存在刻板印象
结尾是否来自地点、物件或动作
```

通过标准：

- 12 张里至少 9 张通过。
- 每张都能指出一个具体城市或场景细节。
- 每张都能指出一个真实生活事件。
- 每张都能指出一个由小动物完成的小动作。
- 没有一张只像景点介绍。

## 7. 与小动物数据库的关系

地点库不负责塑造小动物人格，小动物库不负责编造地点事实。

两者通过标签组合：

```text
cityDetailPack.scene.microArcFits
sceneEventLibrary.event.animalAffinity
animal_profiles.generationControl.preferredPostcardTypes
animal action pattern
```

组合后再由样张审核规则检查：

```text
像它。
像发生过。
像寄给你的。
```

## 8. 下一步任务

建议下一轮按这个顺序推进：

```text
1. 先跑自动校验和地理校验，确认无地理常识级错误。
2. 按 sourceRefs 对 3000 个场景做分批人工终审。
3. 抽 30 个城市包检查场景是否仍有城市级泛化过强的问题。
4. 抽 100 个场景检查风物是否真正参与动作。
5. 抽 20 个生活事件做跨城市适配测试。
6. 写 12 张地点驱动样张，和小动物样张审核流程合并。
7. 根据样张问题回填城市包、事件库和动物 locationIntegration 字段。
```

暂不建议：

```text
只列世界著名景点。
把风物细节做成脱离城市的词库。
让生成器临时编造真实地点事实。
未经事实校验就把具体城市细节当成最终产品文案。
```
