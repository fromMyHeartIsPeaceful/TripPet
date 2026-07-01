#!/usr/bin/env python3
import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path


GEONAMES_SOURCE = "geonames:cities500"
MANUAL_SOURCE_PREFIX = "manual:"
GEONAMES_REF_PATTERN = re.compile(r"^https://www\.geonames\.org/\d+$")


@dataclass(frozen=True)
class CoordinateBox:
    minimum_latitude: float
    maximum_latitude: float
    minimum_longitude: float
    maximum_longitude: float

    def contains(self, latitude, longitude):
        latitude_ok = self.minimum_latitude <= latitude <= self.maximum_latitude
        if self.minimum_longitude <= self.maximum_longitude:
            longitude_ok = self.minimum_longitude <= longitude <= self.maximum_longitude
        else:
            longitude_ok = longitude >= self.minimum_longitude or longitude <= self.maximum_longitude
        return latitude_ok and longitude_ok

    def describe(self):
        return (
            f"lat {self.minimum_latitude}..{self.maximum_latitude}, "
            f"lon {self.minimum_longitude}..{self.maximum_longitude}"
        )


# These boxes are intentionally broad. They are only meant to catch severe
# country/continent-level mistakes, not city-center precision problems.
CONTINENT_BOXES = {
    "Asia": CoordinateBox(-11, 82, 25, 180),
    "Europe/Asia": CoordinateBox(35, 72, -11, 180),
    "Europe": CoordinateBox(34, 72, -25, 45),
    "North America": CoordinateBox(5, 84, -170, -50),
    "South America": CoordinateBox(-56, 13, -82, -34),
    "Africa": CoordinateBox(-35, 38, -18, 60),
    "Oceania": CoordinateBox(-50, 10, 110, -120),
}

MANUAL_COUNTRY_BOXES = {
    "哈萨克斯坦": CoordinateBox(40, 56, 46, 88),
    "日本": CoordinateBox(24, 46, 122, 146),
    "韩国": CoordinateBox(33, 39, 124, 132),
    "泰国": CoordinateBox(5, 21, 97, 106),
    "印度": CoordinateBox(6, 37, 68, 98),
}

EXPECTED_ASSET_VALUES = {
    "landmarkAssetName": "postcard_destination_city_generic",
    "stampAssetName": "postcard_stamp_city_generic",
    "routeMapAssetName": "trip_route_map_generic",
}


