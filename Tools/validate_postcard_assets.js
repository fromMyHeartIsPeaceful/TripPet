#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..");

const requiredPngs = [
  {
    file: "TripPet/Resources/Assets.xcassets/Postcards/postcard_base_portrait.imageset/postcard_base_portrait@3x.png",
    width: 1080,
    height: 1920,
  },
  {
    file: "TripPet/Resources/Assets.xcassets/Destinations/postcard_destination_paris.imageset/postcard_destination_paris@3x.png",
    width: 940,
    height: 560,
  },
  {
    file: "TripPet/Resources/Assets.xcassets/Destinations/postcard_destination_reykjavik.imageset/postcard_destination_reykjavik@3x.png",
    width: 940,
    height: 560,
  },
  {
    file: "TripPet/Resources/Assets.xcassets/Destinations/postcard_destination_lisbon.imageset/postcard_destination_lisbon@3x.png",
    width: 940,
    height: 560,
  },
  {
    file: "TripPet/Resources/Assets.xcassets/Destinations/postcard_destination_airport.imageset/postcard_destination_airport@3x.png",
    width: 940,
    height: 560,
  },
];

const requiredNames = [
  "postcard_base_portrait",
  "postcard_destination_airport",
  "postcard_destination_lisbon",
  "postcard_destination_paris",
  "postcard_destination_reykjavik",
  "postcard_stamp_airport",
  "postcard_stamp_lisbon",
  "postcard_stamp_paris",
  "postcard_stamp_reykjavik",
];

const animalStyleKeys = [
  "xiaoman_hamster",
  "tangyuan_puppy",
  "moji_cat",
  "dengdeng_rabbit",
  "feifei_parrot",
  "xiaolu_guinea_pig",
  "deer_visitor",
  "fox_visitor",
  "bear_visitor",
];

const archetypeArtworkNames = [
  "postcard_destination_archetype_east_asia_city",
  "postcard_destination_archetype_european_old_town",
  "postcard_destination_archetype_harbor",
  "postcard_destination_archetype_snow",
  "postcard_destination_archetype_desert",
  "postcard_destination_archetype_mountain",
  "postcard_destination_archetype_tropical",
  "postcard_destination_archetype_north_america_street",
  "postcard_destination_archetype_river_lake",
  "postcard_destination_archetype_modern_skyline",
  "postcard_destination_archetype_historic_market",
  "postcard_destination_archetype_oceania_coast",
];

const cityDestinationArtwork = {
  cn_beijing: "postcard_destination_city_beijing",
  cn_shanghai: "postcard_destination_city_shanghai",
  jp_tokyo: "postcard_destination_city_tokyo",
  jp_kyoto: "postcard_destination_city_kyoto",
  kr_seoul: "postcard_destination_city_seoul",
  cn_hongkong: "postcard_destination_city_hongkong",
  sg_singapore: "postcard_destination_city_singapore",
  fr_paris: "postcard_destination_city_paris",
  uk_london: "postcard_destination_city_london",
  it_rome: "postcard_destination_city_rome",
  it_venice: "postcard_destination_city_venice",
  es_barcelona: "postcard_destination_city_barcelona",
  nl_amsterdam: "postcard_destination_city_amsterdam",
  us_new_york: "postcard_destination_city_new_york",
  us_los_angeles: "postcard_destination_city_los_angeles",
  us_san_francisco: "postcard_destination_city_san_francisco",
  ca_vancouver: "postcard_destination_city_vancouver",
  au_sydney: "postcard_destination_city_sydney",
  au_melbourne: "postcard_destination_city_melbourne",
  tr_istanbul: "postcard_destination_city_istanbul",
  eg_cairo: "postcard_destination_city_cairo",
  br_rio: "postcard_destination_city_rio",
  za_cape_town: "postcard_destination_city_cape_town",
  is_reykjavik: "postcard_destination_city_reykjavik",
};

function pngSize(filePath) {
  const buffer = fs.readFileSync(filePath);
  const pngSignature = "89504e470d0a1a0a";
  if (buffer.subarray(0, 8).toString("hex") !== pngSignature) {
    throw new Error(`${filePath} is not a PNG`);
  }
  return {
    width: buffer.readUInt32BE(16),
    height: buffer.readUInt32BE(20),
  };
}

function assertAssetExists(name) {
  const matches = findAssetDirs(path.join(root, "TripPet/Resources/Assets.xcassets"), `${name}.imageset`);
  if (matches.length === 0) {
    throw new Error(`Missing asset catalog imageset: ${name}`);
  }
}

