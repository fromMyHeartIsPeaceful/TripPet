# 真实地点数据库 V2

这个目录用于规划《小动物旅行叙事系统》的真实地点、城市风物和旅行生活场景内容资产。

当前阶段仍不实现 Swift 代码，但已经推进到完整 V2 文本资产形态。

## 文件

- `LocationDatabase_Plan.md`：地点数据库的分层策略、字段规范、生活场景库规范和人工测试方法。
- `V2/README.md`：V2 数据资产目录说明。
- `V2/city_candidate_pool_v2.json`：300 个世界城市候选。
- `V2/city_detail_packs_v2.json`：300 个城市详细包，每城 10 个可写场景，共 3000 个场景。
- `V2/scene_event_library_v2.json`：100 个可复用旅行生活事件。
- `V2/city_geography_capabilities_v2.json`：300 个城市的粗粒度地理能力表。
- `V2/location_database_v2_summary.md`：V2 计数、组合顺序和 QA 规则。
- `V2/rebuild_location_database_v2.mjs`：V2 地点资产重建脚本。
- `V2/validate_location_database_v2.mjs`：V2 自动校验脚本。
- `V2/validate_location_geography_v2.mjs`：V2 地理常识校验脚本。

## 内容边界

- 地点库负责回答“发生在哪里、那里有什么普通生活细节”。
- 小动物角色库负责回答“是谁在经历这件小事、它会怎么做”。
- 明信片模板负责回答“这件小事如何写成一张短消息”。
- 真实地点事实只从人工维护资料库抽取，不由生成器临时编造。

## 当前结论

- V2 已规划 300 个城市候选。
- V2 已为 300 个城市各规划 10 个可写场景，并移除旧版模板化占位地点。
- 普通生活场景优先于知名地点，知名地点只作为边缘锚点。
- V2 已独立维护 100 个可复用旅行生活事件。
- 风物细节按“城市 + 场景”组合规划，不做脱离城市的孤立词库。
- V2 已加入粗粒度地理能力表，用于避免北京海边、内陆港边、无稳定水系城市河岸湖边、无轨城市电车等地理常识级错误。
- 当前 3000 个场景均带有 `sourceRefs` 和 `verificationStatus`，状态为待人工终审。

## 接入状态

- `city_candidate_pool_v2.json` 可用于目的地池和旅行调度。
- `city_detail_packs_v2.json` 可用于地点场景抽取和样张测试。
- `scene_event_library_v2.json` 可用于普通旅行事件抽取。
- 进入正式产品文案前，具体城市事实必须按 `sourceRefs` 做人工终审；未终审场景只能写成城市级生活空间，不能写成已核验具体地址。
