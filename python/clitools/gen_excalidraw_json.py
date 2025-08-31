#!/usr/bin/env python3
"""
OOP converter: simplified JSON (clipboard/file) -> Excalidraw clipboard JSON (clipboard/file).

Input example:
{
  "elements": [
    {"id":"rect1","type":"Rectangle","text":"Texto 1"},
    {"id":"rect2","type":"Rectangle","text":"Texto 2"},
    {"type":"arrow","from":"rect1","to":"rect2"}
  ]
}

Usage:
  python slim_to_excaliclip_oop_v2.py
  python slim_to_excaliclip_oop_v2.py --in in.json --out out.json
"""

from __future__ import annotations
import argparse
import json
import os
import random
import subprocess
import sys
import time
import uuid
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Any, Dict, Iterable, List, Optional, Tuple, Type, Callable

# ============================= Clipboard helpers =============================

def _have_cmd(cmd: str) -> bool:
    from shutil import which
    return which(cmd) is not None

def read_clipboard_text() -> str:
    try:
        import pyperclip  # type: ignore
        return pyperclip.paste()
    except Exception:
        pass
    if sys.platform == "darwin" and _have_cmd("pbpaste"):
        return subprocess.check_output(["pbpaste"]).decode("utf-8")
    if os.name == "nt":
        try:
            return subprocess.check_output(
                ["powershell", "-NoProfile", "-Command", "Get-Clipboard"]
            ).decode("utf-8")
        except Exception:
            pass
    for cmd in (["xclip", "-selection", "clipboard", "-o"],
                ["xsel", "--clipboard", "--output"]):
        if _have_cmd(cmd[0]):
            return subprocess.check_output(cmd).decode("utf-8")
    raise RuntimeError("No clipboard read method available. Install 'pyperclip' or an OS clipboard tool.")

def write_clipboard_text(text: str) -> None:
    try:
        import pyperclip  # type: ignore
        pyperclip.copy(text)
        return
    except Exception:
        pass
    if sys.platform == "darwin" and _have_cmd("pbcopy"):
        p = subprocess.Popen(["pbcopy"], stdin=subprocess.PIPE)
        p.communicate(input=text.encode("utf-8"))
        return
    if os.name == "nt":
        try:
            subprocess.run(
                ["powershell", "-NoProfile", "-Command",
                 "Set-Clipboard -Value ([Console]::In.ReadToEnd())"],
                input=text.encode("utf-8"), check=True
            )
            return
        except Exception:
            pass
    for cmd in (["xclip", "-selection", "clipboard"],
                ["xsel", "--clipboard", "--input"]):
        if _have_cmd(cmd[0]):
            p = subprocess.Popen(cmd, stdin=subprocess.PIPE)
            p.communicate(input=text.encode("utf-8"))
            return
    raise RuntimeError("No clipboard write method available. Install 'pyperclip' or an OS clipboard tool.")

# ============================= Build context & utils =============================

def now_ms() -> int:
    return int(time.time() * 1000)

def uid() -> str:
    # Vary IDs a bit to resemble Excalidraw variability
    return uuid.uuid4().hex if random.random() < 0.5 else str(uuid.uuid4())

# ---- spacing knobs ----
LAYOUT_GAP_X = 320.0   # distance between consecutive nodes (was 220)
ARROW_GAP    = 24.0    # distance from element edge to arrow endpoints (was 10)

DEFAULTS: Dict[str, Any] = {
    "strokeColor": "#1e1e1e",
    "backgroundColor": "transparent",
    "fillStyle": "solid",       # solid | hachure | cross-hatch
    "strokeWidth": 2,
    "strokeStyle": "solid",     # solid | dashed | dotted
    "roughness": 1,
    "opacity": 100,
    "fontSize": 20,
    "fontFamily": 1,            # 1=Virgil, 2=Arial, 3=Cascadia
    "textAlign": "center",
    "verticalAlign": "middle",
}