function assertPngAsset(name, width, height) {
  assertAssetExists(name);
  const matches = findAssetDirs(path.join(root, "TripPet/Resources/Assets.xcassets"), `${name}.imageset`);
  const png = path.join(matches[0], `${name}@3x.png`);
  if (!fs.existsSync(png)) {
    throw new Error(`Missing @3x PNG for asset: ${name}`);
  }
  const actual = pngSize(png);
  if (actual.width !== width || actual.height !== height) {
    throw new Error(`${name} must be ${width}x${height}, got ${actual.width}x${actual.height}`);
  }
}

function findAssetDirs(dir, targetName, matches = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === targetName) {
        matches.push(fullPath);
      }
      findAssetDirs(fullPath, targetName, matches);
    }
  }
  return matches;
}

for (const name of requiredNames) {
  assertAssetExists(name);
}

for (const expected of requiredPngs) {
  const filePath = path.join(root, expected.file);
  if (!fs.existsSync(filePath)) {
    throw new Error(`Missing PNG: ${expected.file}`);
  }
  const actual = pngSize(filePath);
  if (actual.width !== expected.width || actual.height !== expected.height) {
    throw new Error(
      `${expected.file} must be ${expected.width}x${expected.height}, got ${actual.width}x${actual.height}`
    );
  }
}

for (const animalKey of animalStyleKeys) {
  assertPngAsset(`postcard_edge_${animalKey}`, 1080, 1920);
  assertPngAsset(`postcard_motif_${animalKey}`, 160, 160);
}

for (const name of archetypeArtworkNames) {
  assertPngAsset(name, 940, 560);
}

for (const name of Object.values(cityDestinationArtwork)) {
  assertPngAsset(name, 940, 560);
}

const fontFile = path.join(root, "TripPet/Resources/Fonts/LXGWWenKaiScreen.ttf");
if (!fs.existsSync(fontFile)) {
  throw new Error("Missing bundled postcard font: LXGWWenKaiScreen.ttf");
}

function archetypeArtworkName(destination) {
  const id = destination.id;
  const country = destination.countryOrRegion || "";
  const continent = destination.continent || "";
  if (id.startsWith("jp_") || id.startsWith("kr_") || id.startsWith("cn_") || id.startsWith("sg_")) {
    return "postcard_destination_archetype_east_asia_city";
  }
  if (id.startsWith("is_") || id.startsWith("no_") || id.startsWith("fi_") || id.startsWith("se_") || id.startsWith("ca_")) {
    return "postcard_destination_archetype_snow";
  }
  if (id.startsWith("eg_") || id.startsWith("ma_") || id.startsWith("ae_") || id.startsWith("qa_")) {
    return "postcard_destination_archetype_desert";
  }
  if (id.startsWith("br_") || id.startsWith("th_") || id.startsWith("id_") || id.startsWith("my_")) {
    return "postcard_destination_archetype_tropical";
  }
  if (id.startsWith("au_") || id.startsWith("nz_")) {
    return "postcard_destination_archetype_oceania_coast";
  }
  if (id.startsWith("us_") || id.startsWith("mx_")) {
    return "postcard_destination_archetype_north_america_street";
  }
  if (country.includes("土耳其") || country.includes("埃及") || continent === "Africa") {
    return "postcard_destination_archetype_historic_market";
  }
  if (continent === "Europe" || continent === "Europe/Asia") {
    return "postcard_destination_archetype_european_old_town";
  }
  if (continent === "Oceania") {
    return "postcard_destination_archetype_oceania_coast";
  }
  if (continent === "North America") {
    return "postcard_destination_archetype_north_america_street";
  }
  if (continent === "South America") {
    return "postcard_destination_archetype_tropical";
  }
  return "postcard_destination_archetype_modern_skyline";
}

const catalog = JSON.parse(fs.readFileSync(path.join(root, "TripPet/Resources/LocationDestinationCatalog.json"), "utf8"));
if (!Array.isArray(catalog.destinations) || catalog.destinations.length !== 300) {
  throw new Error(`Expected 300 location destinations, found ${catalog.destinations?.length}`);
}

for (const destination of catalog.destinations) {
  const artworkName = cityDestinationArtwork[destination.id] || archetypeArtworkName(destination);
  assertAssetExists(artworkName);
}

console.log("Postcard asset validation passed.");
