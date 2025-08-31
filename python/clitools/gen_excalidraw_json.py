#!/usr/bin/env python3
"""
Convert a simplified Excalidraw-ish JSON from the clipboard (or a file)
into a full Excalidraw clipboard JSON and copy it back to the clipboard.

Input (example):
{
  "elements": [
    {"id":"rect1","type":"Rectangle","text":"Texto 1"},
    {"id":"rect2","type":"Rectangle","text":"Texto 2"},
    {"type":"arrow","from":"rect1","to":"rect2"}
  ]
}

Output shape (clipboard):
{ "type": "excalidraw/clipboard", "elements":[...], "files":{} }

Usage:
  python slim_to_excaliclip.py
  python slim_to_excaliclip.py --in in.json --out out.json
"""

from __future__ import annotations
import argparse
import json
import math
import os
import random
import subprocess
import sys
import time
import uuid
from typing import Any, Dict, List, Optional, Tuple

# ------------- Clipboard helpers (pyperclip if available, else OS tools) -------------
def _have_cmd(cmd: str) -> bool:
    from shutil import which
    return which(cmd) is not None

def read_clipboard_text() -> str:
    # Try pyperclip
    try:
        import pyperclip  # type: ignore
        return pyperclip.paste()
    except Exception:
        pass

    # macOS
    if sys.platform == "darwin" and _have_cmd("pbpaste"):
        return subprocess.check_output(["pbpaste"]).decode("utf-8")

    # Windows (PowerShell)
    if os.name == "nt":
        try:
            return subprocess.check_output(
                ["powershell", "-NoProfile", "-Command", "Get-Clipboard"]
            ).decode("utf-8")
        except Exception:
            pass
        # Fallback: clip.exe cannot read

    # Linux / X11
    for cmd in (["xclip", "-selection", "clipboard", "-o"],
                ["xsel", "--clipboard", "--output"]):
        if _have_cmd(cmd[0]):
            return subprocess.check_output(cmd).decode("utf-8")

    raise RuntimeError("No clipboard read method available. Install 'pyperclip' or an OS clipboard tool.")

def write_clipboard_text(text: str) -> None:
    # Try pyperclip
    try:
        import pyperclip  # type: ignore
        pyperclip.copy(text)
        return
    except Exception:
        pass

    # macOS
    if sys.platform == "darwin" and _have_cmd("pbcopy"):
        p = subprocess.Popen(["pbcopy"], stdin=subprocess.PIPE)
        p.communicate(input=text.encode("utf-8"))
        return

    # Windows (PowerShell)
    if os.name == "nt":
        try:
            subprocess.run(
                ["powershell", "-NoProfile", "-Command", "Set-Clipboard -Value ([Console]::In.ReadToEnd())"],
                input=text.encode("utf-8"),
                check=True
            )
            return
        except Exception:
            pass

    # Linux / X11
    for cmd in (["xclip", "-selection", "clipboard"],
                ["xsel", "--clipboard", "--input"]):
        if _have_cmd(cmd[0]):
            p = subprocess.Popen(cmd, stdin=subprocess.PIPE)
            p.communicate(input=text.encode("utf-8"))
            return

    raise RuntimeError("No clipboard write method available. Install 'pyperclip' or an OS clipboard tool.")

# ------------- Excalidraw element helpers -------------
NOW_MS = lambda: int(time.time() * 1000)

DEFAULTS = {
    "strokeColor": "#1e1e1e",
    "backgroundColor": "transparent",
    "fillStyle": "solid",       # solid | hachure | cross-hatch
    "strokeWidth": 2,
    "strokeStyle": "solid",     # solid | dashed | dotted
    "roughness": 1,
    "opacity": 100,
    "fontSize": 20,
    "fontFamily": 1,            # 1=Virgil, 2=Arial, 3=Cascadia; 5 also works in some builds
    "textAlign": "center",
    "verticalAlign": "middle",
}

