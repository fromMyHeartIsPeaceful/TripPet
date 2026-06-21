# TripPet 1.0.7 汇总梳理

## 基线

本地工作区从 `1.0.6` 基线继续整理，包含 `origin/1.0.6文本库` 的墩墩文本提交，以及后续几个资源与修复任务的成果。当前目标是把 1.0.6 之后已完成的内容汇总到本地 `1.0.7` 工作区分支。

## 任务来源

- `继续导入 imagegen 资源`
- `制作小动物动画GIF`
- `确认城市目的地数量`
- `完成城市目的地数量确认`
- 当前 1.0.6 修复任务

## Imagegen 明信片资源

- 新增 54 个正式项目资源：
  - 24 张高认知城市目的地图，尺寸 `940x560`
  - 12 张通用/archetype 目的地图，尺寸 `940x560`
  - 9 套小动物明信片边饰，透明 PNG，尺寸 `1080x1920`
  - 9 个小动物 motif，透明 PNG，尺寸 `160x160`
- 资源目录：
  - `TripPet/Resources/Assets.xcassets/Destinations`
  - `TripPet/Resources/Assets.xcassets/Postcards`
- 导入脚本：
  - `Tools/import_imagegen_postcard_artwork.py`
- 校验脚本更新：
  - `Tools/validate_postcard_assets.js`

## 小动物动画 GIF

- 新增正式 Bundle 资源目录：
  - `TripPet/Resources/AnimalAnimations`
- 包含 9 个透明 GIF：
  - `animal_animation_xiaoman_hamster.gif`
  - `animal_animation_tangyuan_puppy.gif`
  - `animal_animation_moji_cat.gif`
  - `animal_animation_dengdeng_rabbit.gif`
  - `animal_animation_feifei_parrot.gif`
  - `animal_animation_xiaolu_guinea_pig.gif`
  - `animal_animation_jiujiu_deer.gif`
  - `animal_animation_aini_fox.gif`
  - `animal_animation_dundun_bear.gif`
- 新增 `manifest.json`，记录 animalId、文件名、帧数和尺寸。
- `TripPet.xcodeproj/project.pbxproj` 已把 `AnimalAnimations` 加入 Copy Bundle Resources。

## 城市目的地

- 当前城市目的地目录为 300 个。
- `LocationDestinationCatalog.json` 与运行时代码保持 300 城市候选库。
- 新增/保留目的地美术映射：
  - 24 个城市特化 imagegen 目的地图
  - 12 个通用 archetype 目的地图
  - 旧 `postcard_destination_city_generic` 仍作为兜底资源，不计入本轮 54 个新增 imagegen 资源。

## 当前 1.0.6 修复合入内容

- 本地通知：
  - 赠票后按 postcard plan 的未来 `dueAt` 预排本地通知。
  - 通知点击跳转邮箱 tab。
  - 通知权限仍沿用首次明信片详情返回入口。
  - App 启动/回前台会揭示到期明信片并补排未来通知。
  - 已修复真机反馈：打开 App 时不再把过去到期明信片补排成 1 秒后的系统通知。
  - App 前台时不展示系统通知横幅，端外通知只在 App 外展示。
- 弹窗：
  - 赠送确认态和出发成功态 sheet 高度统一，减少视觉跳变。
- 邮箱：
  - 邮箱标题改为固定顶部区域。
  - 移除标题区域毛玻璃效果。
- 首次免费赠送：
  - 首次免费票 `sourceSteps == 0` 不占当天 3 次步数票限制。
  - 仍创建 ticket/trip，仍标记 `firstImmediateTicketGifted`，不扣步数。
- 墩墩文本：
  - `bear_visitor` 从 markdown 生成。
  - 文本库为 9 只小动物各 140 条，共 1,260 条。

## 已知验证

- `python3 Tools/generate_postcard_text_library.py --check`
- `Tools/validate_postcard_assets.js`
- `Tools/validate_location_destination_catalog.py`
- `xcodebuild -project TripPet.xcodeproj -list`
- `xcodebuild test -project TripPet.xcodeproj -scheme TripPet -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath BuildArtifacts/DerivedData-1.0.6-notification-fix`

## 当前分支整理说明

- 当前工作区包含已暂存的 imagegen 资源与脚本。
- 当前工作区还包含未暂存的 1.0.6 修复、GIF 资源、工程引用、文本库与 UI 调整。
- `BuildArtifacts/`、`exports/`、`.worktrees/`、`Tools/__pycache__/` 为本地构建/导出/工作区辅助目录，不属于本次汇总的正式源码内容。
