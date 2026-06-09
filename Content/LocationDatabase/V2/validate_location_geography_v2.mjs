import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const detailPacks = JSON.parse(fs.readFileSync(path.join(here, "city_detail_packs_v2.json"), "utf8"));
const geography = JSON.parse(fs.readFileSync(path.join(here, "city_geography_capabilities_v2.json"), "utf8"));

const capabilityByCityId = new Map(geography.capabilities.map((capability) => [capability.cityId, capability]));
const errors = [];
const warnings = [];
const stats = {
  scannedScenes: 0,
  seasideScenes: 0,
  pierScenes: 0,
  tramScenes: 0,
  stairPathScenes: 0,
  waterfrontScenes: 0,
  citiesWithCapabilities: capabilityByCityId.size
};

const patterns = {
  seaside: /海边|沙滩|海风|浪声|冲脚/,
  pier: /轮渡|码头|港边|候船|渡船|船票|船绳/,
  seaOnly: /海边|沙滩|海风|浪声|冲脚|港边/,
  tram: /有轨电车|路面电车|电车时刻|电车铃|轨道转弯/,
  steep: /山城|陡坡|上坡小路/,
  waterfrontSeaLeak: /海边|港边|码头|轮渡|渡船|候船|船票|船绳/
};

function sceneText(scene) {
  return [
    scene.sceneName,
    scene.realWorldAnchor,
    ...(scene.sensoryDetails || []),
    ...(scene.localObjects || []),
    ...(scene.possibleEvents || []),
    ...(scene.availableActions || [])
  ].join(" ");
}

function addError(pack, scene, reason) {
  errors.push({
    cityId: pack.cityId,
    cityNameZh: pack.cityNameZh,
    sceneId: scene.sceneId,
    sceneType: scene.sceneType,
    sceneName: scene.sceneName,
    realWorldAnchor: scene.realWorldAnchor,
    reason
  });
}

for (const pack of detailPacks.cityPacks) {
  const capability = capabilityByCityId.get(pack.cityId);
  if (!capability) {
    warnings.push({ cityId: pack.cityId, cityNameZh: pack.cityNameZh, reason: "missing geography capability row" });
    continue;
  }

  for (const scene of pack.scenes) {
    stats.scannedScenes += 1;
    const text = sceneText(scene);

    if (scene.sceneType === "seaside_walk") stats.seasideScenes += 1;
    if (scene.sceneType === "pier") stats.pierScenes += 1;
    if (scene.sceneType === "tram_stop") stats.tramScenes += 1;
    if (scene.sceneType === "stair_path") stats.stairPathScenes += 1;
    if (scene.sceneType === "waterfront") stats.waterfrontScenes += 1;

    if (!capability.supportsSeaside && (scene.sceneType === "seaside_walk" || (!capability.supportsPierOrFerry && patterns.seaside.test(text)))) {
      addError(pack, scene, "city does not support seaside scenes or seaside terms");
    }

    if (!capability.supportsPierOrFerry && (scene.sceneType === "pier" || patterns.pier.test(text))) {
      addError(pack, scene, "city does not support pier/ferry scenes or pier/ferry terms");
    }

    if (!capability.isCoastal && patterns.seaOnly.test(text)) {
      addError(pack, scene, "non-coastal city contains sea-only terms");
    }

    if (!capability.supportsTram && (scene.sceneType === "tram_stop" || patterns.tram.test(text))) {
      addError(pack, scene, "city does not support tram scenes or tram terms");
    }

    if (!capability.supportsHillOrSteepStairs && (scene.sceneType === "stair_path" || patterns.steep.test(text))) {
      addError(pack, scene, "city does not support steep stair/path scenes or steep-slope terms");
    }

    if (scene.sceneType === "waterfront" && !capability.hasMajorRiverOrLake) {
      addError(pack, scene, "city does not support major river/lake waterfront scenes");
    }

    if (scene.sceneType === "waterfront" && !capability.supportsSeaside && patterns.waterfrontSeaLeak.test(text)) {
      addError(pack, scene, "inland waterfront scene contains sea/pier/ferry terms");
    }
  }
}

const result = {
  ok: errors.length === 0,
  errors,
  warnings,
  stats
};

console.log(JSON.stringify(result, null, 2));
if (!result.ok) process.exit(1);
