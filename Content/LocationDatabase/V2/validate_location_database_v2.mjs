import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const candidates = JSON.parse(fs.readFileSync(path.join(here, "city_candidate_pool_v2.json"), "utf8"));
const detailPacks = JSON.parse(fs.readFileSync(path.join(here, "city_detail_packs_v2.json"), "utf8"));
const events = JSON.parse(fs.readFileSync(path.join(here, "scene_event_library_v2.json"), "utf8"));
const geography = JSON.parse(fs.readFileSync(path.join(here, "city_geography_capabilities_v2.json"), "utf8"));

const issues = [];
const forbiddenPhrases = [
  ["中央车站", "或主要换乘口"].join(""),
  ["知名地点边缘", "的普通角落"].join(""),
  ["便利店、甜品店", "或咖啡店"].join(""),
  ["老街、旧门牌", "或巷口"].join(""),
  ["河边、湖边", "或港口栏杆"].join("")
];
const forbidden = new RegExp(forbiddenPhrases.join("|"));

if (candidates.cities.length !== 300) issues.push(`city candidates: ${candidates.cities.length}`);
if (detailPacks.cityPacks.length !== 300) issues.push(`city packs: ${detailPacks.cityPacks.length}`);
if (events.events.length !== 100) issues.push(`events: ${events.events.length}`);
if (geography.capabilities.length !== 300) issues.push(`geography capabilities: ${geography.capabilities.length}`);

const totalScenes = detailPacks.cityPacks.reduce((sum, pack) => sum + pack.scenes.length, 0);
if (totalScenes !== 3000) issues.push(`total scenes: ${totalScenes}`);

if (forbidden.test(JSON.stringify(candidates)) || forbidden.test(JSON.stringify(detailPacks))) {
  issues.push("old template text remains");
}

const tagSets = new Map();
for (const city of candidates.cities) {
  const tagKey = (city.modernLifeTags || []).join("|");
  tagSets.set(tagKey, (tagSets.get(tagKey) || 0) + 1);
  if ((city.modernLifeTags || []).some((tag) => /^[a-z]+_[a-z_]+$/.test(tag))) {
    issues.push(`english enum leaked into modernLifeTags: ${city.cityId}`);
  }
}

const sceneNameBases = new Map();
let minTypesPerCity = Infinity;
let maxFamousPerCity = 0;
let minSensoryDetails = Infinity;
let minLocalObjects = Infinity;
let minAvailableActions = Infinity;
let scenesWithoutSources = 0;
let needsHumanFinalReview = 0;

for (const pack of detailPacks.cityPacks) {
  if (pack.scenes.length !== 10) issues.push(`${pack.cityId} scenes: ${pack.scenes.length}`);

  const types = new Set(pack.scenes.map((scene) => scene.sceneType));
  minTypesPerCity = Math.min(minTypesPerCity, types.size);
  if (types.size < 7) issues.push(`${pack.cityId} scene types: ${types.size}`);

  const famousCount = pack.scenes.filter((scene) => scene.isFamousPlace).length;
  maxFamousPerCity = Math.max(maxFamousPerCity, famousCount);
  if (famousCount > 2) issues.push(`${pack.cityId} famous scenes: ${famousCount}`);

  for (const scene of pack.scenes) {
    minSensoryDetails = Math.min(minSensoryDetails, scene.sensoryDetails?.length ?? 0);
    minLocalObjects = Math.min(minLocalObjects, scene.localObjects?.length ?? 0);
    minAvailableActions = Math.min(minAvailableActions, scene.availableActions?.length ?? 0);
    if ((scene.sensoryDetails || []).length < 4) issues.push(`${scene.sceneId} sensoryDetails < 4`);
    if ((scene.localObjects || []).length < 5) issues.push(`${scene.sceneId} localObjects < 5`);
    if ((scene.availableActions || []).length < 4) issues.push(`${scene.sceneId} availableActions < 4`);
    if (!scene.sourceRefs?.length) scenesWithoutSources += 1;
    if (scene.verificationStatus === "needs_human_final_review") needsHumanFinalReview += 1;

    const cityName = pack.cityNameZh.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const localName = (pack.cityNameLocal || "").replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    let base = scene.sceneName.replace(new RegExp(cityName, "g"), "{city}");
    if (localName) base = base.replace(new RegExp(localName, "g"), "{local}");
    sceneNameBases.set(base, (sceneNameBases.get(base) || 0) + 1);
  }
}

const maxTagSetReuse = Math.max(...tagSets.values());
if (maxTagSetReuse > 1) issues.push(`shared modernLifeTags set max: ${maxTagSetReuse}`);

const topSceneNameBases = [...sceneNameBases.entries()].sort((a, b) => b[1] - a[1]).slice(0, 10);
const maxSceneNameBaseReuse = topSceneNameBases[0]?.[1] || 0;
if (maxSceneNameBaseReuse > 25) issues.push(`sceneName base reuse max: ${maxSceneNameBaseReuse}`);

const eventNames = new Map();
for (const event of events.events) eventNames.set(event.eventName, (eventNames.get(event.eventName) || 0) + 1);
const duplicateEventNames = [...eventNames.entries()].filter(([, count]) => count > 1);
if (duplicateEventNames.length) issues.push(`duplicate event names: ${duplicateEventNames.length}`);

const result = {
  ok: issues.length === 0,
  issues,
  stats: {
    cityCandidates: candidates.cities.length,
    cityPacks: detailPacks.cityPacks.length,
    totalScenes,
    events: events.events.length,
    geographyCapabilities: geography.capabilities.length,
    uniqueModernLifeTagSets: tagSets.size,
    maxTagSetReuse,
    minTypesPerCity,
    maxFamousPerCity,
    minSensoryDetails,
    minLocalObjects,
    minAvailableActions,
    scenesWithoutSources,
    needsHumanFinalReview,
    uniqueSceneNameBases: sceneNameBases.size,
    maxSceneNameBaseReuse,
    duplicateEventNames: duplicateEventNames.length
  }
};

console.log(JSON.stringify(result, null, 2));
if (!result.ok) process.exit(1);
