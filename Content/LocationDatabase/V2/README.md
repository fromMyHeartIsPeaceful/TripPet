# LocationDatabase V2

本目录是完整地点内容资产 V2。

## 文件

- `city_candidate_pool_v2.json`：300 个城市候选。
- `city_detail_packs_v2.json`：300 个城市详细包，每个城市 10 个可写场景，共 3000 个场景。
- `scene_event_library_v2.json`：100 个可复用旅行生活事件。
- `city_geography_capabilities_v2.json`：300 个城市的粗粒度地理能力表，用于筛掉海边、港边、轮渡、河岸湖边、电车、坡道等地理常识级错误。
- `rebuild_location_database_v2.mjs`：可复现重建脚本，用于移除模板化占位地点并生成待人工终审的 V2 资产。
- `validate_location_database_v2.mjs`：V2 自动校验脚本，检查数量、旧模板残留、重复度、字段下限和事件去重。
- `validate_location_geography_v2.mjs`：V2 地理常识校验脚本，检查城市能力与场景类型、地理词是否冲突。
- `location_database_v2_summary.md`：字段、计数、使用顺序和 QA 说明。

普通生活场景优先于知名地点。每个场景至少提供风物细节、可行动物件、可发生事件、可用动作、适合明信片类型和避免写法。

## 当前状态

V2 已完成一次事实风险修复：

- 删除旧版全城市复用的 10 个场景模板。
- 场景原型扩充为 42 类日常生活场景。
- 每个场景新增 `anchorKind`、`verificationStatus`、`sourceRefs`。
- 每个城市新增粗粒度地理能力，用于过滤明显错误的海边、港边、轮渡、河岸湖边、电车和坡道场景。
- 当前 3000 个场景均为 `needs_human_final_review`，可用于样张和生成器测试，但进入最终产品文案前必须人工终审。

## 校验

```bash
node Content/LocationDatabase/V2/validate_location_database_v2.mjs
node Content/LocationDatabase/V2/validate_location_geography_v2.mjs
```