def text_metrics(text: str, font_size: float) -> Tuple[float, float, float]:
    width = max(1.0, len(text) * font_size * 0.60)
    height = max(font_size, font_size * 1.25)
    baseline = font_size * 1.0
    return width, height, baseline

def base_element(eltype: str, x: float, y: float) -> Dict[str, Any]:
    return {
        "id": uid(),
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
        "updated": now_ms(),
        "link": None,
        "locked": False,
    }

def bbox(el: Dict[str, Any]) -> Tuple[float, float, float, float]:
    return float(el["x"]), float(el["y"]), float(el.get("width", 0.0)), float(el.get("height", 0.0))

def center_of(el: Dict[str, Any]) -> Tuple[float, float]:
    x, y, w, h = bbox(el)
    return x + w / 2.0, y + h / 2.0

def anchor_towards(el: Dict[str, Any], toward: Tuple[float, float], gap: float = 10.0) -> Tuple[float, float, float]:
    """
    Pick an anchor on the element's bounding box facing toward (tx, ty).
    Returns (ax, ay, gap).
    """
    x, y, w, h = bbox(el)
    cx, cy = x + w / 2.0, y + h / 2.0
    tx, ty = toward
    dx, dy = tx - cx, ty - cy
    if abs(dx) >= abs(dy):
        # left/right
        if dx >= 0:
            return x + w + gap, cy, gap  # right side
        else:
            return x - gap, cy, gap       # left side
    else:
        # top/bottom
        if dy >= 0:
            return cx, y + h + gap, gap  # bottom
        else:
            return cx, y - gap, gap      # top

@dataclass
class BuildContext:
    """Holds shared state during a build."""
    out_elements: List[Dict[str, Any]] = field(default_factory=list)

    # Index by real Excalidraw element id -> element dict
    id_index: Dict[str, Dict[str, Any]] = field(default_factory=dict)

    # Index by *slim* id -> connectable element dict (the primary element to bind to)
    connectable_index: Dict[str, Dict[str, Any]] = field(default_factory=dict)

    def add(self, el: Dict[str, Any]) -> None:
        self.out_elements.append(el)
        if "id" in el:
            self.id_index[el["id"]] = el

    def register_connectable(self, slim_id: Optional[str], el: Dict[str, Any]) -> None:
        if slim_id:
            self.connectable_index[slim_id] = el

    def resolve_target(self, ref: str) -> Optional[Dict[str, Any]]:
        """Accepts either a slim id or a real Excalidraw id."""
        return self.connectable_index.get(ref) or self.id_index.get(ref)

# ============================= Registry & base class =============================

ELEMENT_REGISTRY: Dict[str, Type["ExcalidrawObject"]] = {}

def register_element(*type_names: str) -> Callable[[Type["ExcalidrawObject"]], Type["ExcalidrawObject"]]:
    def _wrap(cls: Type["ExcalidrawObject"]) -> Type["ExcalidrawObject"]:
        for name in type_names:
            ELEMENT_REGISTRY[name.lower()] = cls
        return cls
    return _wrap

class ExcalidrawObject(ABC):
    """Base class for all simplified elements."""
    def __init__(self, raw: Dict[str, Any]):
        self.raw = raw
        # Slim id (user-level, e.g., "rect1"). Optional for elements without IDs.
        self.slim_id: Optional[str] = raw.get("id")

    @classmethod
    def from_slim(cls, raw: Dict[str, Any]) -> "ExcalidrawObject":
        return cls(raw)

    @classmethod
    @abstractmethod
    def can_build_from(cls, raw: Dict[str, Any]) -> bool:
        ...

    @abstractmethod
    def build(self, ctx: BuildContext) -> None:
        """Append produced Excalidraw elements to ctx and register connectables if applicable."""
        ...