RECT_W = 185.0
RECT_H = 134.0
GRID_GAP_X = 220.0
GRID_ORIGIN = (0.0, 0.0)

def _uid() -> str:
    return uuid.uuid4().hex if random.random() < 0.5 else str(uuid.uuid4())

def _base(eltype: str, x: float, y: float) -> Dict[str, Any]:
    return {
        "id": _uid(),
        "type": eltype,
        "x": float(x),
        "y": float(y),
        "width": 0.0,
        "height": 0.0,
        "angle": 0,
        "strokeColor": DEFAULTS["strokeColor"],
        "backgroundColor": DEFAULTS["backgroundColor"],
        "fillStyle": DEFAULTS["fillStyle"],
        "strokeWidth": DEFAULTS["strokeWidth"],
        "strokeStyle": DEFAULTS["strokeStyle"],
        "roughness": DEFAULTS["roughness"],
        "opacity": DEFAULTS["opacity"],
        "groupIds": [],
        "frameId": None,
        "roundness": None,
        "seed": random.randint(1, 2**31 - 1),
        "version": 1,
        "versionNonce": random.randint(1, 2**31 - 1),
        "isDeleted": False,
        "boundElements": None,
        "updated": NOW_MS(),
        "link": None,
        "locked": False,
    }

def _text_metrics(text: str, font_size: float) -> Tuple[float, float, float]:
    width = max(1.0, len(text) * font_size * 0.60)
    height = max(font_size, font_size * 1.25)
    baseline = font_size * 1.0
    return width, height, baseline

# ------------- High level conversion -------------
class SlimElement:
    def __init__(self, raw: Dict[str, Any]):
        self.raw = raw
        self.type = str(raw.get("type", "")).lower()
        self.id = raw.get("id")

def layout_rects(slim_rects: List[SlimElement]) -> Dict[str, Tuple[float, float]]:
    """
    Simple horizontal layout: rects placed left-to-right.
    Returns mapping rect_id -> (x, y).
    """
    positions: Dict[str, Tuple[float, float]] = {}
    x0, y0 = GRID_ORIGIN
    for i, s in enumerate(slim_rects):
        x = x0 + i * GRID_GAP_X
        y = y0
        if s.id:
            positions[s.id] = (x, y)
    return positions

def build_rectangle_and_text(rect_id: Optional[str], label: str, x: float, y: float) -> Tuple[Dict[str, Any], Dict[str, Any]]:
    # Rectangle
    rect = _base("rectangle", x, y)
    if rect_id:
        rect["id"] = rect_id  # respect provided id if present
    rect["width"] = RECT_W
    rect["height"] = RECT_H
    rect["roundness"] = {"type": 3}

    # Text bound to rect as container
    text_el = _base("text", 0, 0)
    tx_w, tx_h, baseline = _text_metrics(label, DEFAULTS["fontSize"])
    text_el.update({
        "text": label,
        "rawText": label,
        "fontSize": DEFAULTS["fontSize"],
        "fontFamily": DEFAULTS["fontFamily"],
        "textAlign": DEFAULTS["textAlign"],
        "verticalAlign": DEFAULTS["verticalAlign"],
        "containerId": rect["id"],
        "originalText": label,
        "autoResize": True,
        "lineHeight": 1.25,
        "width": tx_w,
        "height": tx_h,
        "baseline": baseline,
    })
    # center text within rectangle
    text_el["x"] = rect["x"] + (rect["width"] - tx_w) / 2.0
    text_el["y"] = rect["y"] + (rect["height"] - tx_h) / 2.0
    text_el["roundness"] = None

    # bound elements linkage
    rect["boundElements"] = [{"type": "text", "id": text_el["id"]}]

    return rect, text_el

