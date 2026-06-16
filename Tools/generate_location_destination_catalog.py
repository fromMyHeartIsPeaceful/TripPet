#!/usr/bin/env python3
import argparse
import io
import json
import time
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
import zipfile
from pathlib import Path


DEFAULT_PRIMARY_COLOR = "#7AA7B8"
USER_AGENT = "TripPetLocationCatalog/1.0 (https://example.invalid/trippet)"
GEONAMES_CITIES_URL = "https://download.geonames.org/export/dump/cities500.zip"


COUNTRY_HINTS = {
    "中国": "China",
    "日本": "Japan",
    "韩国": "South Korea",
    "泰国": "Thailand",
    "越南": "Vietnam",
    "新加坡": "Singapore",
    "马来西亚": "Malaysia",
    "印度尼西亚": "Indonesia",
    "菲律宾": "Philippines",
    "印度": "India",
    "尼泊尔": "Nepal",
    "阿联酋": "United Arab Emirates",
    "土耳其": "Turkey",
    "英国": "United Kingdom",
    "法国": "France",
    "德国": "Germany",
    "意大利": "Italy",
    "西班牙": "Spain",
    "葡萄牙": "Portugal",
    "荷兰": "Netherlands",
    "比利时": "Belgium",
    "瑞士": "Switzerland",
    "奥地利": "Austria",
    "捷克": "Czechia",
    "匈牙利": "Hungary",
    "希腊": "Greece",
    "冰岛": "Iceland",
    "爱尔兰": "Ireland",
    "丹麦": "Denmark",
    "挪威": "Norway",
    "瑞典": "Sweden",
    "芬兰": "Finland",
    "波兰": "Poland",
    "美国": "United States",
    "加拿大": "Canada",
    "墨西哥": "Mexico",
    "巴西": "Brazil",
    "阿根廷": "Argentina",
    "智利": "Chile",
    "秘鲁": "Peru",
    "哥伦比亚": "Colombia",
    "澳大利亚": "Australia",
    "新西兰": "New Zealand",
    "埃及": "Egypt",
    "摩洛哥": "Morocco",
    "南非": "South Africa",
}

COUNTRY_HINTS.update(
    {
        "中国台湾": "Taiwan",
        "中国香港": "Hong Kong",
        "中国澳门": "Macau",
        "蒙古": "Mongolia",
        "柬埔寨": "Cambodia",
        "老挝": "Laos",
        "缅甸": "Myanmar",
        "文莱": "Brunei",
        "东帝汶": "Timor-Leste",
        "不丹": "Bhutan",
        "马尔代夫": "Maldives",
        "斯里兰卡": "Sri Lanka",
        "孟加拉国": "Bangladesh",
        "巴基斯坦": "Pakistan",
        "伊朗": "Iran",
        "伊拉克": "Iraq",
        "哈萨克斯坦": "Kazakhstan",
        "乌兹别克斯坦": "Uzbekistan",
        "以色列": "Israel",
        "约旦": "Jordan",
        "黎巴嫩": "Lebanon",
        "阿塞拜疆": "Azerbaijan",
        "格鲁吉亚": "Georgia",
        "亚美尼亚": "Armenia",
        "沙特阿拉伯": "Saudi Arabia",
        "阿曼": "Oman",
        "巴林": "Bahrain",
        "科威特": "Kuwait",
        "塞浦路斯": "Cyprus",
        "克罗地亚": "Croatia",
        "乌克兰": "Ukraine",
        "罗马尼亚": "Romania",
        "保加利亚": "Bulgaria",
        "塞尔维亚": "Serbia",
        "斯洛文尼亚": "Slovenia",
        "爱沙尼亚": "Estonia",
        "拉脱维亚": "Latvia",
        "立陶宛": "Lithuania",
        "马耳他": "Malta",
        "阿尔巴尼亚": "Albania",
        "北马其顿": "North Macedonia",
        "波黑": "Bosnia and Herzegovina",
        "黑山": "Montenegro",
        "斯洛伐克": "Slovakia",
        "摩尔多瓦": "Moldova",
        "白俄罗斯": "Belarus",
        "卢森堡": "Luxembourg",
        "摩纳哥": "Monaco",
        "列支敦士登": "Liechtenstein",
        "圣马力诺": "San Marino",
        "安道尔": "Andorra",
        "古巴": "Cuba",
        "巴拿马": "Panama",
        "哥斯达黎加": "Costa Rica",
        "危地马拉": "Guatemala",
        "萨尔瓦多": "El Salvador",
        "洪都拉斯": "Honduras",
        "尼加拉瓜": "Nicaragua",
        "多米尼加": "Dominican Republic",
        "牙买加": "Jamaica",
        "特立尼达和多巴哥": "Trinidad and Tobago",
        "巴哈马": "Bahamas",
        "圭亚那": "Guyana",
        "苏里南": "Suriname",
        "玻利维亚": "Bolivia",
        "巴拉圭": "Paraguay",
        "乌干达": "Uganda",
        "卢旺达": "Rwanda",
        "坦桑尼亚": "Tanzania",
        "埃塞俄比亚": "Ethiopia",
        "尼日利亚": "Nigeria",
        "加纳": "Ghana",
        "塞内加尔": "Senegal",
        "突尼斯": "Tunisia",
        "阿尔及利亚": "Algeria",
        "毛里求斯": "Mauritius",
        "安哥拉": "Angola",
        "喀麦隆": "Cameroon",
        "科特迪瓦": "Côte d'Ivoire",
        "马达加斯加": "Madagascar",
        "莫桑比克": "Mozambique",
        "赞比亚": "Zambia",
        "津巴布韦": "Zimbabwe",
        "纳米比亚": "Namibia",
        "博茨瓦纳": "Botswana",
        "苏丹": "Sudan",
        "斐济": "Fiji",
        "巴布亚新几内亚": "Papua New Guinea",
        "新喀里多尼亚": "New Caledonia",
        "法属波利尼西亚": "French Polynesia",
        "萨摩亚": "Samoa",
        "汤加": "Tonga",
        "瓦努阿图": "Vanuatu",
    }
)


