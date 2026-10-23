"""One-off migration of the pre-redesign journal scenes from the 1600x900 stage
to the 960x540 stage with bundled pixel fonts. Layout numbers are scaled by K,
SystemFont overrides are replaced with Jersey 10 / Jersey 15 at crisp sizes,
and linear texture filtering on labels is dropped."""
import re, sys, os

K = 0.52
SCALE_KEYS = ("offset_left", "offset_top", "offset_right", "offset_bottom",
              "content_margin_left", "content_margin_top", "content_margin_right", "content_margin_bottom",
              "theme_override_constants/separation")
BORDER_KEYS = ("border_width_left", "border_width_top", "border_width_right", "border_width_bottom")
BODY_EXT = '[ext_resource type="FontFile" path="res://assets/fonts/Jersey10-Regular.ttf" id="font_body"]'
TITLE_EXT = '[ext_resource type="FontFile" path="res://assets/fonts/Jersey15-Regular.ttf" id="font_title"]'


def scale(v):
    return str(int(round(float(v) * K)))


def convert(path):
    text = open(path).read()
    if "font_body" in text or "K_CONVERTED" in text:
        return False
    # Find SystemFont sub-resources and which are headings.
    fonts = {}
    for m in re.finditer(r'\[sub_resource type="SystemFont" id="([^"]+)"\]\nfont_names = PackedStringArray\(([^)]*)\)\n(?:[a-z_]+ = [^\n]*\n)*', text):
        fonts[m.group(1)] = m.group(2).startswith('"Goudy')
    text = re.sub(r'\[sub_resource type="SystemFont" id="[^"]+"\]\nfont_names = PackedStringArray\([^)]*\)\n(?:[a-z_]+ = [^\n]*\n)*\n?', '', text)
    blocks = re.split(r'(?=^\[node )', text, flags=re.M)
    out = []
    for block in blocks:
        lines = block.split("\n")
        font_ref = None
        size = None
        for i, line in enumerate(lines):
            m = re.match(r'theme_override_fonts/font = SubResource\("([^"]+)"\)', line)
            if m and m.group(1) in fonts:
                font_ref = (i, m.group(1))
            m = re.match(r'theme_override_font_sizes/font_size = (\d+)', line)
            if m:
                size = (i, int(m.group(1)))
        new_lines = []
        for i, line in enumerate(lines):
            key = line.split(" = ")[0] if " = " in line else None
            if font_ref and i == font_ref[0]:
                heading = fonts[font_ref[1]]
                s = (size[1] if size else 16) * K
                if heading and s >= 10.5:
                    new_lines.append('theme_override_fonts/font = ExtResource("font_title")')
                else:
                    new_lines.append('theme_override_fonts/font = ExtResource("font_body")')
                continue
            if size and i == size[0]:
                s = size[1] * K
                heading = font_ref and fonts[font_ref[1]]
                if heading and s >= 10.5:
                    new_lines.append("theme_override_font_sizes/font_size = 12")
                else:
                    new_lines.append("theme_override_font_sizes/font_size = %d" % (20 if s >= 14 else 10))
                continue
            if key in SCALE_KEYS:
                new_lines.append("%s = %s" % (key, scale(line.split(" = ")[1])))
                continue
            if key in BORDER_KEYS:
                new_lines.append("%s = %d" % (key, max(1, int(round(float(line.split(" = ")[1]) * K)))))
                continue
            if key == "custom_minimum_size":
                nums = re.findall(r"-?[\d.]+", line.split(" = ")[1])
                new_lines.append("custom_minimum_size = Vector2(%s, %s)" % (scale(nums[0]), scale(nums[1])))
                continue
            if line.strip() == "texture_filter = 2":
                continue
            new_lines.append(line)
        out.append("\n".join(new_lines))
    text = "".join(out)
    # Register font resources after the header line.
    header_end = text.index("\n") + 1
    exts = "\n" + BODY_EXT + "\n" + TITLE_EXT + "\n"
    text = text[:header_end] + exts + text[header_end:]
    open(path, "w").write(text)
    return True


if __name__ == "__main__":
    for p in sys.argv[1:]:
        print(("converted " if convert(p) else "skipped ") + p)
