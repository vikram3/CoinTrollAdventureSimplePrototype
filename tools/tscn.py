"""Minimal writer for Godot 4 text scene (.tscn) files."""
import os

class Res(str):
    """Resource path resolved to an ExtResource when the node is written."""


class R(str):
    """Raw Godot literal (written as-is)."""

def V(x, y):
    return R(f"Vector2({fmtnum(x)}, {fmtnum(y)})")

def C(r, g, b, a=1.0):
    return R(f"Color({fmtnum(r)}, {fmtnum(g)}, {fmtnum(b)}, {fmtnum(a)})")

def RECT(x, y, w, h):
    return R(f"Rect2({fmtnum(x)}, {fmtnum(y)}, {fmtnum(w)}, {fmtnum(h)})")

def NP(p):
    return R(f'NodePath("{p}")')

def PSA(items):
    return R("PackedStringArray(" + ", ".join(q(s) for s in items) + ")")

def PIA(items):
    return R("PackedInt32Array(" + ", ".join(str(int(i)) for i in items) + ")")

def PV2(points):
    flat = []
    for (x, y) in points:
        flat += [fmtnum(x), fmtnum(y)]
    return R("PackedVector2Array(" + ", ".join(flat) + ")")

def fmtnum(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, int):
        return str(v)
    f = float(v)
    if f == int(f) and abs(f) < 1e15:
        return f"{int(f)}"
    return repr(round(f, 4))

def q(s):
    s = s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
    return f'"{s}"'

def val(v):
    if v is None:
        return "null"
    if isinstance(v, R):
        return str(v)
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, int):
        return str(v)
    if isinstance(v, float):
        s = repr(float(v))
        return s
    if isinstance(v, str):
        return q(v)
    raise TypeError(f"bad value {v!r}")


class Scene:
    def __init__(self, root_name, root_type, script=None, props=None, groups=None):
        self.ext = []      # (type, path, id)
        self.subs = []     # (type, id, [(k, v)])
        self.nodes = []    # header, props
        self._sub_n = 0
        rp = dict(props or {})
        if script:
            rp = {"script": self.res(script, "Script"), **rp}
        self._add_node(root_name, root_type, None, rp, None, groups)

    def res(self, path, typ=None):
        if typ is None:
            if path.endswith(".gd"):
                typ = "Script"
            elif path.endswith(".tscn"):
                typ = "PackedScene"
            elif path.endswith(".tres"):
                typ = "Theme"
            else:
                typ = "Texture2D"
        for (t, p, i) in self.ext:
            if p == path:
                return R(f'ExtResource("{i}")')
        i = f"{len(self.ext) + 1}_r"
        self.ext.append((typ, path, i))
        return R(f'ExtResource("{i}")')

    def sub(self, typ, props):
        self._sub_n += 1
        i = f"{typ}_{self._sub_n}"
        self.subs.append((typ, i, list(props.items()) if isinstance(props, dict) else props))
        return R(f'SubResource("{i}")')

    def _add_node(self, name, typ, parent, props, instance, groups):
        props = {k: (self.res(str(v)) if isinstance(v, Res) else v) for k, v in (props or {}).items()}
        hdr = f'[node name="{name}"'
        if typ:
            hdr += f' type="{typ}"'
        if parent is not None:
            hdr += f' parent="{parent}"'
        if instance is not None:
            hdr += f" instance={instance}"
        if groups:
            hdr += " groups=[" + ", ".join(q(g) for g in groups) + "]"
        hdr += "]"
        self.nodes.append((hdr, props or {}))

    def node(self, name, typ=None, parent=".", props=None, script=None, instance=None, groups=None):
        p = dict(props or {})
        if script:
            p = {"script": self.res(script, "Script"), **p}
        inst = self.res(instance, "PackedScene") if instance else None
        self._add_node(name, None if instance else typ, parent, p, inst, groups)
        return name if parent == "." else f"{parent}/{name}"

    def write(self, path):
        out = [f"[gd_scene load_steps={len(self.ext) + len(self.subs) + 1} format=3]", ""]
        for (t, p, i) in self.ext:
            out.append(f'[ext_resource type="{t}" path="{p}" id="{i}"]')
        if self.ext:
            out.append("")
        for (t, i, props) in self.subs:
            out.append(f'[sub_resource type="{t}" id="{i}"]')
            for k, v in props:
                out.append(f"{k} = {val(v)}")
            out.append("")
        for hdr, props in self.nodes:
            out.append(hdr)
            for k, v in props.items():
                out.append(f"{k} = {val(v)}")
            out.append("")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            f.write("\n".join(out))


def sprite_frames(scene, anims, speed=5.0):
    """anims: list of (name, [texture paths], loop)."""
    parts = []
    for name, textures, loop in anims:
        frames = ",\n".join(
            '{\n"duration": 1.0,\n"texture": ' + str(scene.res(t)) + "\n}" for t in textures)
        parts.append('{\n"frames": [' + frames + '],\n"loop": ' + ("true" if loop else "false")
                     + ',\n"name": &"' + name + '",\n"speed": ' + repr(float(speed)) + "\n}")
    return scene.sub("SpriteFrames", {"animations": R("[" + ", ".join(parts) + "]")})