def read_json(path):
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def write_json(path, payload):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, ensure_ascii=False, indent=2)
        handle.write("\n")


def request_json(url, timeout=20):
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return json.loads(response.read().decode("utf-8"))


def request_bytes(url, timeout=90):
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return response.read()


def post_json(url, payload, timeout=90):
    data = urllib.parse.urlencode(payload).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=data,
        headers={
            "User-Agent": USER_AGENT,
            "Content-Type": "application/x-www-form-urlencoded",
            "Accept": "application/sparql-results+json",
        },
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return json.loads(response.read().decode("utf-8"))


def parse_wikidata_point(point):
    prefix = "Point("
    if not point.startswith(prefix) or not point.endswith(")"):
        return None
    longitude, latitude = point[len(prefix) : -1].split()
    return round(float(latitude), 6), round(float(longitude), 6)


def country_matches(candidate_country, result_country):
    if not result_country:
        return False
    normalized_result = result_country.lower()
    hints = {candidate_country.lower()}
    if candidate_country in COUNTRY_HINTS:
        hints.add(COUNTRY_HINTS[candidate_country].lower())
    return any(hint in normalized_result for hint in hints)


def sparql_string_literal(value):
    return value.replace("\\", "\\\\").replace('"', '\\"')


def batch_wikidata_coordinates(cities):
    values = "\n".join(
        f'    "{sparql_string_literal(city["cityNameLocal"])}"@en'
        for city in cities
    )
    query = f"""
SELECT ?input ?city ?countryLabel ?coord WHERE {{
  VALUES ?input {{
{values}
  }}
  ?city rdfs:label ?input;
        wdt:P625 ?coord.
  OPTIONAL {{ ?city wdt:P17 ?country. }}
  SERVICE wikibase:label {{ bd:serviceParam wikibase:language "zh,en". }}
}}
"""
    data = post_json("https://query.wikidata.org/sparql", {"query": query, "format": "json"})
    by_name = {}
    for binding in data.get("results", {}).get("bindings", []):
        city_name = binding.get("input", {}).get("value")
        country_label = binding.get("countryLabel", {}).get("value", "")
        coordinate_value = binding.get("coord", {}).get("value", "")
        parsed = parse_wikidata_point(coordinate_value)
        entity_url = binding.get("city", {}).get("value", "")
        if city_name and parsed:
            by_name.setdefault(city_name, []).append((country_label, parsed, entity_url))

    coordinates = {}
    for city in cities:
        matches = by_name.get(city["cityNameLocal"], [])
        if not matches:
            continue
        match = next(
            (item for item in matches if country_matches(city["countryOrRegion"], item[0])),
            None,
        )
        if match is None:
            continue
        latitude, longitude = match[1]
        coordinates[city["cityId"]] = {
            "latitude": latitude,
            "longitude": longitude,
            "source": "wikidata:sparql:P625",
            "sourceRef": match[2],
        }
    return coordinates