def make_object(raw: Dict[str, Any]) -> ExcalidrawObject:
    t = str(raw.get("type", "")).lower().strip()
    cls = ELEMENT_REGISTRY.get(t)
    if not cls:
        raise ValueError(f"Unsupported element type: {raw.get('type')!r}")
    return cls.from_slim(raw)

# ============================= Layout =============================

from dataclasses import dataclass
from typing import Iterable, Tuple, List

@dataclass
class LayoutEngine:
    origin: Tuple[float, float] = (0.0, 0.0)
    gap_x: float = LAYOUT_GAP_X      # <-- uses the constant
    rect_w: float = 185.0
    rect_h: float = 134.0

    def assign_positions(self, rects: Iterable["Rectangle"]) -> None:
        """Left-to-right layout. Honors explicit x/y/width/height if provided."""
        x0, y0 = self.origin
        i = 0
        for r in rects:
            if r.x is None:
                r.x = x0 + i * self.gap_x
            if r.y is None:
                r.y = y0
            if r.width is None:
                r.width = self.rect_w
            if r.height is None:
                r.height = self.rect_h
            i += 1


# ============================= Elements =============================

def _try_float(v: Any) -> Optional[float]:
    try:
        if v is None:
            return None
        return float(v)
    except Exception:
        return None

@register_element("rectangle", "rect")
class Rectangle(ExcalidrawObject):
    def __init__(self, raw: Dict[str, Any]):
        super().__init__(raw)
        self.label: str = str(raw.get("text") or (self.slim_id or ""))
        # Optional coordinates/dimensions
        self.x: Optional[float] = _try_float(raw.get("x"))
        self.y: Optional[float] = _try_float(raw.get("y"))
        self.width: Optional[float] = _try_float(raw.get("width"))
        self.height: Optional[float] = _try_float(raw.get("height"))

    @classmethod
    def can_build_from(cls, raw: Dict[str, Any]) -> bool:
        return str(raw.get("type", "")).lower() in {"rectangle", "rect"}

    def build(self, ctx: BuildContext) -> None:
        assert self.x is not None and self.y is not None
        assert self.width is not None and self.height is not None

        rect = base_element("rectangle", self.x, self.y)
        # Preserve slim id as Excalidraw element id when present (nice for debugging & linking)
        if self.slim_id:
            rect["id"] = self.slim_id
        rect["width"] = self.width
        rect["height"] = self.height
        rect["roundness"] = {"type": 3}
        rect["boundElements"] = []

        # Bound text
        text_el = base_element("text", 0, 0)
        font_size = DEFAULTS["fontSize"]
        w, h, baseline = text_metrics(self.label, font_size)
        text_el.update({
            "text": self.label,
            "rawText": self.label,
            "fontSize": font_size,
            "fontFamily": DEFAULTS["fontFamily"],
            "textAlign": DEFAULTS["textAlign"],
            "verticalAlign": DEFAULTS["verticalAlign"],
            "containerId": rect["id"],
            "originalText": self.label,
            "autoResize": True,
            "lineHeight": 1.25,
            "width": w,
            "height": h,
            "baseline": baseline,
        })
        # center inside rectangle
        text_el["x"] = rect["x"] + (rect["width"] - w) / 2.0
        text_el["y"] = rect["y"] + (rect["height"] - h) / 2.0

        rect["boundElements"].append({"type": "text", "id": text_el["id"]})

        # Register outputs
        ctx.add(rect)
        ctx.add(text_el)
        # Make this rectangle the connectable target for this slim id
        ctx.register_connectable(self.slim_id, rect)

