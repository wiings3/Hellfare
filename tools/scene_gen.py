"""Tiny helper for authoring Godot .tscn files from Python.

The output is an ordinary editor scene: open it in Godot and edit it like any other.
Usage:
    s = Scene("CompanyLeft", "Control", {"offset_right": 285.0})
    s.node("Margin", "MarginContainer", {...})
    s.inst("Margin/Header", "res://scenes/journal/widgets/section_header.tscn", {"text": "Title"})
    s.save("scenes/journal/pages/x.tscn")
Values: str -> quoted string; Res("res://path") -> ExtResource; Raw("...") -> written verbatim.
"""


class Raw:
    def __init__(self, text):
        self.text = text


class Res:
    def __init__(self, path, kind=None):
        self.path = path
        self.kind = kind


def _kind(path):
    if path.endswith(".tscn"):
        return "PackedScene"
    if path.endswith(".gd"):
        return "Script"
    if path.endswith((".ttf", ".otf")):
        return "FontFile"
    return "Texture2D"


class Scene:
    def __init__(self, name, type_, props=None):
        self.ext = {}
        self.subs = []
        self.nodes = []
        self.nodes.append((name, type_, None, props or {}, None))

    def _ext_id(self, res):
        if res.path not in self.ext:
            self.ext[res.path] = (res.kind or _kind(res.path), "%d_%s" % (len(self.ext) + 1, res.path.split("/")[-1].split(".")[0][:16]))
        return self.ext[res.path][1]

    def sub(self, id_, type_, props):
        self.subs.append((id_, type_, props))
        return Raw('SubResource("%s")' % id_)

    def node(self, path, type_, props=None):
        parent, _, name = path.rpartition("/")
        self.nodes.append((name, type_, parent or ".", props or {}, None))

    def inst(self, path, scene, props=None):
        parent, _, name = path.rpartition("/")
        self.nodes.append((name, None, parent or ".", props or {}, Res(scene)))

    def _val(self, v):
        if isinstance(v, Raw):
            return v.text
        if isinstance(v, Res):
            return 'ExtResource("%s")' % self._ext_id(v)
        if isinstance(v, bool):
            return "true" if v else "false"
        if isinstance(v, str):
            return '"%s"' % v.replace("\\", "\\\\").replace('"', '\\"')
        if isinstance(v, float):
            return repr(v)
        if isinstance(v, tuple):
            return "Vector2(%s, %s)" % (v[0], v[1])
        return str(v)

    def save(self, path):
        body = []
        for (name, type_, parent, props, inst) in self.nodes:
            head = '[node name="%s"' % name
            if type_:
                head += ' type="%s"' % type_
            if parent is not None:
                head += ' parent="%s"' % parent
            if inst:
                head += ' instance=ExtResource("%s")' % self._ext_id(inst)
            head += "]"
            lines = [head]
            if parent is not None and "layout_mode" not in props:
                lines.append("layout_mode = 2")
            for k, v in props.items():
                lines.append("%s = %s" % (k, self._val(v)))
            body.append("\n".join(lines))
        subs = []
        for (id_, type_, props) in self.subs:
            lines = ['[sub_resource type="%s" id="%s"]' % (type_, id_)]
            for k, v in props.items():
                lines.append("%s = %s" % (k, self._val(v)))
            subs.append("\n".join(lines))
        exts = ['[ext_resource type="%s" path="%s" id="%s"]' % (kind, p, i) for p, (kind, i) in self.ext.items()]
        out = '[gd_scene load_steps=%d format=3]\n\n' % (len(exts) + len(subs) + 1)
        if exts:
            out += "\n".join(exts) + "\n\n"
        if subs:
            out += "\n\n".join(subs) + "\n\n"
        out += "\n\n".join(body) + "\n"
        with open(path, "w") as f:
            f.write(out)


# Shared building blocks -------------------------------------------------------
HEADER = "res://scenes/journal/widgets/section_header.tscn"
TILE = "res://scenes/journal/widgets/stat_tile.tscn"
SLOT = "res://scenes/journal/widgets/item_slot.tscn"
INFO = "res://scenes/journal/widgets/info_box.tscn"
PIPS = "res://scenes/journal/widgets/pip_row.tscn"


def page(name, top=12):
    """Standard page root: 285x371 Control with a margin and a content VBox."""
    s = Scene(name, "Control", {"layout_mode": 3, "anchors_preset": 0, "offset_right": 285.0, "offset_bottom": 371.0})
    s.node("Margin", "MarginContainer", {
        "layout_mode": 1, "anchors_preset": 15, "anchor_right": 1.0, "anchor_bottom": 1.0,
        "grow_horizontal": 2, "grow_vertical": 2,
        "theme_override_constants/margin_left": 14, "theme_override_constants/margin_top": top,
        "theme_override_constants/margin_right": 14, "theme_override_constants/margin_bottom": 12})
    s.node("Margin/Content", "VBoxContainer", {"theme_override_constants/separation": 6})
    return s


def label(s, path, text, variation=None, extra=None):
    props = {}
    if variation:
        props["theme_type_variation"] = Raw('&"%s"' % variation)
    props["text"] = text
    props.update(extra or {})
    s.node(path, "Label", props)


def button(s, path, text, variation=None, extra=None):
    props = {"mouse_default_cursor_shape": 2}
    if variation:
        props["theme_type_variation"] = Raw('&"%s"' % variation)
    props["text"] = text
    props.update(extra or {})
    s.node(path, "Button", props)


def spacer(s, path):
    s.node(path, "Control", {"size_flags_vertical": 3, "mouse_filter": 2})


def scroll(s, path, min_h=40, expand=True):
    props = {"custom_minimum_size": (0, min_h), "horizontal_scroll_mode": 0}
    if expand:
        props["size_flags_vertical"] = 3
    s.node(path, "ScrollContainer", props)
    s.node(path + "/Items", "VBoxContainer", {"size_flags_horizontal": 3, "theme_override_constants/separation": 3})