def wikidata_entity_ids(city):
    country = COUNTRY_HINTS.get(city["countryOrRegion"], city["countryOrRegion"])
    queries = [
        f"{city['cityNameLocal']} {country}",
        f"{city['cityNameZh']} {city['countryOrRegion']}",
        city["cityNameLocal"],
    ]
    seen = set()
    for query in queries:
        params = urllib.parse.urlencode(
            {
                "action": "wbsearchentities",
                "format": "json",
                "language": "en",
                "uselang": "en",
                "type": "item",
                "limit": 8,
                "search": query,
            }
        )
        data = request_json(f"https://www.wikidata.org/w/api.php?{params}")
        for result in data.get("search", []):
            entity_id = result.get("id")
            if entity_id and entity_id not in seen:
                seen.add(entity_id)
                yield entity_id


def coordinate_from_entity(entity):
    claims = entity.get("claims", {})
    coordinates = claims.get("P625", [])
    if not coordinates:
        return None
    value = coordinates[0].get("mainsnak", {}).get("datavalue", {}).get("value")
    if not value:
        return None
    return {
        "latitude": round(float(value["latitude"]), 6),
        "longitude": round(float(value["longitude"]), 6),
        "source": "wikidata:P625",
    }


def wikidata_coordinate(city):
    for entity_id in wikidata_entity_ids(city):
        data = request_json(f"https://www.wikidata.org/wiki/Special:EntityData/{entity_id}.json")
        entity = data.get("entities", {}).get(entity_id, {})
        coordinate = coordinate_from_entity(entity)
        if coordinate:
            coordinate["sourceRef"] = f"https://www.wikidata.org/wiki/{entity_id}"
            return coordinate
    return None


def nominatim_coordinate(city):
    country = COUNTRY_HINTS.get(city["countryOrRegion"], city["countryOrRegion"])
    query = f"{city['cityNameLocal']}, {country}"
    params = urllib.parse.urlencode({"format": "jsonv2", "limit": 1, "q": query})
    data = request_json(f"https://nominatim.openstreetmap.org/search?{params}")
    if not data:
        return None
    result = data[0]
    return {
        "latitude": round(float(result["lat"]), 6),
        "longitude": round(float(result["lon"]), 6),
        "source": "openstreetmap:nominatim",
        "sourceRef": f"https://www.openstreetmap.org/{result.get('osm_type', 'node')}/{result.get('osm_id', '')}",
    }


COUNTRY_CODE_OVERRIDES = {
    "uk": "GB",
}

COUNTRY_CODE_BY_REGION = {
    "中国香港": "HK",
    "中国澳门": "MO",
    "中国台湾": "TW",
}


def expected_country_code(city):
    if city["countryOrRegion"] in COUNTRY_CODE_BY_REGION:
        return COUNTRY_CODE_BY_REGION[city["countryOrRegion"]]
    prefix = city["cityId"].split("_", 1)[0]
    return COUNTRY_CODE_OVERRIDES.get(prefix, prefix.upper())


def normalized_name(value):
    folded = unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode("ascii")
    return "".join(character.lower() for character in folded if character.isalnum())


def geonames_entries(url):
    data = request_bytes(url)
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        text_name = next(name for name in archive.namelist() if name.endswith(".txt"))
        with archive.open(text_name) as handle:
            for raw_line in handle:
                fields = raw_line.decode("utf-8").rstrip("\n").split("\t")
                if len(fields) < 15:
                    continue
                names = [
                    normalized_name(name)
                    for name in [fields[1], fields[2]] + fields[3].split(",")
                    if name
                ]
                yield {
                    "names": {name for name in names if name},
                    "latitude": round(float(fields[4]), 6),
                    "longitude": round(float(fields[5]), 6),
                    "countryCode": fields[8],
                    "population": int(fields[14] or 0),
                    "geonameId": fields[0],
                }


