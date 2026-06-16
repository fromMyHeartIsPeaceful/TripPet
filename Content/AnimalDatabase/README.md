# 小动物数据库：作者资料库

这个目录存放“小动物旅行明信片文本系统”的作者资料与结构化资产。

## 当前任务版说明

- `AnimalProfiles_Bible.md` 是当前 9 只小动物的作者角色 Bible：小满、糖圆、墨迹、灯灯、飞飞、小炉、啾啾、埃尼、墩墩。
- `AnimalVoiceEcology_Current9.md` 是当前 9 只的声音生态位、专属生成提示词和 9 条盲测级样张。
- `TravelEventSceneLibrary_900.md` 是现有 900 个旅行事件场景库，本轮保留不改。
- `AnimalBasePostcards_900.md` 是当前 9 只强差异声音版基础明信片母本库：每只 100 条，共 900 条。
- `PostcardTextLibrary_1.0.6/` 是 1.0.6 可消耗明信片文本库的作者 Markdown 资源；运行时 Swift 静态库由 `Tools/generate_postcard_text_library.py` 生成。
- `TravelEventSceneLibrary_800.md` 是上一轮 800 通用事件场景草稿，保留作对照。
- `animal_profiles.json` 仍是旧结构化资产，暂未同步本轮 Markdown 内容；后续如需进入 App，应单独做 Markdown -> JSON schema 转换。

## 文件

- `AnimalProfiles_Bible.md`：作者可读的当前 9 只角色 bible。
- `AnimalVoiceEcology_Current9.md`：声音生态位、模型提示词和样张。
- `TravelEventSceneLibrary_900.md`：作者可读的 900 个旅行事件场景库。
- `AnimalBasePostcards_900.md`：作者可读的 900 条基础明信片文本。
- `PostcardTextLibrary_1.0.6/`：1.0.6 可消耗明信片文本库原始资源；当前分支资源中灯灯文件有重复副本，生成脚本只读取无后缀版本，小熊暂沿用本地 10 条 fallback。
- `animal_profiles.json`：旧版生成器可读结构化角色库，目前不代表最新内容。
- `RelationshipMemoryShape.md`：运行时关系记忆的数据边界说明。
- `PostcardWriting_TestGuide.md`：明信片文本样张的人工审核方法。
- `PostcardSampleReview_Log.md`：样张标注、问题记录和修正版。

## 共同写作边界

- 用户“你”是远方收信人、被想起的人、明信片抵达的方向，不与旅行中的小动物发生现实同空间交互。
- 小满负责温柔克制；其他动物必须各自承担喜剧、毒舌、可爱、华丽、后勤、警觉、机灵、厚实等不同生态位。
- 明信片不写旅游介绍，而写旅行事件触发的小动物专属反应。