def build_arrow(from_rect: Dict[str, Any], to_rect: Dict[str, Any]) -> Dict[str, Any]:
    # Start at middle of right edge of from_rect, end at middle of left edge of to_rect
    start_x = from_rect["x"] + from_rect["width"] + 10.0
    start_y = from_rect["y"] + from_rect["height"] / 2.0
    end_x   = to_rect["x"] - 10.0
    end_y   = to_rect["y"] + to_rect["height"] / 2.0

    dx = end_x - start_x
    dy = end_y - start_y

    arr = _base("arrow", start_x, start_y)
    arr.update({
        "points": [[0, 0], [dx, dy]],
        "width": abs(dx),
        "height": abs(dy),
        "lastCommittedPoint": None,
        "startBinding": {
            "elementId": from_rect["id"],
            "focus": 0.0,
            "gap": 10.0,
        },
        "endBinding": {
            "elementId": to_rect["id"],
            "focus": 0.0,
            "gap": 10.0,
        },
        "startArrowhead": None,
        "endArrowhead": "arrow",
        "roundness": {"type": 2},
        "elbowed": False,
    })

    # Append arrow refs to rectangles' boundElements
    for rect in (from_rect, to_rect):
        if rect.get("boundElements") is None:
            rect["boundElements"] = []
        rect["boundElements"].append({"id": arr["id"], "type": "arrow"})

    return arr

def convert_slim_to_clipboard(slim: Dict[str, Any]) -> Dict[str, Any]:
    raw_elems = slim.get("elements", [])
    slims = [SlimElement(e) for e in raw_elems]

    # Collect rectangles (case-insensitive "rectangle")
    rect_slim = [s for s in slims if s.type in ("rectangle", "rect")]
    # Layout rectangles
    positions = layout_rects(rect_slim)

    # Build full elements
    id_to_rect: Dict[str, Dict[str, Any]] = {}
    elements_out: List[Dict[str, Any]] = []

    # 1) rectangles + bound text
    for s in rect_slim:
        label = str(s.raw.get("text", s.id or ""))
        x, y = positions.get(s.id, GRID_ORIGIN)
        rect, text_el = build_rectangle_and_text(s.id, label, x, y)
        id_to_rect[rect["id"]] = rect
        elements_out.append(rect)
        elements_out.append(text_el)

    # 2) arrows
    for s in slims:
        if s.type == "arrow":
            src_id = s.raw.get("from")
            dst_id = s.raw.get("to")
            if not src_id or not dst_id:
                continue
            if src_id not in id_to_rect or dst_id not in id_to_rect:
                continue
            arr = build_arrow(id_to_rect[src_id], id_to_rect[dst_id])
            elements_out.append(arr)

    # Package clipboard payload
    return {
        "type": "excalidraw/clipboard",
        "elements": elements_out,
        "files": {},
    }

# ------------- CLI -------------
def main():
    ap = argparse.ArgumentParser(description="Convert slim JSON → Excalidraw clipboard JSON.")
    ap.add_argument("--in", dest="infile", help="Read slim JSON from file instead of clipboard.")
    ap.add_argument("--out", dest="outfile", help="Write Excalidraw clipboard JSON to file instead of clipboard.")
    args = ap.parse_args()

    # Read
    if args.infile:
        with open(args.infile, "r", encoding="utf-8") as f:
            slim = json.load(f)
    else:
        text = read_clipboard_text()
        try:
            slim = json.loads(text)
        except Exception as e:
            print("Clipboard doesn't contain valid JSON. Use --in to specify a file.", file=sys.stderr)
            raise

    # Convert
    clip = convert_slim_to_clipboard(slim)

    # Write
    out_text = json.dumps(clip, ensure_ascii=False, indent=2)
    if args.outfile:
        with open(args.outfile, "w", encoding="utf-8") as f:
            f.write(out_text)
        print(f"Wrote {args.outfile}")
    else:
        write_clipboard_text(out_text)
        print("Excalidraw JSON copied to clipboard.")

if __name__ == "__main__":
    main()
