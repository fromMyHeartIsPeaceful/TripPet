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

console.log("Postcard asset validation passed.");