def read_json(path):
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def audit(candidates, destinations):
    p0_errors = []
    p1_warnings = []
    p2_notes = []

    candidate_by_id = {city.get("cityId"): city for city in candidates}
    destinations_by_id = {destination.get("id"): destination for destination in destinations}
    candidate_ids = [city.get("cityId") for city in candidates]
    destination_ids = [destination.get("id") for destination in destinations]

    if len(destinations) != len(candidates):
        p0_errors.append(f"expected {len(candidates)} destinations, found {len(destinations)}")
    if len(set(destination_ids)) != len(destination_ids):
        p0_errors.append("destination ids must be unique")
    if set(candidate_ids) != set(destination_ids):
        missing = sorted(set(candidate_ids) - set(destination_ids))
        extra = sorted(set(destination_ids) - set(candidate_ids))
        p0_errors.append(f"catalog ids mismatch, missing={missing[:10]}, extra={extra[:10]}")

    source_counts = Counter()
    country_by_prefix = defaultdict(set)
    same_country_names = defaultdict(list)
    rounded_coordinates = defaultdict(list)
    geonames_entries = []
    manual_entries = []

    for destination in destinations:
        destination_id = destination.get("id", "<missing>")
        candidate = candidate_by_id.get(destination_id)
        latitude = destination.get("latitude")
        longitude = destination.get("longitude")
        source = destination.get("coordinateSource")
        source_ref = destination.get("coordinateSourceRef")

        source_counts[source or "<missing>"] += 1
        country_by_prefix[destination_id.split("_", 1)[0]].add(destination.get("countryOrRegion"))
        same_country_names[(destination.get("displayName"), destination.get("countryOrRegion"))].append(destination_id)

        if isinstance(latitude, (int, float)) and isinstance(longitude, (int, float)):
            rounded_coordinates[(round(latitude, 4), round(longitude, 4))].append(destination_id)
        else:
            p0_errors.append(f"{destination_id} has non-numeric coordinate {latitude!r},{longitude!r}")
            continue

        if not -90 <= latitude <= 90:
            p0_errors.append(f"{destination_id} has invalid latitude {latitude!r}")
        if not -180 <= longitude <= 180:
            p0_errors.append(f"{destination_id} has invalid longitude {longitude!r}")

        if candidate:
            if candidate.get("countryOrRegion") != destination.get("countryOrRegion"):
                p0_errors.append(
                    f"{destination_id} country mismatch "
                    f"candidate={candidate.get('countryOrRegion')} catalog={destination.get('countryOrRegion')}"
                )
            if candidate.get("continent") != destination.get("continent"):
                p0_errors.append(
                    f"{destination_id} continent mismatch "
                    f"candidate={candidate.get('continent')} catalog={destination.get('continent')}"
                )

        for key, expected_value in EXPECTED_ASSET_VALUES.items():
            if destination.get(key) != expected_value:
                p1_warnings.append(f"{destination_id} {key} is {destination.get(key)!r}, expected {expected_value!r}")

        continent = destination.get("continent")
        continent_box = CONTINENT_BOXES.get(continent)
        if continent_box and not continent_box.contains(latitude, longitude):
            p0_errors.append(
                f"{destination_id} {destination.get('displayName')} outside coarse "
                f"{continent} box ({latitude},{longitude}); {continent_box.describe()}"
            )

        if source == GEONAMES_SOURCE:
            geonames_entries.append(destination)
            if not isinstance(source_ref, str) or not GEONAMES_REF_PATTERN.match(source_ref):
                p0_errors.append(f"{destination_id} has invalid GeoNames sourceRef {source_ref!r}")
        elif isinstance(source, str) and source.startswith(MANUAL_SOURCE_PREFIX):
            manual_entries.append(destination)
            country = destination.get("countryOrRegion")
            country_box = MANUAL_COUNTRY_BOXES.get(country)
            if country_box and not country_box.contains(latitude, longitude):
                p0_errors.append(
                    f"{destination_id} {destination.get('displayName')} outside coarse "
                    f"{country} box ({latitude},{longitude}); {country_box.describe()}"
                )
            elif country_box is None:
                p1_warnings.append(f"{destination_id} manual coordinate has no coarse country box for {country}")
        else:
            p0_errors.append(f"{destination_id} has unexpected coordinateSource {source!r}")

    for prefix, countries in sorted(country_by_prefix.items()):
        clean_countries = {country for country in countries if country}
        if len(clean_countries) > 1:
            p0_errors.append(f"id prefix {prefix!r} maps to multiple countries/regions: {sorted(clean_countries)}")

    duplicate_names = [
        (key, ids)
        for key, ids in same_country_names.items()
        if len(ids) > 1 and key[0] and key[1]
    ]
    for (display_name, country), ids in duplicate_names:
        p1_warnings.append(f"duplicate same-country destination name {display_name}/{country}: {ids}")

    duplicate_coordinates = [
        (coordinate, ids)
        for coordinate, ids in rounded_coordinates.items()
        if len(ids) > 1
    ]
    for coordinate, ids in duplicate_coordinates:
        p0_errors.append(f"duplicate rounded coordinate {coordinate}: {ids}")

    p2_notes.append(f"{len(geonames_entries)} destinations use {GEONAMES_SOURCE}")
    p2_notes.append(f"{len(manual_entries)} destinations use {MANUAL_SOURCE_PREFIX} coordinates")
    p2_notes.append(f"{len(set(destination.get('countryOrRegion') for destination in destinations))} countries/regions")

    return p0_errors, p1_warnings, p2_notes, source_counts


def print_section(title, items):
    print(title)
    if items:
        for item in items:
            print(f"- {item}")
    else:
        print("- none")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--candidate-pool", default="Content/LocationDatabase/V2/city_candidate_pool_v2.json")
    parser.add_argument("--catalog", default="TripPet/Resources/LocationDestinationCatalog.json")
    args = parser.parse_args()

    root = Path.cwd()
    candidates = read_json(root / args.candidate_pool)["cities"]
    destinations = read_json(root / args.catalog).get("destinations", [])

    p0_errors, p1_warnings, p2_notes, source_counts = audit(candidates, destinations)

    print("Location destination coordinate audit")
    print(f"candidate destinations: {len(candidates)}")
    print(f"catalog destinations: {len(destinations)}")
    print("coordinate sources:")
    for source, count in sorted(source_counts.items()):
        print(f"- {source}: {count}")
    print_section("P0 severe coordinate/data issues", p0_errors)
    print_section("P1 manual review warnings", p1_warnings)
    print_section("P2 accepted notes", p2_notes)

    if p0_errors:
        return 1
    print("Coordinate audit passed with no severe country-level issues")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
