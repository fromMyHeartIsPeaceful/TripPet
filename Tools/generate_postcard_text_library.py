#!/usr/bin/env python3
"""Generate the runtime Swift postcard text library from author markdown files."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = REPO_ROOT / "Content" / "AnimalDatabase" / "PostcardTextLibrary_1.0.6"
OUTPUT_FILE = REPO_ROOT / "TripPet" / "Domain" / "Services" / "PostcardTextLibrary.swift"

SOURCE_FILES = [
    ("xiaoman_hamster", "仓鼠小满明信片人格与状态文本合集.md"),
    ("tangyuan_puppy", "小狗糖圆明信片人格与状态文本合集.md"),
    ("moji_cat", "小猫墨迹明信片人格与状态文本合集.md"),
    ("dengdeng_rabbit", "兔子灯灯明信片人格与状态文本合集.md"),
    ("feifei_parrot", "鹦鹉飞飞明信片人格与状态文本合集.md"),
    ("xiaolu_guinea_pig", "豚鼠小炉明信片人格与状态文本合集.md"),
    ("deer_visitor", "小鹿啾啾明信片人格与状态文本合集.md"),
    ("fox_visitor", "小狐狸埃尼明信片人格与状态文本合集.md"),
]

BEAR_FALLBACK_NARRATIVES = [
    "夜班药店的白灯还亮着，柜台旁放着一杯热水，杯口的白气很淡。值班的人把椅子往里推了推，又把说明书压在药盒下面，动作很慢，也很稳。我站在门口，把爪子放在杯壁旁边暖了一会儿。小熊有时候反应慢，要过一阵才知道自己为什么停下。后来我想明白了：不是因为药店特别好，也不是因为这杯水特别热，是因为这一小块地方没有催我马上走。旅行里有些地方就是这样，什么都不多说，只给你一把椅子、一盏灯、一点热气。后来门外的风小了一点，那把椅子还在原来的地方。",
    "傍晚的长椅被太阳晒了一天，坐上去还有一点暖。我坐得很慢，木头先响了一声，然后稳住。旁边有人把购物袋放在椅子另一头，袋子里有白菜和一瓶酱油。小熊不太会找话，只会听塑料袋被风吹得轻轻动。提前坐一会儿，后面的路会好走些。太阳落下去以后，椅背还剩一点温度。",
    "便利店的微波炉转着一盒便当，里面的灯一亮一暗。站在旁边的人搓着手，眼睛一直看着倒计时。我也跟着看，数字跳得很慢，但总算一格一格少下去。热东西有自己的速度，急也没有用。微波炉叮的一声，便当盒盖鼓起来一点。那个人小心地端出来，像端着一个刚刚回来的晚上。",
    "雨天的公交站有一块干的地方，在广告牌下面，不大，但够站。我把背包放在脚边，尽量不占太多。雨水顺着棚顶往下流，落到路边的水坑里。旁边老人把伞收起来，伞尖滴水很慢。公交还没到，那块干地被几双鞋分着站，谁也没有挤谁。小熊看着那一小块地，觉得够用就很好。",
    "老电影院门口有两级台阶，边缘磨得很圆。我上去时慢了一点，爪子先试了试。里面散场的人出来，笑声一阵一阵往外涌。小熊不太适合挤在人群里，就靠在墙边等他们过去。重一点的脚步，更要知道什么时候停。人群散开以后，台阶上留下几张票根，风吹过来，票根翻了个面，又停住了。",
    "深夜的自动售货机亮着，瓶子一排排站在玻璃后面。我投了硬币，机器响了一会儿，水才慢慢滚下来。声音很沉，像有什么东西终于落到该落的位置。我弯腰捡起来，瓶身很凉。手里有一点重量，心里会稳些。售货机继续亮着，照着地上一小块蓝白色的光。",
    "小饭馆快打烊，老板把最后一张桌子擦干净，又把椅子推进去。桌面上还有一点汤的味道，不浓，很家常。我坐在门口台阶上，听锅盖碰到锅沿，咚的一声。吃饱以后，很多声音都在结束一天。老板关门时，屋里的热气跟着出来一点，很快散在夜风里。小熊坐到风小了，才慢慢站起来。",
    "火车车厢里空座很多，我挑了靠窗的位置。座椅有点旧，坐下去会轻轻陷一下，但很稳。窗外的灯一盏一盏退后，像路自己在慢慢折起来。小熊看东西慢，常常要等它走远了，才知道刚才看见了什么。列车晃了一下，水杯里的水只晃到杯壁，没有洒出来。这个位置不错，可以坐很久。",
    "桥上的风大，我把围巾往下压了压。栏杆很凉，但很结实，手放上去能感觉到一点震动。河水在下面走得很快，灯影被拉长又揉碎。小熊不急着过桥，先找一处能靠的地方。风又吹来时，围巾角贴在胸口，没有再翻起来。栏杆一直在那里，稳稳地接住我的重量。",
    "清晨的门卫室亮着一盏小灯，窗台上放着搪瓷杯。杯子旁边有一副旧手套，手套口朝着暖气片。值班的人低头看报纸，偶尔抬头看看外面的路。我站在窗外，觉得这种灯不刺眼，只把周围照得够用。远处第一辆公交开过来，门卫室的窗玻璃轻轻震了一下。手套没有动，杯子也没有动，早晨就这样慢慢开始了。",
]


def parse_markdown_narratives(path: Path) -> list[str]:
    lines = path.read_text(encoding="utf-8").splitlines()
    narratives: list[str] = []
    in_text_section = False
    index = 0

    while index < len(lines):
        line = lines[index].strip()
        if line.startswith("## "):
            in_text_section = "｜10条" in line
            index += 1
            continue

        if in_text_section and re.fullmatch(r"\d+\.\s*", line):
            index += 1
            body_lines: list[str] = []
            while index < len(lines):
                candidate = lines[index].strip()
                if (
                    re.fullmatch(r"\d+\.\s*", candidate)
                    or candidate.startswith("## ")
                    or candidate == "---"
                ):
                    break
                if candidate:
                    body_lines.append(candidate)
                index += 1
            body = "\n".join(body_lines).strip()
            if body:
                narratives.append(body)
            continue

        index += 1

    return narratives


def swift_string(value: str) -> str:
    return (
        value.replace("\\", "\\\\")
        .replace("\"", "\\\"")
        .replace("\n", "\\n")
    )


def make_entry(identifier: str, animal_key: str, body: str) -> str:
    return (
        f'        PostcardNarrative(id: "{identifier}", '
        f'animalKey: "{animal_key}", '
        f'body: "{swift_string(body)}")'
    )


def build_swift(entries: list[tuple[str, str, str]]) -> str:
    entry_lines = [make_entry(identifier, animal_key, body) for identifier, animal_key, body in entries]
    joined_entries = ",\n".join(entry_lines)
    return f"""import Foundation

