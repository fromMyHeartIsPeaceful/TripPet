#!/usr/bin/env python3
"""Generate the runtime Swift postcard care text library from author markdown."""

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SOURCE_FILE = REPO_ROOT / "Content" / "AnimalDatabase" / "PostcardGreetingCare_1.0_Draft.md"
OUTPUT_FILE = REPO_ROOT / "TripPet" / "Domain" / "Services" / "PostcardTextLibrary.swift"

ANIMAL_KEY_ALIASES = {
    "小满": "xiaoman_hamster",
    "糖圆": "tangyuan_puppy",
    "墨迹": "moji_cat",
    "灯灯": "dengdeng_rabbit",
    "飞飞": "feifei_parrot",
    "小炉": "xiaolu_guinea_pig",
    "啾啾": "deer_visitor",
    "埃尼": "fox_visitor",
    "墩墩": "bear_visitor",
}

CATEGORY_CASES = {
    1: "nightCare",
    2: "movementBreak",
    3: "hydrationFood",
    4: "sleepShutdown",
    5: "workRhythm",
    6: "hurtMisunderstood",
    7: "informationOverload",
    8: "lowBattery",
    9: "selfBlameFailure",
    10: "missingHome",
    11: "gentleEncouragement",
    12: "smallTips",
    13: "weatherSeason",
    14: "morningRestart",
}

CATEGORY_TITLES = {
    1: "疲惫恢复/夜间关照",
    2: "久坐与身体活动",
    3: "喝水与饮食",
    4: "睡眠与收工",
    5: "工作压力与节奏",
    6: "委屈与不被理解",
    7: "情绪乱/信息太多",
    8: "低电量与空掉",
    9: "自我责备与失败感",
    10: "直接想念与回家期待",
    11: "轻鼓励与继续出发",
    12: "小 tips/健康提醒",
    13: "天气、季节与身体感受",
    14: "早晨/重新开始",
}


@dataclass(frozen=True)
class Entry:
    identifier: str
    animal_key: str
    category_number: int
    body: str


def swift_string(value: str) -> str:
    return (
        value.replace("\\", "\\\\")
        .replace("\"", "\\\"")
        .replace("\n", "\\n")
    )


def parse_animal_key(line: str) -> str | None:
    title = line.removeprefix("## ").strip()
    parts = [part.strip() for part in title.split("｜")]
    if len(parts) >= 2 and parts[1]:
        return parts[1]
    return ANIMAL_KEY_ALIASES.get(parts[0])


def parse_source() -> list[Entry]:
    lines = SOURCE_FILE.read_text(encoding="utf-8").splitlines()
    entries: list[Entry] = []
    animal_key: str | None = None
    category_number: int | None = None
    category_offsets: dict[tuple[str, int], int] = {}
    index = 0

    while index < len(lines):
        line = lines[index].strip()
        if line.startswith("## "):
            animal_key = parse_animal_key(line)
            category_number = None
            index += 1
            continue

        category_match = re.fullmatch(r"###\s+(\d{2})\.\s+(.+)", line)
        if category_match:
            category_number = int(category_match.group(1))
            expected_title = CATEGORY_TITLES.get(category_number)
            actual_title = category_match.group(2).strip()
            if expected_title != actual_title:
                raise ValueError(f"Unexpected category title {actual_title!r} for {category_number:02d}")
            index += 1
            continue

        text_match = re.match(r"^(\d+)\.\s+(.+)$", line)
        if text_match and animal_key and category_number:
            body_lines = [text_match.group(2).strip()]
            index += 1
            while index < len(lines):
                candidate = lines[index].strip()
                if candidate.startswith("## ") or candidate.startswith("### ") or re.match(r"^\d+\.\s+", candidate):
                    break
                if candidate:
                    body_lines.append(candidate)
                index += 1
            key = (animal_key, category_number)
            category_offsets[key] = category_offsets.get(key, 0) + 1
            identifier = f"{animal_key}_care10_{category_number:02d}_{category_offsets[key]:03d}"
            entries.append(
                Entry(
                    identifier=identifier,
                    animal_key=animal_key,
                    category_number=category_number,
                    body="\n".join(body_lines).strip(),
                )
            )
            continue

        index += 1

    return entries


