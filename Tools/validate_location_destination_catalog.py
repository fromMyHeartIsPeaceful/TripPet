#!/usr/bin/env python3
import argparse
import json
import sys
from pathlib import Path


REQUIRED_ASSETS = {
    "landmarkAssetName": "postcard_destination_city_generic",
    "stampAssetName": "postcard_stamp_city_generic",
    "routeMapAssetName": "trip_route_map_generic",
}


def read_json(path):
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--candidate-pool", default="Content/LocationDatabase/V2/city_candidate_pool_v2.json")
    parser.add_argument("--catalog", default="TripPet/Resources/LocationDestinationCatalog.json")
    args = parser.parse_args()

    root = Path.cwd()
    candidates = read_json(root / args.candidate_pool)["cities"]
    catalog = read_json(root / args.catalog)
    destinations = catalog.get("destinations", [])
    errors = []

    candidate_ids = [city["cityId"] for city in candidates]
    destination_ids = [destination.get("id") for destination in destinations]

    if len(destinations) != len(candidates):
        errors.append(f"expected {len(candidates)} destinations, found {len(destinations)}")
    if len(set(destination_ids)) != len(destination_ids):
        errors.append("destination ids must be unique")
    if set(candidate_ids) != set(destination_ids):
        missing = sorted(set(candidate_ids) - set(destination_ids))
        extra = sorted(set(destination_ids) - set(candidate_ids))
        errors.append(f"catalog ids mismatch, missing={missing[:10]}, extra={extra[:10]}")

    for destination in destinations:
        destination_id = destination.get("id", "<missing>")
        latitude = destination.get("latitude")
        longitude = destination.get("longitude")
        if not isinstance(latitude, (int, float)) or not -90 <= latitude <= 90:
            errors.append(f"{destination_id} has invalid latitude {latitude!r}")
        if not isinstance(longitude, (int, float)) or not -180 <= longitude <= 180:
            errors.append(f"{destination_id} has invalid longitude {longitude!r}")
        for key, value in REQUIRED_ASSETS.items():
            if destination.get(key) != value:
                errors.append(f"{destination_id} {key} must be {value}")
        for key in ("displayName", "countryOrRegion", "continent", "travelDistanceTier"):
            if not destination.get(key):
                errors.append(f"{destination_id} missing {key}")

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print(f"{len(destinations)} location destinations are valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
