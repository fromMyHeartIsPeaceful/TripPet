# 关系记忆数据形状

关系记忆是运行时状态，必须和 `animal_profiles.json` 分离。静态角色库可以随版本更新，关系记忆则属于某个用户和某只小动物之间的历史。

## 最小字段

```json
{
  "animalId": "xiaoman_hamster",
  "encounterCount": 0,
  "relationshipStage": "stranger",
  "tripCount": 0,
  "visitedLocationIds": [],
  "visitedCityIds": [],
  "recentSceneIds": [],
  "recentEventIds": [],
  "sentPostcardIds": [],
  "recentlyUsedMotifs": [],
  "unlockedClueIds": [],
  "revealedSecretIds": [],
  "favoritedPostcardIds": []
}
```

## 更新规则

- `relationshipStage` 由见面次数、旅行次数、收藏行为和长期事件共同推进，不由单张明信片直接跳级。
- `recentlyUsedMotifs` 用于意象冷却，建议保留最近 5-8 次出现记录。
- `unlockedClueIds` 表示线索可以被提及，不等于秘密已经说破。
- `revealedSecretIds` 只能由高关系阶段和合适揭示预算写入。
- 用户步数下降不能触发更重文本，只能降低深层卡权重或转向轻日常。

## V2 地点访问记忆

地点数据库 V2 引入 `cityId`、`sceneId` 和 `eventId` 后，关系记忆建议记录更细的地点访问历史。

建议新增：

```json
{
  "visitedCityIds": ["cn_shanghai"],
  "recentSceneIds": ["cn_shanghai_central_transit"],
  "recentEventIds": ["transport_waiting_01"],
  "favoriteCityIds": [],
  "postcardLocationHistory": [
    {
      "postcardId": "local-generated-id",
      "cityId": "cn_shanghai",
      "sceneId": "cn_shanghai_central_transit",
      "eventId": "transport_waiting_01",
      "animalId": "xiaoman_hamster",
      "createdAt": "local timestamp"
    }
  ]
}
```

用途：

- 避免同一小动物短期重复去同一城市。
- 避免连续复用同一场景或生活事件。
- 支持关系阶段较高时的地点回访；地点回访只影响权重和可回声线索，不作为特殊触发，也不额外增加明信片数量。
- 支持用户收藏过的城市或明信片形成轻量偏好。

这些字段只记录历史，不改变地点事实，也不让系统根据用户状态推送沉重文本。