def validate_entries(entries: list[Entry]) -> None:
    if len(entries) != 1_260:
        raise ValueError(f"Expected 1260 entries, found {len(entries)}")

    animals = sorted({entry.animal_key for entry in entries})
    if len(animals) != 9:
        raise ValueError(f"Expected 9 animals, found {len(animals)}")

    for animal_key in animals:
        animal_entries = [entry for entry in entries if entry.animal_key == animal_key]
        if len(animal_entries) != 140:
            raise ValueError(f"Expected 140 entries for {animal_key}, found {len(animal_entries)}")
        for category_number in CATEGORY_CASES:
            count = sum(1 for entry in animal_entries if entry.category_number == category_number)
            if count != 10:
                raise ValueError(
                    f"Expected 10 entries for {animal_key} category {category_number:02d}, found {count}"
                )


def make_entry(entry: Entry) -> str:
    return (
        f'        PostcardNarrative(id: "{entry.identifier}", '
        f'animalKey: "{entry.animal_key}", '
        f"careCategory: .{CATEGORY_CASES[entry.category_number]}, "
        f'body: "{swift_string(entry.body)}")'
    )


def build_swift(entries: list[Entry]) -> str:
    entry_lines = [make_entry(entry) for entry in entries]
    joined_entries = ",\n".join(entry_lines)
    generated_cases = "\n".join(
        f"    case {case_name}" for _, case_name in sorted(CATEGORY_CASES.items())
    )
    return f"""import Foundation

enum PostcardCareCategory: String, CaseIterable, Equatable, Hashable {{
{generated_cases}
}}

struct PostcardCareCategorySelection: Equatable {{
    let preferred: [PostcardCareCategory]
    let fallback: [PostcardCareCategory]
}}

enum PostcardCareTimeRules {{
    static let minimumSpacing: TimeInterval = 60 * 90

    static func selection(for date: Date, calendar: Calendar = .current) -> PostcardCareCategorySelection {{
        let minute = minuteOfDay(for: date, calendar: calendar)
        switch minute {{
        case 360..<630:
            return PostcardCareCategorySelection(
                preferred: [.morningRestart, .gentleEncouragement, .weatherSeason],
                fallback: [.missingHome, .smallTips]
            )
        case 630..<810:
            return PostcardCareCategorySelection(
                preferred: [.hydrationFood, .workRhythm, .smallTips],
                fallback: [.missingHome, .weatherSeason]
            )
        case 810..<1050:
            return PostcardCareCategorySelection(
                preferred: [.movementBreak, .workRhythm, .informationOverload, .lowBattery],
                fallback: [.hydrationFood, .gentleEncouragement, .smallTips]
            )
        case 1050..<1170:
            return PostcardCareCategorySelection(
                preferred: [.sleepShutdown, .hydrationFood, .hurtMisunderstood],
                fallback: [.missingHome, .weatherSeason]
            )
        case 1170..<1290:
            return PostcardCareCategorySelection(
                preferred: [.nightCare, .hurtMisunderstood, .informationOverload, .selfBlameFailure],
                fallback: [.hydrationFood, .missingHome]
            )
        case 1290..<1410:
            return PostcardCareCategorySelection(
                preferred: [.nightCare, .sleepShutdown, .lowBattery, .selfBlameFailure],
                fallback: [.missingHome]
            )
        case 1410..<1440, 0..<360:
            return PostcardCareCategorySelection(
                preferred: [.nightCare, .sleepShutdown],
                fallback: [.lowBattery]
            )
        default:
            return PostcardCareCategorySelection(
                preferred: [.missingHome, .weatherSeason],
                fallback: [.hurtMisunderstood, .selfBlameFailure]
            )
        }}
    }}

    static func normalizedDeliveryDate(for date: Date, calendar: Calendar = .current) -> Date {{
        let minute = minuteOfDay(for: date, calendar: calendar)
        guard minute >= 1410 || minute < 360 else {{
            return date
        }}

        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 6
        components.minute = 30
        components.second = 0
        components.nanosecond = 0
        let baseDay = calendar.date(from: components) ?? date
        if minute >= 1410 {{
            return calendar.date(byAdding: .day, value: 1, to: baseDay) ?? date.addingTimeInterval(60 * 60 * 7)
        }}
        return baseDay
    }}

    static func minuteOfDay(for date: Date, calendar: Calendar = .current) -> Int {{
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }}
}}

struct PostcardNarrative: Equatable {{
    let id: String
    let animalKey: String
    let careCategory: PostcardCareCategory
    let body: String
}}

enum PostcardTextLibrary {{
    static func randomEntry(
        for animal: Animal,
        on date: Date,
        calendar: Calendar = .current,
        excluding consumedIds: Set<String>
    ) -> PostcardNarrative? {{
        let key = animalKey(for: animal)
        let selection = PostcardCareTimeRules.selection(for: date, calendar: calendar)
        let available = narratives.filter {{ $0.animalKey == key && consumedIds.contains($0.id) == false }}
        return randomEntry(in: available, categories: selection.preferred) ??
            randomEntry(in: available, categories: selection.fallback)
    }}

    static func randomEntry(for animal: Animal, excluding consumedIds: Set<String>) -> PostcardNarrative? {{
        randomEntry(for: animal, on: Date(), excluding: consumedIds)
    }}

    private static func randomEntry(
        in entries: [PostcardNarrative],
        categories: [PostcardCareCategory]
    ) -> PostcardNarrative? {{
        guard categories.isEmpty == false else {{ return nil }}
        let categorySet = Set(categories)
        return entries.filter {{ categorySet.contains($0.careCategory) }}.randomElement()
    }}

    static func animalKey(for animal: Animal) -> String {{
        if animal.id == "xiaoman_hamster" || animal.homeAssetName.contains("xiaoman_hamster") {{
            return "xiaoman_hamster"
        }}
        if animal.id == "tangyuan_puppy" || animal.homeAssetName.contains("tangyuan_puppy") {{
            return "tangyuan_puppy"
        }}
        if animal.id == "moji_cat" || animal.homeAssetName.contains("moji_cat") {{
            return "moji_cat"
        }}
        if animal.id == "dengdeng_rabbit" || animal.homeAssetName.contains("dengdeng_rabbit") {{
            return "dengdeng_rabbit"
        }}
        if animal.id == "feifei_parrot" || animal.homeAssetName.contains("feifei_parrot") {{
            return "feifei_parrot"
        }}
        if animal.id == "xiaolu_guinea_pig" || animal.homeAssetName.contains("xiaolu_guinea_pig") {{
            return "xiaolu_guinea_pig"
        }}
        if animal.id == "deer_visitor" ||
            animal.homeAssetName.contains("deer_visitor") ||
            animal.homeAssetName.contains("jiujiu_deer") {{
            return "deer_visitor"
        }}
        if animal.id == "fox_visitor" ||
            animal.homeAssetName.contains("fox_visitor") ||
            animal.homeAssetName.contains("aini_fox") {{
            return "fox_visitor"
        }}
        if animal.id == "bear_visitor" ||
            animal.homeAssetName.contains("bear_visitor") ||
            animal.homeAssetName.contains("dundun_bear") {{
            return "bear_visitor"
        }}
        return animal.id
    }}

    // Generated by Tools/generate_postcard_text_library.py from Content/AnimalDatabase/PostcardGreetingCare_1.0_Draft.md.
    static let narratives: [PostcardNarrative] = [
{joined_entries}
    ]
}}
"""


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="Validate generated output without writing.")
    args = parser.parse_args()

    entries = parse_source()
    validate_entries(entries)
    swift = build_swift(entries)

    if args.check:
        current = OUTPUT_FILE.read_text(encoding="utf-8")
        if current != swift:
            raise SystemExit("PostcardTextLibrary.swift is out of date. Run Tools/generate_postcard_text_library.py.")
    else:
        OUTPUT_FILE.write_text(swift, encoding="utf-8")

    counts: dict[str, int] = {}
    for entry in entries:
        counts[entry.animal_key] = counts.get(entry.animal_key, 0) + 1
    for animal_key in sorted(counts):
        print(f"{animal_key}: {counts[animal_key]}")
    print(f"total: {len(entries)}")


if __name__ == "__main__":
    main()