struct PostcardNarrative: Equatable {{
    let id: String
    let animalKey: String
    let body: String
}}

enum PostcardTextLibrary {{
    static func randomEntry(for animal: Animal, excluding consumedIds: Set<String>) -> PostcardNarrative? {{
        let key = animalKey(for: animal)
        let available = narratives.filter {{ $0.animalKey == key && consumedIds.contains($0.id) == false }}
        return available.randomElement()
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

    // Generated by Tools/generate_postcard_text_library.py from Content/AnimalDatabase/PostcardTextLibrary_1.0.6.
    static let narratives: [PostcardNarrative] = [
{joined_entries}
    ]
}}
"""


def collect_entries() -> list[tuple[str, str, str]]:
    entries: list[tuple[str, str, str]] = []
    for animal_key, filename in SOURCE_FILES:
        path = SOURCE_DIR / filename
        narratives = parse_markdown_narratives(path)
        if not narratives:
            raise ValueError(f"No narratives parsed from {path}")
        for offset, body in enumerate(narratives, start=1):
            identifier = f"{animal_key}_textlib106_{offset:03d}"
            entries.append((identifier, animal_key, body))

    for offset, body in enumerate(BEAR_FALLBACK_NARRATIVES, start=1):
        entries.append((f"bear_visitor_{offset:03d}", "bear_visitor", body))

    return entries


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="Validate generated output without writing.")
    args = parser.parse_args()

    entries = collect_entries()
    swift = build_swift(entries)

    if args.check:
        current = OUTPUT_FILE.read_text(encoding="utf-8")
        if current != swift:
            raise SystemExit("PostcardTextLibrary.swift is out of date. Run Tools/generate_postcard_text_library.py.")
    else:
        OUTPUT_FILE.write_text(swift, encoding="utf-8")

    counts: dict[str, int] = {}
    for _, animal_key, _ in entries:
        counts[animal_key] = counts.get(animal_key, 0) + 1
    for animal_key in sorted(counts):
        print(f"{animal_key}: {counts[animal_key]}")
    print(f"total: {len(entries)}")


if __name__ == "__main__":
    main()
