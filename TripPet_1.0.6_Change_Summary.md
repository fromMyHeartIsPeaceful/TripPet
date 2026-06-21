# TripPet 1.0.6 改动汇总

## 版本定位

1.0.6 将本轮旅行系统、地图页、明信片文本库、本地通知、礼物出发态与版本展示统一收口，作为第一版可验证的「多小动物城市旅行 + 消耗式明信片文本 + 地图去重 + 明信片提醒」版本。

## 核心改动

- 接入 `Content/LocationDatabase/V2` 的 300 城市候选库，生成运行时资源 `TripPet/Resources/LocationDestinationCatalog.json`。
- 扩展 `ManifestDestination`，支持 `latitude`、`longitude`、`countryOrRegion`、`continent`、`travelDistanceTier`，并保持旧 `ContentManifest.json` 解码兼容。
- `ContentManifestLoader` 在加载旧 manifest 后合并 300 城市目录，同 ID 目的地沿用旧资源配置，新目录补齐城市元数据与坐标。
- 新增地点目录生成与校验脚本：
  - `Tools/generate_location_destination_catalog.py`
  - `Tools/validate_location_destination_catalog.py`
- 新增城市通用兜底资源：
  - `postcard_destination_city_generic`
  - `postcard_stamp_city_generic`
  - `trip_route_map_generic`

## 旅行逻辑

- `AppRepository` 出发目的地改为从 300 城市目录随机选择。
- 新增当前活跃旅行占用判断，排除 `preparing` 与 `traveling` 中已被其他小动物占用的 `destinationId`。
- 当旧等待愿望目的地已被其他小动物占用时，送票出发前会重新分配一个可用城市。
- trip 完成后目的地自动释放，后续可再次随机抽中。
- 极端情况下没有可用地点时，`giftTicket` 返回 `nil`，不消耗票，也不更新小屋派遣状态。

## 地图页

- 新增 `TripPet/Features/Map/WorldMapView.swift`，地图页读取活跃旅行并绘制 marker。
- marker 坐标优先来自城市目录中的经纬度，不再依赖目的地硬编码分支。
- 保留巴黎、冰岛、里斯本旧坐标 fallback，未知旧目的地缺坐标时跳过 marker，避免崩溃或错误叠点。
- 地图底部新增木牌资源 `map_travel_count_sign`，固定展示当前 `x只小动物在旅行中`。

## 明信片文本库

- 新增 `TripPet/Domain/Services/PostcardTextLibrary.swift`，作为第一版可消耗明信片文本库。
- 合并 `Content/AnimalDatabase/PostcardTextLibrary_1.0.6` 作者资源，并通过 `Tools/generate_postcard_text_library.py` 生成运行时静态库。
- 文本库当前共 1,260 条：9 只小动物各 140 条；分支内重复的灯灯副本不进入生成。
- `AppRepository` 生成明信片时记录已使用 `textId`，后续不再重复展示。
- `UserStatePersistence` 持久化已消耗文本 ID。
- `PostcardScheduler` 支持传入正文覆盖，文本耗尽时回退到目的地模板。
- 新 trip 旅行总时长从 36 小时调整为 18 小时。
- 旅行中两张明信片改为出发后 2-3 小时、6-8 小时送达。

## 本地通知

- 新增 `PostcardNotificationService`，用于旅途中新增明信片的本地通知。
- 通知标题为 `邮箱收到1条新的明信片`。
- 点击通知会切换到邮箱 tab，同时保留小屋、邮箱、地图三个 tab。
- 首张免费票即时生成的机场明信片不发送通知，也不在送票成功时请求通知权限。
- 用户打开首张明信片后，点击详情页左上返回时，仅请求一次通知权限，不补发这张已展示的明信片通知。

## 小屋与邮箱 UI

- 送票成功后不再弹出旧黑色飞行 modal，原 gift sheet 直接切换为出发状态。
- gift sheet 出发态使用 `trip_route_map_generic` 与实际出发小动物资源。
- 不可用票据保留 70% 呼吸效果，同时保持禁用状态并隐藏“点击赠送”徽标。
- `Animal.travelMarkerAssetName` 统一返回 `homeAssetName`，地图 marker 与礼物出发态使用同一套小动物形象。
- 1.0.6 小动物身份统一到 9 只正式角色：小满、糖圆、墨迹、灯灯、飞飞、小炉、啾啾、埃尼、墩墩；邮箱寄件人优先从 trip 关联动物名读取，不再从旧 asset 名猜“小猫/小狗/小兔”。
- 邮箱页调整为单一滚动面，顶部固定非交互玻璃渐变。

## 版本展示

- 工程 `MARKETING_VERSION` 已更新为 `1.0.6`。
- 设置页版本文案已更新为 `1.0.6 版本`，并纳入 300 城市旅行、地图标记和可消耗明信片文本库说明。

## 测试与校验覆盖

- Repository tests：
  - 多只小动物连续出发时，活跃 trip 的 `destinationId` 不重复。
  - 已完成 trip 的目的地可再次被随机选中。
  - 旧等待 wish 指向已占用地点时，出发前会重分配。
  - 无可用地点时不创建 trip、不消耗 ticket。
  - 明信片文本不重复消耗，耗尽后回退目的地模板。
  - 18 小时旅行返回时间正确。
  - 明信片计划窗口为 2-3 小时、6-8 小时。
  - 首张即时机场明信片不发送通知。
  - 明信片详情返回只请求一次通知授权，不补发当前明信片通知。
  - 后续 reveal 新明信片时，在已授权情况下发送本地通知。
- Loader/catalog tests：
  - 300 城市全部加载。
  - 300 个城市目的地 ID 唯一。
  - 所有城市都有合法经纬度。
  - 旧 manifest 地点仍可解码。
- Map tests：
  - marker 使用 catalog 坐标。
  - 未知旧目的地不会导致崩溃。
  - 小动物旅行 marker 使用 home asset。
- Root tab tests：
  - 通知 payload 可路由到邮箱 tab。

## 已运行验证

- `Tools/validate_location_destination_catalog.py`
- `Tools/generate_postcard_text_library.py --check`
- `Content/LocationDatabase/V2/validate_location_database_v2.mjs`
- `Content/LocationDatabase/V2/validate_location_geography_v2.mjs`
- `xcodebuild test -project TripPet.xcodeproj -scheme TripPet -destination 'platform=iOS Simulator,id=0F39C893-4E39-4C55-BEA7-9F0D221D664D'`
- 真机构建：`xcodebuild build -project TripPet.xcodeproj -scheme TripPet -destination 'platform=iOS,id=BC67627A-9384-5020-AD2D-51F02D4E8C2C'`
- 真机安装：`xcrun devicectl device install app --device BC67627A-9384-5020-AD2D-51F02D4E8C2C .../TripPet.app`