@register_element("arrow")
class Arrow(ExcalidrawObject):
    def __init__(self, raw: Dict[str, Any]):
        super().__init__(raw)
        self.from_ref: Optional[str] = raw.get("from")
        self.to_ref: Optional[str] = raw.get("to")

    @classmethod
    def can_build_from(cls, raw: Dict[str, Any]) -> bool:
        return str(raw.get("type", "")).lower() == "arrow"

    def build(self, ctx: BuildContext) -> None:
        src = ctx.resolve_target(self.from_ref) if self.from_ref else None
        dst = ctx.resolve_target(self.to_ref) if self.to_ref else None

        if not src or not dst:
            arr = base_element("arrow", 0.0, 0.0)
            arr.update({
                "points": [[0, 0], [100, 0]],
                "width": 100.0,
                "height": 0.0,
                "lastCommittedPoint": None,
                "startBinding": None,
                "endBinding": None,
                "startArrowhead": None,
                "endArrowhead": "arrow",
                "roundness": {"type": 2},
                "elbowed": False,
            })
            ctx.add(arr)
            ctx.register_connectable(self.slim_id, arr)
            return

        # Choose anchors on the bounding boxes facing each other,
        # but keep ARROW_GAP pixels away from the element edges.
        sx, sy = center_of(src)
        dx, dy = center_of(dst)
        ax, ay, gap_s = anchor_towards(src, (dx, dy), gap=ARROW_GAP)
        bx, by, gap_d = anchor_towards(dst, (sx, sy), gap=ARROW_GAP)

        arr = base_element("arrow", ax, ay)
        arr.update({
            "points": [[0, 0], [bx - ax, by - ay]],
            "width": abs(bx - ax),
            "height": abs(by - ay),
            "lastCommittedPoint": None,
            "startBinding": {"elementId": src["id"], "focus": 0.0, "gap": gap_s},
            "endBinding": {"elementId": dst["id"], "focus": 0.0, "gap": gap_d},
            "startArrowhead": None,
            "endArrowhead": "arrow",
            "roundness": {"type": 2},
            "elbowed": False,
        })

        for target in (src, dst):
            if target.get("boundElements") is None:
                target["boundElements"] = []
            target["boundElements"].append({"id": arr["id"], "type": "arrow"})

        ctx.add(arr)
        ctx.register_connectable(self.slim_id, arr)

# ============================= Orchestrator =============================

def parse_objects(slim: Dict[str, Any]) -> List[ExcalidrawObject]:
    objs: List[ExcalidrawObject] = []
    for raw in slim.get("elements", []):
        t = str(raw.get("type", "")).lower().strip()
        cls = ELEMENT_REGISTRY.get(t)
        if not cls:
            raise ValueError(f"Unsupported element type: {raw.get('type')!r}")
        objs.append(cls.from_slim(raw))
    return objs

def convert_slim_to_clipboard(slim: Dict[str, Any]) -> Dict[str, Any]:
    objs = parse_objects(slim)
    ctx = BuildContext()

    # Layout pass for rectangles
    rects: List[Rectangle] = [o for o in objs if isinstance(o, Rectangle)]
    layout = LayoutEngine()
    layout.assign_positions(rects)

    # Build pass: build connectables first (rectangles), then others (arrows)
    for r in rects:
        r.build(ctx)
    for o in objs:
        if not isinstance(o, Rectangle):
            o.build(ctx)

    return {"type": "excalidraw/clipboard", "elements": ctx.out_elements, "files": {}}

# ============================= CLI =============================

def main() -> None:
    ap = argparse.ArgumentParser(description="Convert slim JSON → Excalidraw clipboard JSON (OOP, generic index).")
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
        except Exception:
            print("Clipboard doesn't contain valid JSON. Use --in to specify a file.", file=sys.stderr)
            raise

    # Convert
    clip = convert_slim_to_clipboard(slim)
    out_text = json.dumps(clip, ensure_ascii=False, indent=2)

    # Write
    if args.outfile:
        with open(args.outfile, "w", encoding="utf-8") as f:
            f.write(out_text)
        print(f"Wrote {args.outfile}")
    else:
        write_clipboard_text(out_text)
        print("Excalidraw JSON copied to clipboard.")

if __name__ == "__main__":
    main()