def geonames_coordinates(cities, url):
    entries_by_country = {}
    for entry in geonames_entries(url):
        entries_by_country.setdefault(entry["countryCode"], []).append(entry)

    coordinates = {}
    for city in cities:
        country_code = expected_country_code(city)
        candidates = entries_by_country.get(country_code, [])
        name_keys = {
            name
            for name in (
                normalized_name(city["cityNameLocal"]),
                normalized_name(city["cityNameZh"]),
            )
            if name
        }
        matches = [
            entry
            for entry in candidates
            if entry["names"].intersection(name_keys)
        ]
        if not matches:
            continue
        match = max(matches, key=lambda entry: entry["population"])
        coordinates[city["cityId"]] = {
            "latitude": match["latitude"],
            "longitude": match["longitude"],
            "source": "geonames:cities500",
            "sourceRef": f"https://www.geonames.org/{match['geonameId']}",
        }
    return coordinates


def coordinate_for_city(city, delay_seconds, provider):
    errors = []
    resolvers = {
        "auto": (wikidata_coordinate, nominatim_coordinate),
        "nominatim": (nominatim_coordinate,),
        "wikidata": (wikidata_coordinate,),
    }[provider]
    for resolver in resolvers:
        try:
            coordinate = resolver(city)
            if coordinate:
                if delay_seconds:
                    time.sleep(delay_seconds)
                return coordinate
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as error:
            errors.append(f"{resolver.__name__}: {error}")
    raise RuntimeError(f"Missing coordinate for {city['cityId']} ({city['cityNameLocal']}): {'; '.join(errors)}")


def destination_for_city(city, coordinate):
    display_name = city["cityNameZh"]
    country = city["countryOrRegion"]
    return {
        "id": city["cityId"],
        "displayName": display_name,
        "landmarkAssetName": "postcard_destination_city_generic",
        "stampAssetName": "postcard_stamp_city_generic",
        "routeMapAssetName": "trip_route_map_generic",
        "primaryColor": DEFAULT_PRIMARY_COLOR,
        "postcardTitleTemplate": "{animal}寄来的" + display_name + "来信",
        "postcardSubtitle": country + "旅途中寄来",
        "postcardBodyTemplate": "{animal}到了{destination}。这里的街角、队伍和灯光都很日常，像一张慢慢展开的小地图。",
        "latitude": coordinate["latitude"],
        "longitude": coordinate["longitude"],
        "countryOrRegion": country,
        "continent": city["continent"],
        "travelDistanceTier": city["travelDistanceTier"],
        "coordinateSource": coordinate["source"],
        "coordinateSourceRef": coordinate["sourceRef"],
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--candidate-pool", default="Content/LocationDatabase/V2/city_candidate_pool_v2.json")
    parser.add_argument("--output", default="TripPet/Resources/LocationDestinationCatalog.json")
    parser.add_argument("--delay", type=float, default=0.15)
    parser.add_argument("--provider", choices=("auto", "geonames", "nominatim", "wikidata"), default="geonames")
    parser.add_argument("--geonames-url", default=GEONAMES_CITIES_URL)
    args = parser.parse_args()

    root = Path.cwd()
    candidate_pool = read_json(root / args.candidate_pool)
    cities = candidate_pool["cities"]
    destinations = []
    if args.provider == "geonames":
        batch_coordinates = geonames_coordinates(cities, args.geonames_url)
    elif args.provider == "nominatim":
        batch_coordinates = {}
    else:
        batch_coordinates = batch_wikidata_coordinates(cities)
    for index, city in enumerate(cities, start=1):
        fallback_provider = "auto" if args.provider == "geonames" else args.provider
        coordinate = batch_coordinates.get(city["cityId"]) or coordinate_for_city(city, args.delay, fallback_provider)
        destinations.append(destination_for_city(city, coordinate))
        print(f"{index:03d}/{len(cities)} {city['cityId']} {coordinate['latitude']},{coordinate['longitude']}")

    payload = {
        "version": 1,
        "sourceCandidatePool": args.candidate_pool,
        "coordinateSources": ["geonames:cities500", "wikidata:P625", "openstreetmap:nominatim"],
        "destinations": destinations,
    }
    write_json(root / args.output, payload)


if __name__ == "__main__":
    main()
