import re
import sys
import xml.etree.ElementTree as et


def iter_nodes(xml_path: str):
    root = et.parse(xml_path).getroot()
    pattern = re.compile(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]")

    for node in root.iter("node"):
        bounds = node.attrib.get("bounds", "")
        match = pattern.fullmatch(bounds)
        if not match:
            continue
        x1, y1, x2, y2 = map(int, match.groups())
        yield {
            "class": node.attrib.get("class", ""),
            "text": node.attrib.get("text", ""),
            "desc": node.attrib.get("content-desc", ""),
            "enabled": node.attrib.get("enabled", ""),
            "clickable": node.attrib.get("clickable", ""),
            "x": (x1 + x2) // 2,
            "y": (y1 + y2) // 2,
            "x1": x1,
            "y1": y1,
            "x2": x2,
            "y2": y2,
        }


def main() -> int:
    xml_path = sys.argv[1]
    mode = sys.argv[2]
    needle = sys.argv[3] if len(sys.argv) > 3 else ""
    nodes = list(iter_nodes(xml_path))

    if mode == "desc":
        for node in nodes:
            if needle in node["desc"]:
                print(node["x"], node["y"])
                return 0
    elif mode == "class":
        for node in nodes:
            if node["class"] == needle:
                print(node["x"], node["y"])
                return 0
    elif mode == "exists_desc":
        print("1" if any(needle in node["desc"] for node in nodes) else "0")
        return 0
    elif mode == "bottom_action":
        candidates = [
            node
            for node in nodes
            if node["class"] == "android.widget.Button"
            and node["y1"] > 2000
            and node["x1"] > 800
        ]
        candidates.sort(key=lambda node: (node["y1"], node["x1"]))
        if candidates:
            node = candidates[0]
            print(node["x"], node["y"], node["enabled"])
            return 0
    elif mode == "dump_action_state":
        candidates = [
            node
            for node in nodes
            if node["class"] == "android.widget.Button"
            and node["y1"] > 2000
            and node["x1"] > 800
        ]
        candidates.sort(key=lambda node: (node["y1"], node["x1"]))
        if candidates:
            node = candidates[0]
            print(
                f"{node['x']} {node['y']} enabled={node['enabled']} clickable={node['clickable']}"
            )
            return 0

    print("NOT_FOUND", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
