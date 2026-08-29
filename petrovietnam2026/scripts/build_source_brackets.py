#!/usr/bin/env python3
"""Build reviewed source topology and its idempotent Supabase seed."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from uuid import UUID, uuid5

ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parent
ASSET_DIR = ROOT / "assets" / "sports"
MANIFEST_PATH = ROOT / "data" / "source-brackets.json"
SEED_PATH = REPO_ROOT / "supabase" / "seeds" / "051_source_brackets.sql"
FIXTURE_NAMESPACE = UUID("7a3e2a95-78f2-4c70-90e7-0c4706bc2026")
MODES = {"knockout", "group_knockout", "round_robin", "swiss", "race"}


PICKLEBALL = [
    ("doi-nam-duoi-30", "PICKLEBALL/PDF/DÔI NAM d30t-32.pdf", 7, "1A 2K 2F 1B 2G 1C 1D 2H 2I 1E 2J 1F 1G 2E 2D 2C 1H 1I 2B 1J 2A 1K"),
    ("doi-nam-31-40", "PICKLEBALL/PDF/DÔI NAM 31-40T 37 (1).pdf", 7, "1A 2L 2K 1B 2J 1C 1D 2I 1E 2H 2G 1F 1G 2F 2E 1H 2D 1I 1J 2C 1K 2B 2A 1L"),
    ("doi-nam-41-50", "PICKLEBALL/PDF/DÔI NAM 41-50T-40.pdf", 12, "1J 2I 1A 1B 2H 1C 2G 1D 2F 1E 1F 2E 1G 1H 2D 1I 2C 1J 2B 2A"),
    ("doi-nam-tren-51", "PICKLEBALL/PDF/DÔI NAM 51T-26.pdf", 6, "1A 2H 1B 2G 1C 2F 1D 2E 1E 2C 1F 2D 1G 2B 1H 2A"),
    ("doi-nu-31-40", "PICKLEBALL/PDF/DÔI NỮ 31-40T-18.pdf", 4, "1A 2F 2E 1B 2D 1C 1D 2C 1E 2B 2A 1F"),
    ("doi-nu-41-50", "PICKLEBALL/PDF/DÔI NỮ 41-50.pdf", 3, "1A 2D 1B 2C 1C 2B 1D 2A"),
    ("doi-nam-nu-duoi-30", "PICKLEBALL/PDF/DÔI NAM NƯ D30T-22.pdf", 6, "1A 2G 1B 2F 1C 2E 1D 1E 2D 1F 2C 2B 2A 1G"),
    ("doi-nam-nu-31-40", "PICKLEBALL/PDF/DÔI NAM NỮ 31-40T-31.pdf", 5, "1A 2H 1B 2G 1C 2F 1D 2E 1E 2C 1F 2D 1G 2B 1H 2A"),
    ("doi-nam-nu-41-50", "PICKLEBALL/PDF/DÔI NAM NỮ 41-50T-21.pdf", 5, "1A 2G 2F 1B 2E 2D 1C 1D 2C 1E 2B 1F 2A 1G"),
    ("doi-nam-nu-tren-51", "PICKLEBALL/PDF/ĐÔI NAM NỮ 51-10.pdf", 3, "1A 2C 1B 2A 2B 1C"),
]

GROUP_BRACKETS = [
    *(dict(sport="pickleball", slug=slug, file=file, page=page, leaves=labels.split(), bronze=slug == "doi-nam-nu-tren-51") for slug, file, page, labels in PICKLEBALL),
    dict(sport="bong-ban", slug="doi-nam-duoi-30", file="BÓNG BÀN/B Bàn pn 26 (1).pdf", page=4, leaves="1A 2B 1B 2A".split(), bronze=True),
    dict(sport="bong-ban", slug="doi-nam-31-40", file="BÓNG BÀN/B Bàn pn 26 (1).pdf", page=7, leaves="1A 2B 1B 2A".split(), bronze=True),
    dict(sport="bong-ban", slug="doi-nam-41-50", file="BÓNG BÀN/B Bàn pn 26 (1).pdf", page=13, leaves="1A 2D 1B 2F 2E 1C 1D 2B 1E 2C 2A 1F".split(), bronze=False),
    dict(sport="bong-ban", slug="doi-nu", file="BÓNG BÀN/B Bàn pn 26 (1).pdf", page=16, leaves="1A 2B 1B 2A".split(), bronze=True),
    dict(sport="bong-ban", slug="doi-nam-nu-31-40", file="BÓNG BÀN/B Bàn pn 26 (1).pdf", page=18, leaves="1A 2B 1B 2A".split(), bronze=True),
    dict(sport="bong-ban", slug="doi-nam-nu-41-50", file="BÓNG BÀN/B Bàn pn 26 (1).pdf", page=20, leaves="1A 2B 1B 2A".split(), bronze=True),
    dict(sport="cau-long", slug="doi-nam-nu-31-40", file="CẦU LÔNG/CẦU LÔNG PN 2026.pdf", page=8, leaves="1A 2B 1B 2A".split(), bronze=True),
    dict(sport="cau-long", slug="doi-nam-nu-41-50", file="CẦU LÔNG/CẦU LÔNG PN 2026.pdf", page=10, leaves="1A 2B 1B 2A".split(), bronze=True),
    dict(sport="cau-long", slug="doi-nu-31-40", file="CẦU LÔNG/CẦU LÔNG PN 2026.pdf", page=13, leaves="1A 2B 1B 2A".split(), bronze=True),
]

DIRECT_BRACKETS = [
    dict(sport="cau-long", slug="doi-nam-31-40", file="CẦU LÔNG/CẦU LÔNG PN 2026.pdf", page=2),
    dict(sport="cau-long", slug="doi-nam-duoi-30", file="CẦU LÔNG/CẦU LÔNG PN 2026.pdf", page=3),
    dict(sport="cau-long", slug="doi-nam-41-50", file="CẦU LÔNG/CẦU LÔNG PN 2026.pdf", page=4),
    dict(sport="cau-long", slug="doi-nam-nu-duoi-30", file="CẦU LÔNG/CẦU LÔNG PN 2026.pdf", page=6),
]

TUG = {
    "nu": "PVCHEM|VSP|PVI|NCKH|PVOIL|PVMR|PVTRANS|PTSC|PVCOMBANK|PETROCONs|PVPMB|PETROSETCO".split("|"),
    "nam": "PVFCCo|PTSC|PVGAS|PVOIL|PVPMB|PVMR|PVCHEM|PVI|PETROSETCO|PCTRANS|PVD|SWPOC|NCKH|PVCOMBANK|PQPOC|BỘ MÁY QL&ĐH PETROVN|VSP".split("|"),
}

PASSIVE = [
    ("pickleball", "doi-nu-tren-50", "round_robin", "PICKLEBALL/PDF/ĐÔI NỮ 50T.pdf", 1),
    ("cau-long", "doi-nam-tren-51", "round_robin", "CẦU LÔNG/CẦU LÔNG PN 2026.pdf", 5),
    ("cau-long", "doi-nu-duoi-30", "round_robin", "CẦU LÔNG/CẦU LÔNG PN 2026.pdf", 11),
    ("boi-loi", "50m-nam", "race", "BƠI LỘI/Boi pn 2026.pdf", 3),
    ("boi-loi", "50m-nu", "race", "BƠI LỘI/Boi pn 2026.pdf", 6),
    ("boi-loi", "100m-nam", "race", "BƠI LỘI/Boi pn 2026.pdf", 5),
    ("boi-loi", "100m-nu", "race", "BƠI LỘI/Boi pn 2026.pdf", 2),
    ("boi-loi", "4x50m-nam", "race", "BƠI LỘI/Boi pn 2026.pdf", 7),
    ("boi-loi", "4x50m-nu", "race", "BƠI LỘI/Boi pn 2026.pdf", 7),
    ("dien-kinh", "400m-nu", "race", "ĐIỀN KINH/ĐKinh cap nhat 27.8 pvn 2026.pdf", 5),
    ("dien-kinh", "800m-nam", "race", "ĐIỀN KINH/ĐKinh cap nhat 27.8 pvn 2026.pdf", 6),
    ("dien-kinh", "4x100m-nu", "race", "ĐIỀN KINH/ĐKinh cap nhat 27.8 pvn 2026.pdf", 4),
    ("dien-kinh", "4x100m-nam", "race", "ĐIỀN KINH/ĐKinh cap nhat 27.8 pvn 2026.pdf", 2),
    ("dien-kinh", "3000m-nu", "race", "ĐIỀN KINH/ĐKinh cap nhat 27.8 pvn 2026.pdf", 8),
    ("dien-kinh", "5000m-nam", "race", "ĐIỀN KINH/ĐKinh cap nhat 27.8 pvn 2026.pdf", 10),
    ("co-vua", "nu", "swiss", "CỜ VUA/cờ vua bảng nữ.pdf", 1),
    ("co-vua", "nam-duoi-45", "swiss", "CỜ VUA/cờ vua bảng nam dưới 45t.pdf", 1),
    ("co-vua", "nam-tren-45", "swiss", "CỜ VUA/cờ vua bảng nam trên 45t.pdf", 1),
    ("co-tuong", "nam-duoi-45", "swiss", "CỜ TƯỚNG/cờ tướng bảng nam dưới 45t.pdf", 1),
    ("co-tuong", "nam-tren-45", "swiss", "CỜ TƯỚNG/cờ tướng bảng nam trên 45t.pdf", 1),
]


def source(file: str, page: int, warnings: list[str] | None = None) -> dict:
    pdf = Path(file)
    sibling = next((path for path in (ASSET_DIR / pdf.parent).glob("*.xlsx")), None)
    value = {"file": file, "page_or_sheet": page, "warnings": warnings or []}
    if sibling:
        value.update({"supporting_file": str(sibling.relative_to(ASSET_DIR)), "supporting_sheet": f"Trang {page}"})
    return value


def leaf(label: str, kind: str) -> dict:
    if kind == "group_rank":
        match = re.fullmatch(r"([12])([A-Z])", label.upper())
        if not match:
            raise ValueError(f"invalid group label: {label}")
        return {"kind": kind, "group": f"Bảng {match[2]}", "rank": int(match[1]), "label_vi": label, "label_en": label}
    return {"kind": "entry", "entry_name": label, "label_vi": label, "label_en": label}


def round_names(round_order: int, total_rounds: int) -> tuple[str, str]:
    remaining = total_rounds - round_order
    if remaining == 0:
        return "Chung kết", "Final"
    if remaining == 1:
        return "Bán kết", "Semifinal"
    if remaining == 2:
        return "Tứ kết", "Quarterfinal"
    return f"Vòng loại {round_order}", f"Knockout round {round_order}"


def extract_bracket(file: str, page_number: int, labels: list[str], kind: str, bronze: bool) -> list[dict]:
    """Read actual PDF connector graph. Leaf order alone cannot place source-defined byes."""
    import fitz

    page = fitz.open(ASSET_DIR / file)[page_number - 1]
    horizontal: list[tuple[float, float, float]] = []
    vertical: list[tuple[float, float, float]] = []
    for drawing in page.get_drawings():
        for item in drawing["items"]:
            if item[0] != "l":
                continue
            first, second = item[1], item[2]
            if abs(first.y - second.y) < 1:
                horizontal.append((min(first.x, second.x), max(first.x, second.x), (first.y + second.y) / 2))
            elif abs(first.x - second.x) < 1:
                vertical.append(((first.x + second.x) / 2, min(first.y, second.y), max(first.y, second.y)))

    nodes: list[dict] = []
    for x, top, bottom in vertical:
        inputs = []
        for endpoint in (top, bottom):
            matches = [index for index, (_, right, y) in enumerate(horizontal) if abs(right - x) < 1.5 and abs(y - endpoint) < 1.5]
            if not matches:
                break
            inputs.append(matches[0])
        if len(inputs) != 2:
            continue
        outputs = [index for index, (left, right, y) in enumerate(horizontal) if left < x + 1.5 and right > x + 3 and top + 1 < y < bottom - 1]
        if outputs:
            nodes.append({"x": x, "y": horizontal[outputs[0]][2], "inputs": inputs, "output": outputs[0]})

    output_to_node = {node["output"]: index for index, node in enumerate(nodes)}
    used_lines = {line for node in nodes for line in node["inputs"]}

    def component(root: int) -> tuple[set[int], set[int]]:
        node_ids, leaf_lines = set(), set()

        def visit(index: int) -> None:
            if index in node_ids:
                return
            node_ids.add(index)
            for line in nodes[index]["inputs"]:
                if line in output_to_node:
                    visit(output_to_node[line])
                else:
                    leaf_lines.add(line)

        visit(root)
        return node_ids, leaf_lines

    roots = [index for index, node in enumerate(nodes) if node["output"] not in used_lines]
    components = [(node_ids, leaf_lines, root) for root in roots for node_ids, leaf_lines in [component(root)]]
    candidates = [(node_ids, leaf_lines, root) for node_ids, leaf_lines, root in components if len(leaf_lines) == len(labels)]
    if len(candidates) != 1:
        raise ValueError(f"could not isolate bracket graph from {file} page {page_number}; expected {len(labels)} leaves, found {[(len(a), len(b)) for a, b, _ in components]}")
    node_ids, leaf_lines, root = candidates[0]

    ordered_leaves = sorted(leaf_lines, key=lambda line: horizontal[line][2])
    leaf_sources = {line: leaf(label, kind) for line, label in zip(ordered_leaves, labels)}
    x_columns: list[float] = []
    for x in sorted(nodes[index]["x"] for index in node_ids):
        if not x_columns or abs(x - x_columns[-1]) > 3:
            x_columns.append(x)

    texts = []
    for block in page.get_text("dict")["blocks"]:
        for line in block.get("lines", []):
            text = "".join(span["text"] for span in line["spans"]).strip()
            if text:
                texts.append((*line["bbox"], text))

    ordered_nodes = sorted(node_ids, key=lambda index: (min(range(len(x_columns)), key=lambda column: abs(x_columns[column] - nodes[index]["x"])), nodes[index]["y"]))
    codes: dict[int, str] = {}
    occurrences: dict[str, int] = {}
    keys: dict[int, str] = {}
    for fallback, index in enumerate(ordered_nodes, 1):
        node = nodes[index]
        printed = [text for _, top, right, bottom, text in texts if text.isdigit() and node["x"] - 16 < right < node["x"] + 2 and abs((top + bottom) / 2 - node["y"]) < 12]
        code = printed[0] if printed else str(fallback)
        occurrences[code] = occurrences.get(code, 0) + 1
        codes[index] = code
        keys[index] = f"match-{code}" + (f"-{occurrences[code]}" if occurrences[code] > 1 else "")

    fixtures = []
    positions: dict[int, int] = {}
    for index in ordered_nodes:
        node = nodes[index]
        round_order = min(range(len(x_columns)), key=lambda column: abs(x_columns[column] - node["x"])) + 1
        positions[round_order] = positions.get(round_order, 0) + 1
        vi, en = round_names(round_order, len(x_columns))
        slots = []
        for side, line in zip(("home", "away"), node["inputs"]):
            if line in output_to_node:
                source_node = output_to_node[line]
                code = codes[source_node]
                slot = {"kind": "fixture_winner", "fixture": keys[source_node], "label_vi": f"Thắng {code}", "label_en": f"Winner {code}"}
            else:
                slot = leaf_sources[line]
            slots.append({"side": side, **slot})
        fixtures.append({"key": keys[index], "source_code": codes[index], "round_order": round_order, "bracket_position": positions[round_order], "round_vi": vi, "round_en": en, "slots": slots})

    if bronze:
        semifinal_nodes = [output_to_node[line] for line in nodes[root]["inputs"] if line in output_to_node]
        if len(semifinal_nodes) != 2:
            raise ValueError(f"bronze source lacks two semifinals: {file} page {page_number}")
        fixtures.append({
            "key": "match-h3", "source_code": "H3", "round_order": len(x_columns), "bracket_position": positions[len(x_columns)] + 1,
            "round_vi": "Tranh hạng ba", "round_en": "Bronze medal match",
            "slots": [
                {"side": "home", "kind": "fixture_loser", "fixture": keys[semifinal_nodes[0]], "label_vi": "Thua bán kết 1", "label_en": "Loser semifinal 1"},
                {"side": "away", "kind": "fixture_loser", "fixture": keys[semifinal_nodes[1]], "label_vi": "Thua bán kết 2", "label_en": "Loser semifinal 2"},
            ],
        })
    return fixtures


def extract_direct_names(file: str, page_number: int) -> list[str]:
    import fitz

    page = fitz.open(ASSET_DIR / file)[page_number - 1]
    lines = [
        (line["bbox"][0], line["bbox"][1], " ".join(span["text"] for span in line["spans"]).strip())
        for block in page.get_text("dict")["blocks"] if "lines" in block for line in block["lines"]
    ]
    match_x = min(x for x, y, text in lines if x > 100 and y > 60 and text.isdigit() and int(text) < 100)
    seeds = sorted((int(text), x, y) for x, y, text in lines if x < 100 and y > 60 and text.isdigit() and 0 < int(text) < 100)
    names = []
    for _, x, y in seeds:
        parts = [text.rstrip("/").strip() for line_x, line_y, text in sorted(lines, key=lambda row: row[1]) if x + 3 < line_x < min(match_x - 20, 240) and y - 20 < line_y < y + 4 and not text.isdigit()]
        if parts:
            names.append(" / ".join(parts))
    if len(names) != len(seeds) or len(names) < 2:
        raise ValueError(f"could not read every direct entrant from {file} page {page_number}: {len(names)}/{len(seeds)}")
    return names


def extract_manifest() -> dict:
    tournaments = []
    for row in GROUP_BRACKETS:
        warnings = []
        if row["sport"] == "pickleball" and row["slug"] == "doi-nam-41-50":
            warnings.append("PDF in mã trận 5 hai lần; giữ nguyên PDF để admin đối soát.")
        if row["sport"] == "pickleball" and row["slug"] == "doi-nam-31-40":
            warnings.append("Tiêu đề PDF ghi năm 2024; hiển thị thống nhất năm sự kiện 2026.")
        if row["sport"] == "cau-long" and row["slug"] == "doi-nam-nu-duoi-30":
            warnings.append("Tiêu đề PDF ghi năm 2025; hiển thị thống nhất năm sự kiện 2026.")
        tournaments.append({"sport_slug": row["sport"], "tournament_slug": row["slug"], "competition_mode": "group_knockout", "source": source(row["file"], row["page"], warnings), "fixtures": extract_bracket(row["file"], row["page"], row["leaves"], "group_rank", row["bronze"])})

    for row in DIRECT_BRACKETS:
        names = extract_direct_names(row["file"], row["page"])
        tournaments.append({"sport_slug": row["sport"], "tournament_slug": row["slug"], "competition_mode": "knockout", "source": source(row["file"], row["page"]), "fixtures": extract_bracket(row["file"], row["page"], names, "entry", False)})

    for slug, names in TUG.items():
        page = 2 if slug == "nu" else 3
        file = "KÉO CO/ĐK KEO CO pvn 2026.pdf"
        tournaments.append({"sport_slug": "keo-co", "tournament_slug": slug, "competition_mode": "knockout", "source": source(file, page), "fixtures": extract_bracket(file, page, names, "entry", False)})

    for sport, slug, mode, file, page in PASSIVE:
        warnings = ["Tiêu đề PDF ghi năm 2027; giữ nội dung theo bộ hồ sơ Hội thao 2026."] if sport == "dien-kinh" and slug == "400m-nu" else []
        tournaments.append({"sport_slug": sport, "tournament_slug": slug, "competition_mode": mode, "source": source(file, page, warnings), "fixtures": []})

    tournaments.sort(key=lambda row: (row["sport_slug"], row["tournament_slug"]))
    return {"version": 1, "tournaments": tournaments}


def validate_manifest(data: dict) -> None:
    if data.get("version") != 1 or not isinstance(data.get("tournaments"), list):
        raise ValueError("manifest version/tournaments invalid")
    seen_tournaments = set()
    for tournament in data["tournaments"]:
        key = (tournament.get("sport_slug"), tournament.get("tournament_slug"))
        if key in seen_tournaments:
            raise ValueError(f"duplicate tournament: {key}")
        seen_tournaments.add(key)
        if tournament.get("competition_mode") not in MODES:
            raise ValueError(f"invalid competition mode: {key}")
        source_data = tournament.get("source", {})
        if not source_data.get("file") or not isinstance(source_data.get("page_or_sheet"), int) or source_data["page_or_sheet"] < 1:
            raise ValueError(f"invalid source: {key}")
        if not (ASSET_DIR / source_data["file"]).is_file():
            raise ValueError(f"missing source asset: {source_data['file']}")
        if source_data.get("supporting_file") and not (ASSET_DIR / source_data["supporting_file"]).is_file():
            raise ValueError(f"missing supporting asset: {source_data['supporting_file']}")

        fixtures = tournament.get("fixtures", [])
        fixture_keys = [fixture.get("key") for fixture in fixtures]
        if len(fixture_keys) != len(set(fixture_keys)):
            raise ValueError(f"duplicate fixture key: {key}")
        known = set(fixture_keys)
        graph = {fixture_key: [] for fixture_key in fixture_keys}
        positions: dict[int, list[int]] = {}
        for fixture in fixtures:
            slots = fixture.get("slots", [])
            if {slot.get("side") for slot in slots} != {"home", "away"} or len(slots) != 2:
                raise ValueError(f"fixture must have home/away slots: {key}/{fixture.get('key')}")
            positions.setdefault(fixture["round_order"], []).append(fixture["bracket_position"])
            for slot in slots:
                if slot.get("kind") in {"fixture_winner", "fixture_loser"}:
                    dependency = slot.get("fixture")
                    if dependency not in known:
                        raise ValueError(f"missing fixture reference: {key}/{dependency}")
                    graph[dependency].append(fixture["key"])
        for round_order, values in positions.items():
            if sorted(values) != list(range(1, len(values) + 1)):
                raise ValueError(f"non-contiguous positions: {key}/round {round_order}")
        visiting, visited = set(), set()

        def visit(node: str) -> None:
            if node in visiting:
                raise ValueError(f"fixture cycle: {key}/{node}")
            if node in visited:
                return
            visiting.add(node)
            for child in graph[node]:
                visit(child)
            visiting.remove(node)
            visited.add(node)

        for node in graph:
            visit(node)


def sql(value: str | None) -> str:
    return "null" if value is None else "'" + value.replace("'", "''") + "'"


def build_sql(data: dict) -> str:
    validate_manifest(data)
    modes, entries, groups, fixtures, slots, warnings = [], set(), set(), [], [], []
    for tournament in data["tournaments"]:
        sport, slug, mode = tournament["sport_slug"], tournament["tournament_slug"], tournament["competition_mode"]
        modes.append((sport, slug, mode, json.dumps(tournament["source"], ensure_ascii=False, separators=(",", ":"))))
        for warning in tournament["source"].get("warnings", []):
            warnings.append((Path(tournament["source"]["file"]).name, warning))
        for fixture in tournament.get("fixtures", []):
            fixture_id = uuid5(FIXTURE_NAMESPACE, f"{sport}/{slug}/{fixture['key']}")
            fixtures.append((str(fixture_id), sport, slug, fixture["key"], fixture.get("source_code"), fixture["round_vi"], fixture["round_en"], fixture["round_order"], fixture["bracket_position"]))
            for slot_data in fixture["slots"]:
                kind = slot_data["kind"]
                entry_name = slot_data.get("entry_name")
                if entry_name:
                    entries.add((sport, slug, "team" if sport == "keo-co" else "pair", entry_name))
                if slot_data.get("group"):
                    groups.add((sport, slug, slot_data["group"], ord(slot_data["group"][-1]) - 64))
                source_fixture_id = uuid5(FIXTURE_NAMESPACE, f"{sport}/{slug}/{slot_data['fixture']}") if slot_data.get("fixture") else None
                slot_id = uuid5(FIXTURE_NAMESPACE, f"{sport}/{slug}/{fixture['key']}/{slot_data['side']}")
                slots.append((str(slot_id), str(fixture_id), sport, slug, slot_data["side"], kind, entry_name, slot_data.get("group"), str(source_fixture_id) if source_fixture_id else None, slot_data.get("rank"), slot_data.get("label_vi", ""), slot_data.get("label_en", "")))

    values = lambda rows: ",\n".join("  (" + ",".join(str(value) if isinstance(value, int) else sql(value) for value in row) + ")" for row in rows)
    lines = [
        "set app.tenant_slug = 'petrovietnam2026';",
        "",
        "-- Generated by petrovietnam2026/scripts/build_source_brackets.py. PDF topology wins; existing admin rows are never overwritten.",
        "create temporary table seed_source_modes (sport_slug text, tournament_slug text, competition_mode text, source_metadata jsonb) on commit drop;",
        "insert into seed_source_modes values\n" + values(modes) + ";",
        "update public.tournaments t set competition_mode = source.competition_mode, source_metadata = source.source_metadata",
        "from seed_source_modes source join public.sports s on s.slug = source.sport_slug and s.tenant_id = private.seed_tenant_id()",
        "where t.sport_id = s.id and t.slug = source.tournament_slug and t.tenant_id = s.tenant_id;",
    ]
    if entries:
        lines += [
            "",
            "create temporary table seed_source_entries (sport_slug text, tournament_slug text, kind text, entry_name text) on commit drop;",
            "insert into seed_source_entries values\n" + values(sorted(entries)) + ";",
            "insert into public.entries (tenant_id, tournament_id, kind, name_vi, name_en)",
            "select t.tenant_id, t.id, source.kind, source.entry_name, source.entry_name from seed_source_entries source",
            "join public.sports s on s.slug = source.sport_slug and s.tenant_id = private.seed_tenant_id()",
            "join public.tournaments t on t.sport_id = s.id and t.slug = source.tournament_slug and t.tenant_id = s.tenant_id",
            "where not exists (select 1 from public.entries e where e.tournament_id = t.id and e.name_vi = source.entry_name);",
        ]
    if groups:
        lines += [
            "",
            "create temporary table seed_source_groups (sport_slug text, tournament_slug text, group_name text, sort_order integer) on commit drop;",
            "insert into seed_source_groups values\n" + values(sorted(groups)) + ";",
            "insert into public.groups (tenant_id, tournament_id, name_vi, name_en, sort_order)",
            "select t.tenant_id, t.id, source.group_name, replace(source.group_name, 'Bảng ', 'Group '), source.sort_order from seed_source_groups source",
            "join public.sports s on s.slug = source.sport_slug and s.tenant_id = private.seed_tenant_id()",
            "join public.tournaments t on t.sport_id = s.id and t.slug = source.tournament_slug and t.tenant_id = s.tenant_id",
            "where not exists (select 1 from public.groups g where g.tournament_id = t.id and g.name_vi = source.group_name);",
        ]
    lines += [
        "",
        "create temporary table seed_source_fixtures (id uuid, sport_slug text, tournament_slug text, fixture_key text, source_code text, round_vi text, round_en text, round_order integer, bracket_position integer) on commit drop;",
        "insert into seed_source_fixtures values\n" + values(fixtures) + ";",
        "insert into public.fixtures (id, tenant_id, tournament_id, status, source_code, round_vi, round_en, round_order, bracket_position)",
        "select source.id, t.tenant_id, t.id, 'scheduled', source.source_code, source.round_vi, source.round_en, source.round_order, source.bracket_position",
        "from seed_source_fixtures source join public.sports s on s.slug = source.sport_slug and s.tenant_id = private.seed_tenant_id()",
        "join public.tournaments t on t.sport_id = s.id and t.slug = source.tournament_slug and t.tenant_id = s.tenant_id",
        "on conflict (id) do nothing;",
        "",
        "create temporary table seed_source_slots (id uuid, fixture_id uuid, sport_slug text, tournament_slug text, side text, source_kind text, entry_name text, group_name text, source_fixture_id uuid, source_rank integer, label_vi text, label_en text) on commit drop;",
        "insert into seed_source_slots values\n" + values(slots) + ";",
        "insert into public.fixture_slots (id, tenant_id, fixture_id, side, source_kind, source_entry_id, source_group_id, source_fixture_id, source_rank, label_vi, label_en)",
        "select source.id, t.tenant_id, source.fixture_id, source.side, source.source_kind, e.id, g.id, source.source_fixture_id, source.source_rank, source.label_vi, source.label_en",
        "from seed_source_slots source join public.sports s on s.slug = source.sport_slug and s.tenant_id = private.seed_tenant_id()",
        "join public.tournaments t on t.sport_id = s.id and t.slug = source.tournament_slug and t.tenant_id = s.tenant_id",
        "left join public.entries e on e.tournament_id = t.id and e.name_vi = source.entry_name and e.archived_at is null",
        "left join public.groups g on g.tournament_id = t.id and g.name_vi = source.group_name and g.archived_at is null",
        "where (source.source_kind <> 'entry' or e.id is not null) and (source.source_kind <> 'group_rank' or g.id is not null)",
        "on conflict (fixture_id, side) do nothing;",
        "",
        "insert into public.fixture_entries (tenant_id, fixture_id, entry_id, side)",
        "select t.tenant_id, source.fixture_id, e.id, source.side from seed_source_slots source",
        "join public.sports s on s.slug = source.sport_slug and s.tenant_id = private.seed_tenant_id()",
        "join public.tournaments t on t.sport_id = s.id and t.slug = source.tournament_slug and t.tenant_id = s.tenant_id",
        "join public.entries e on e.tournament_id = t.id and e.name_vi = source.entry_name and e.archived_at is null",
        "where source.source_kind = 'entry' on conflict (fixture_id, entry_id) do update set side = excluded.side, archived_at = null;",
    ]
    for filename, warning in sorted(set(warnings)):
        lines += [
            "",
            f"update public.source_documents set notes = concat_ws(E'\\n', nullif(notes, ''), {sql('Bracket audit: ' + warning)})",
            f"where raw_filename = {sql(filename)} and tenant_id = private.seed_tenant_id() and position({sql('Bracket audit: ' + warning)} in notes) = 0;",
        ]
    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", action="store_true", help="extract committed manifest from reviewed source pages")
    parser.add_argument("--write", action="store_true", help="regenerate SQL from committed manifest")
    parser.add_argument("--check", action="store_true", help="validate manifest and generated SQL equality")
    args = parser.parse_args()
    if sum((args.source, args.write, args.check)) != 1:
        parser.error("use exactly one mode")
    if args.source:
        data = extract_manifest()
        validate_manifest(data)
        MANIFEST_PATH.parent.mkdir(parents=True, exist_ok=True)
        MANIFEST_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        SEED_PATH.write_text(build_sql(data), encoding="utf-8")
    else:
        data = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
        generated = build_sql(data)
        if args.write:
            SEED_PATH.write_text(generated, encoding="utf-8")
        elif not SEED_PATH.is_file() or SEED_PATH.read_text(encoding="utf-8") != generated:
            raise SystemExit("generated seed differs; run --write")
    print(f"ok {len(data['tournaments'])} tournaments, {sum(len(row.get('fixtures', [])) for row in data['tournaments'])} fixtures")


if __name__ == "__main__":
    main()
